local Symbol = require( "grammar.symbol" )
local LexerRule = require( "grammar.lexer_rule" )
local ParserRule = require( "grammar.parser_rule" )
local Production = require( "grammar.production" )

---@class Grammar
---@field lexerRules LexerRule[]
---@field parserRules ParserRule[]
---@field startRule ParserRule
---@field initialRule ParserRule
---@field eofSymbol Symbol
---@field rulesOfSymbol table<Symbol, ParserRule[]>
---@field productions table<ParserRule, Production[]>
---@field symbols Symbol[]
local Grammar = {}
Grammar.__index = Grammar
Grammar.__type = "Grammar"

--- Creates a new instance of a grammar
---@param lexerRules LexerRule[]
---@param parserRules ParserRule[]
---@return Grammar
function Grammar.new( lexerRules, parserRules )
    local grammar = setmetatable( {}, Grammar )
    grammar.lexerRules = lexerRules
    grammar.parserRules = parserRules
    grammar.startRule = parserRules[1]
    grammar.rulesOfSymbol = {}
    grammar.productions = {}
    grammar.symbols = {}

    local initialSymbol = Symbol.new( "S'", false )
    local eofSymbol = Symbol.new( "EOF", true )
    grammar.eofSymbol = eofSymbol

    local initialRule = ParserRule.new( initialSymbol, { parserRules[1].left, eofSymbol }, 0 )
    grammar.initialRule = initialRule

    table.insert( parserRules, 1, initialRule )
    table.insert( lexerRules, LexerRule.new( eofSymbol, "", true ) )

    local declaredNonTerminals = {}
    for _, parserRule in ipairs( parserRules ) do
        if not parserRule.left.isTerminal then
            declaredNonTerminals[parserRule.left.name] = true
        end
    end

    for _, parserRule in ipairs( parserRules ) do
        for _, symbol in ipairs( parserRule.right ) do
            if not symbol.isTerminal and not declaredNonTerminals[symbol.name] then
                error( "Undefined non-terminal '" .. symbol.name .. "' used in rule: " .. tostring( parserRule ) )
            end
        end
    end

    local hasSymbol = { [eofSymbol] = true }

    for _, lexerRule in ipairs( lexerRules ) do
        if not hasSymbol[lexerRule.token] then
            table.insert( grammar.symbols, lexerRule.token )
            hasSymbol[lexerRule.token] = true
        end
    end

    for _, parserRule in ipairs( parserRules ) do
        local productions = {}
        for position = 0, #parserRule.right do
            local production = Production.new( parserRule, position )
            table.insert( productions, production )
        end
        grammar.productions[parserRule] = productions

        if not hasSymbol[parserRule.left] then
            table.insert( grammar.symbols, parserRule.left )
            hasSymbol[parserRule.left] = true
        end

        if not grammar.rulesOfSymbol[parserRule.left] then
            grammar.rulesOfSymbol[parserRule.left] = {}
        end

        table.insert( grammar.rulesOfSymbol[parserRule.left], parserRule )
    end

    return grammar
end

return Grammar
