local GrammarLexer = require( "grammar_parsing.grammar_lexer" )
local GrammarParser = require( "grammar_parsing.grammar_parser" )
local DesugarVisitor = require( "grammar_parsing.desugar.desugar_visitor" )
local Grammar = require( "grammar.grammar" )
local computeFirstSets = require( "first_and_follow.first" )
local computeFollowSets = require( "first_and_follow.follow" )
local StateManager = require( "parser_generator.state_manager" )

---@class ParserGenerator
---@field inputFile string
---@field outputPath string
---@field grammar Grammar
---@field firstSets table<Symbol, FirstSet>
---@field followSets table<Symbol, FollowSet>
---@field stateManager StateManager
local ParserGenerator = {}
ParserGenerator.__index = ParserGenerator
ParserGenerator.__type = "ParserGenerator"

--- Creates a new instance of a ParserGenerator
---@return ParserGenerator
function ParserGenerator.new( inputFile, outputPath )
    local parserGenerator = setmetatable( {}, ParserGenerator )
    parserGenerator.inputFile = inputFile
    parserGenerator.outputPath = outputPath

    local grammarLexer = GrammarLexer.fromFile( inputFile )
    local grammarParser = GrammarParser.new( grammarLexer )
    local grammarTree = grammarParser:parseGrammar()
    local desugarVisitor = DesugarVisitor.new()
    local lexerRules, parserRules = desugarVisitor:visitGrammar( grammarTree )
    parserGenerator.grammar = Grammar.new( lexerRules, parserRules )

    parserGenerator.firstSets = computeFirstSets( parserGenerator.grammar )
    parserGenerator.followSets = computeFollowSets( parserGenerator.firstSets, parserGenerator.grammar )

    parserGenerator.stateManager = StateManager.new( parserGenerator.grammar )

    return parserGenerator
end

function ParserGenerator:generate()
    local startProduction = self.grammar.productions[self.grammar.initialRule][1]
    local startState = self.stateManager:getStateForProductions( { startProduction } )

    self:fillStateActions( startState )
end

--- Fills the actions for a given state
---@param state State
function ParserGenerator:fillStateActions( state )
    ---@type table<Symbol, Production[]>
    local possibleShifts = {}

    for _, production in ipairs( state.productions ) do
        if production.isComplete then
            -- Don't add reduce actions for the initial rule (S') - acceptance is handled separately
            if production.rule.left ~= self.grammar.initialRule.left then
                self:addReduceAction( state, production )
            end
        else
            local nextSymbol = production:getNextSymbol()
            if not nextSymbol then
                error( "A production is not complete but has no next symbol" )
            end

            -- Special case: if this is the initial rule shifting EOF, add ACCEPT instead of SHIFT
            if production.rule == self.grammar.initialRule and nextSymbol == self.grammar.eofSymbol then
                state:addAcceptAction( nextSymbol )
            else
                if not possibleShifts[nextSymbol] then
                    possibleShifts[nextSymbol] = {}
                end

                local advancedProduction = self.grammar.productions[production.rule][production.position + 2]
                table.insert( possibleShifts[nextSymbol], advancedProduction )
            end
        end
    end

    for nextSymbol, productions in pairs( possibleShifts ) do
        local nextState, isNewState = self.stateManager:getStateForProductions( productions )
        state:addShiftAction( nextSymbol, nextState )

        if isNewState then
            self:fillStateActions( nextState )
        end
    end
end

--- Adds a reduce action for a given state and production
---@param state State
---@param production Production
function ParserGenerator:addReduceAction( state, production )
    local followSet = self.followSets[production.rule.left]
    if not followSet then
        error( "Follow set not found for symbol: " .. production.rule.left.name )
    end
    local followers = followSet.list
    for _, follower in ipairs( followers ) do
        state:addReduceAction( follower, production )
    end
end

return ParserGenerator
