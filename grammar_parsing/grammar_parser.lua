local LexerRuleNode = require( "grammar_parsing.ast.lexer_rule_node" )
local ParserRuleNode = require( "grammar_parsing.ast.parser_rule_node" )
local SymbolNode = require( "grammar_parsing.ast.symbol_node" )
local SequenceNode = require( "grammar_parsing.ast.sequence_node" )
local AlternationNode = require( "grammar_parsing.ast.alternation_node" )
local OptionalNode = require( "grammar_parsing.ast.optional_node" )
local ZeroOrMoreNode = require( "grammar_parsing.ast.zero_or_more_node" )
local OneOrMoreNode = require( "grammar_parsing.ast.one_or_more_node" )
local GrammarNode = require( "grammar_parsing.ast.grammar_node" )
local Types = require( "grammar_parsing.grammar_types" )
local TokenType = Types.TokenType
local NodeType = Types.NodeType

---@class GrammarParser
---@field lexer GrammarLexer
---@field next Node?
local GrammarParser = {}
GrammarParser.__index = GrammarParser
GrammarParser.__type = "GrammarParser"

--- Creates a new instance of a grammar parser
---@param lexer GrammarLexer
---@return GrammarParser
function GrammarParser.new( lexer )
    local grammarParser = setmetatable( {}, GrammarParser )
    grammarParser.lexer = lexer
    grammarParser.lookup = nil

    return grammarParser
end

--- Returns the next node to be read
---@return Node
function GrammarParser:lookup()
    if not self.next then
        self.next = self.lexer:getNextToken()
    end

    return self.next
end

--- Returns and discards the lookup node
---@return Node
function GrammarParser:discard()
    local lookup = self:lookup()
    self.next = nil

    return lookup
end

--- Sets the lookup to a specific node
---@param node Node
function GrammarParser:setLookup( node )
    self.next = node
end

--- Checks if the next node is of the specified type or throws an error  
--- Returns and discards the lookup node
---@param type TokenType | NodeType
function GrammarParser:expect( type )
    local lookup  = self:lookup()
    if lookup.type ~= type then
        error( "Unexpected node at line " .. lookup.line .. " column " .. lookup.column .. ": expected " .. Types.typeToString( type ) .. ", got " .. Types.typeToString( lookup.type ) )
    end

    return self:discard()
end

function GrammarParser:parseGrammar()
    local tokenDeclarations = {}
    while self:lookup().type == TokenType.TERMINAL do
        local tokenDeclaration = self:parseTokenDeclaration()
        table.insert( tokenDeclarations, tokenDeclaration )
    end

    local ruleDeclarations = {}
    while self:lookup().type == TokenType.NON_TERMINAL do
        local ruleDeclaration = self:parseRuleDeclaration()
        table.insert( ruleDeclarations, ruleDeclaration )
    end

    self:expect( TokenType.EOF )

    return GrammarNode.new( tokenDeclarations, ruleDeclarations )
end

---@return LexerRuleNode
function GrammarParser:parseTokenDeclaration()
    local tokenName = self:discard() --[[@as Token]]
    self:expect( TokenType.COLON )
    local tokenContent = self:expect( TokenType.STRING ) --[[@as Token]]

    local isSkipped = self:lookup().type == TokenType.ARROW
    if isSkipped then
        self:discard()
        self:expect( TokenType.SKIP )
    end

    self:expect( TokenType.SEMICOLON )

    return LexerRuleNode.new( tokenName, tokenContent, isSkipped )
end

---@return ParserRuleNode
function GrammarParser:parseRuleDeclaration()
    local ruleName = self:discard() --[[@as Token]]
    self:expect( TokenType.COLON )

    local ruleDefinition = self:parseSequence()

    self:expect( TokenType.SEMICOLON )

    local ruleSymbol = SymbolNode.new( ruleName, false )
    return ParserRuleNode.new( ruleSymbol, ruleDefinition )
end

function GrammarParser:parseSequence()
    local elements = {}

    while true do
        if self:lookup().type == TokenType.ALTERNATION then
            local sequence = SequenceNode.new( elements )
            return self:parseAlternation( sequence )
        end

        if self:lookup().type == TokenType.LPAREN or self:lookup().type == TokenType.TERMINAL or self:lookup().type == TokenType.NON_TERMINAL then
            local symbolNode = self:parseSymbol()
            table.insert( elements, symbolNode )
        else
            break
        end
    end

    return SequenceNode.new( elements )
end

function GrammarParser:parseAlternation( initialSequence )
    local alternatives = { initialSequence }

    while self:lookup().type == TokenType.ALTERNATION do
        self:discard()
        local sequence = self:parseSequence()
        if sequence.type == NodeType.ALTERNATION then
            for _, nestedSequence in ipairs( sequence.alternatives ) do
                table.insert( alternatives, nestedSequence )
            end
        else
            table.insert( alternatives, sequence )
        end
    end

    return AlternationNode.new( alternatives )
end

function GrammarParser:parseSymbol()
    local symbolNode

    if self:lookup().type == TokenType.LPAREN then
        self:discard()
        symbolNode = self:parseSequence()
        self:expect( TokenType.RPAREN )
    elseif self:lookup().type == TokenType.TERMINAL or self:lookup().type == TokenType.NON_TERMINAL then
        local symbol = self:discard() --[[@as Token]]
        local isTerminal = symbol.type == TokenType.TERMINAL
        symbolNode = SymbolNode.new( symbol, isTerminal )
    end

    if self:lookup().type == TokenType.OPTIONAL then
        self:discard()
        local optionalNode = OptionalNode.new( symbolNode )
        return optionalNode
    elseif self:lookup().type == TokenType.ZERO_OR_MORE then
        self:discard()
        local zeroOrMoreNode = ZeroOrMoreNode.new( symbolNode )
        return zeroOrMoreNode
    elseif self:lookup().type == TokenType.ONE_OR_MORE then
        self:discard()
        local oneOrMoreNode = OneOrMoreNode.new( symbolNode )
        return oneOrMoreNode
    end

    return symbolNode
end

return GrammarParser
