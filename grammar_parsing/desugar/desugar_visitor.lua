local RuleInformation = require( "grammar_parsing.desugar.rule_information" )
local SymbolManager = require( "grammar.symbol_manager" )
local LexerRule = require( "grammar.lexer_rule" )
local ParserRule = require( "grammar.parser_rule" )
local Types = require( "grammar_parsing.grammar_types" )
local NodeType = Types.NodeType

---@class DesugarVisitor
---@field lexerRules LexerRule[]
---@field parserRules ParserRule[]
---@field ruleInformationStack RuleInformation[]
---@field rulePosition integer
---@field symbolmanager SymbolManager
local DesugarVisitor = {}
DesugarVisitor.__index = DesugarVisitor
DesugarVisitor.__type = "DesugarVisitor"

--- Creates a new instance of a DesugarVisitor
---@return DesugarVisitor
function DesugarVisitor.new()
    local desugarVisitor = setmetatable( {}, DesugarVisitor )
    desugarVisitor.lexerRules = {}
    desugarVisitor.parserRules = {}
    desugarVisitor.ruleInformationStack = {}
    desugarVisitor.rulePosition = 0
    desugarVisitor.symbolmanager = SymbolManager.new()

    return desugarVisitor
end

---@param rule Symbol
function DesugarVisitor:pushRuleSymbol( rule )
    self.rulePosition = self.rulePosition + 1

    table.insert( self.ruleInformationStack, RuleInformation.new( rule, self.rulePosition ) )
end

---@return Symbol
function DesugarVisitor:popRuleSymbol()
    if #self.ruleInformationStack == 0 then
        error( "Stack underflow" )
    end

    return table.remove( self.ruleInformationStack ).rule
end

---@return RuleInformation
function DesugarVisitor:ruleInformation()
    local ruleInformation = self.ruleInformationStack[#self.ruleInformationStack]
    if not ruleInformation then
        error( "Stack is empty" )
    end

    return ruleInformation
end

---@param sequence Symbol[]
function DesugarVisitor:addSequenceToRule( sequence )
    local ruleInformation = self:ruleInformation()
    table.insert( self.parserRules, ParserRule.new( ruleInformation.rule, sequence, ruleInformation.position ) )
end

---@param grammar GrammarNode
---@return LexerRule[], ParserRule[]
function DesugarVisitor:visitGrammar( grammar )
    for _, tokenDeclaration in ipairs( grammar.tokenDeclarations ) do
        local lexerSymbol = self.symbolmanager:getSymbol( tokenDeclaration.name.text, true )
        table.insert( self.lexerRules, LexerRule.new( lexerSymbol, tokenDeclaration.content.text, tokenDeclaration.isSkipped ) )
    end

    for _, ruleDeclaration in ipairs( grammar.ruleDeclarations ) do
        self:visitRuleDeclaration( ruleDeclaration )
    end

    ---@param ruleA ParserRule
    ---@param ruleB ParserRule
    local function sortParserRules( ruleA, ruleB )
        if ruleA.position == ruleB.position then
            return #ruleA.right > #ruleB.right
        end

        return ruleA.position < ruleB.position
    end

    table.sort( self.parserRules, sortParserRules )

    return self.lexerRules, self.parserRules
end

---@param ruleDeclaration ParserRuleNode
function DesugarVisitor:visitRuleDeclaration( ruleDeclaration )
    local rule = self.symbolmanager:getSymbol( ruleDeclaration.rule.name.text, false )
    self:pushRuleSymbol( rule )
    self:visitRuleContents( ruleDeclaration.definition )
    self:popRuleSymbol()
end

---@param node Node
function DesugarVisitor:visitRuleContents( node )
    if node.type == NodeType.ALTERNATION then
        self:visitAlternation( node --[[@as AlternationNode]] )
    else
        local symbols = self:visitSequence( node --[[@as SequenceNode]] )
        self:addSequenceToRule( symbols )
    end
end

---@param alternation AlternationNode
function DesugarVisitor:visitAlternation( alternation )
    for _, alternative in ipairs( alternation.alternatives ) do
        local symbols = self:visitSequence( alternative )
        self:addSequenceToRule( symbols )
    end
end

---@param sequence SequenceNode
---@return Symbol[]
function DesugarVisitor:visitSequence( sequence )
    local symbols = {}

    for _, element in ipairs( sequence.elements ) do
        local subSymbols = self:visitSequenceElement( element )
        for _, subSymbol in ipairs( subSymbols ) do
            table.insert( symbols, subSymbol )
        end
    end

    return symbols
end

---@param element Node
---@return Symbol[]
function DesugarVisitor:visitSequenceElement( element )
    if element.type == NodeType.SEQUENCE then
        return self:visitSequence( element --[[@as SequenceNode]] )
    elseif element.type == NodeType.ALTERNATION then
        return { self:visitSubAlternation( element --[[@as AlternationNode]] ) }
    elseif element.type == NodeType.OPTIONAL then
        return { self:visitOptional( element --[[@as OptionalNode]] ) }
    elseif element.type == NodeType.ZERO_OR_MORE then
        return { self:visitZeroOrMore( element --[[@as ZeroOrMoreNode]] ) }
    elseif element.type == NodeType.ONE_OR_MORE then
        return { self:visitOneOrMore( element --[[@as OneOrMoreNode]] ) }
    else
        return { self:visitSymbol( element --[[@as SymbolNode]] ) }
    end
end

---@param alternation AlternationNode
---@return Symbol
function DesugarVisitor:visitSubAlternation( alternation )
    local alternationName = self:ruleInformation():getAlternativeName()
    local symbol = self.symbolmanager:getSymbol( alternationName, false )
    self:pushRuleSymbol( symbol )

    self:visitAlternation( alternation )

    return self:popRuleSymbol()
end

---@param optional OptionalNode
---@return Symbol
function DesugarVisitor:visitOptional( optional )
    local optionalName = self:ruleInformation():getOptionalName()
    local symbol = self.symbolmanager:getSymbol( optionalName, false )
    self:pushRuleSymbol( symbol )

    local elements = self:visitSequenceElement( optional.expression )
    self:addSequenceToRule( elements )
    self:addSequenceToRule( {} )

    return self:popRuleSymbol()
end

---@param zeroOrMoreNode ZeroOrMoreNode
---@return Symbol
function DesugarVisitor:visitZeroOrMore( zeroOrMoreNode )
    local zeroOrMoreName = self:ruleInformation():getZeroOrMoreName()
    local symbol = self.symbolmanager:getSymbol( zeroOrMoreName, false )
    self:pushRuleSymbol( symbol )

    local elements = self:visitSequenceElement( zeroOrMoreNode.expression )
    local recursiveElements = {}
    for i, element in ipairs( elements ) do
        recursiveElements[i] = element
    end
    table.insert( recursiveElements, symbol )

    self:addSequenceToRule( recursiveElements )
    self:addSequenceToRule( {} )

    return self:popRuleSymbol()
end

---@param oneOrMoreNode OneOrMoreNode
---@return Symbol
function DesugarVisitor:visitOneOrMore( oneOrMoreNode )
    local oneOrMoreName = self:ruleInformation():getOneOrMoreName()
    local symbol = self.symbolmanager:getSymbol( oneOrMoreName, false )
    self:pushRuleSymbol( symbol )

    local elements = self:visitSequenceElement( oneOrMoreNode.expression )
    local recursiveElements = {}
    for i, element in ipairs( elements ) do
        recursiveElements[i] = element
    end
    table.insert( recursiveElements, symbol )

    self:addSequenceToRule( recursiveElements )
    self:addSequenceToRule( elements )

    return self:popRuleSymbol()
end

---@param symbol SymbolNode
---@return Symbol
function DesugarVisitor:visitSymbol( symbol )
    return self.symbolmanager:getSymbol( symbol.name.text, symbol.isTerminal )
end

return DesugarVisitor
