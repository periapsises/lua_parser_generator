local GrammarLexer = require( "grammar_parsing.grammar_lexer" )
local GrammarParser = require( "grammar_parsing.grammar_parser" )
local DesugarVisitor = require( "grammar_parsing.desugar.desugar_visitor" )
local Grammar = require( "grammar.grammar" )
local computeFirstSets = require( "first_sets.first" )
local StateManager = require( "parser_generator.state_manager" )

---@class ParserGenerator
---@field inputFile string
---@field outputPath string
---@field grammar Grammar
---@field firstSets table<Symbol, FirstSet>
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
    parserGenerator.stateManager = StateManager.new( parserGenerator.grammar )

    return parserGenerator
end

function ParserGenerator:generate()
    local startProduction = self.grammar.productions[self.grammar.initialRule][1]
    local startState = self.stateManager:getStateForProductions( { startProduction } )

    self:buildStates( startState )
    self:computeLookaheads()
    self:addReduceActions()
end

local MARKER = {}

--- Computes LALR(1) lookaheads using the DeRemer/Pennello method.
--  Discovers spontaneous lookaheads from FIRST sets of rule tails and the
--  initial EOF lookahead on the augmented start production, records
--  propagation relationships between items/states, and then iteratively
--  propagates lookaheads along those edges until a fixed point is reached.
function ParserGenerator:computeLookaheads()
    local startProduction = self.grammar.productions[self.grammar.initialRule][1]
    local eofSymbol = self.grammar.eofSymbol

    startProduction.lookaheads[eofSymbol.name] = eofSymbol

    local function firstOfTail( rule, startPosition, lookahead )
        local terminals = {}
        for position = startPosition, #rule.right do
            local symbol = rule.right[position]
            if symbol.isTerminal then
                table.insert( terminals, symbol )
                return terminals
            else
                for _, firstSymbol in ipairs( self.firstSets[symbol].list ) do
                    if firstSymbol ~= MARKER then
                        table.insert( terminals, firstSymbol )
                    end
                end

                if not self.firstSets[symbol].canBeEmpty then
                    return terminals
                end
            end
        end

        table.insert( terminals, lookahead )
        return terminals
    end

    local propagationEdges = {}

    for _, state in ipairs( self.stateManager.states ) do
        for _, production in ipairs( state.initialProductions ) do
            local worklist = { { production = production, lookahead = MARKER } }

            local visited = {}
            for _, item in ipairs( worklist ) do
                local lookaheadKey = ( item.lookahead == MARKER ) and "MARKER" or item.lookahead.name
                local key = item.production.uuid .. "\0" .. lookaheadKey
                if visited[key] then goto continue end
                visited[key] = true

                local nextSymbol = item.production:getNextSymbol()
                if nextSymbol then
                    local advancedProduction = self.grammar.productions[item.production.rule][item.production.position + 2]

                    if item.lookahead == MARKER then
                        table.insert( propagationEdges, { from = production, to = advancedProduction } )
                    else
                        advancedProduction.lookaheads[item.lookahead.name] = item.lookahead
                    end

                    if not nextSymbol.isTerminal then
                        local rules = self.grammar.rulesOfSymbol[nextSymbol]
                        for _, rule in ipairs( rules ) do
                            local newProduction = self.grammar.productions[rule][1]
                            for _, terminal in ipairs( firstOfTail( item.production.rule, item.production.position + 2, item.lookahead ) ) do
                                table.insert( worklist, { production = newProduction, lookahead = terminal } )
                            end
                        end
                    end
                else
                    if item.lookahead == MARKER then
                        table.insert( propagationEdges, { from = production, to = item.production } )
                    else
                        item.production.lookaheads[item.lookahead.name] = item.lookahead
                    end
                end

                ::continue::
            end
        end
    end

    repeat
        local changed = false

        for _, edge in ipairs( propagationEdges ) do
            for name, symbol in pairs( edge.from.lookaheads ) do
                if not edge.to.lookaheads[name] then
                    edge.to.lookaheads[name] = symbol
                    changed = true
                end
            end
        end
    until not changed
end

--- Builds states by computing shift/accept actions and recursively creating successor states
---@param state State
function ParserGenerator:buildStates( state )
    ---@type table<Symbol, Production[]>
    local possibleShifts = {}

    for _, production in ipairs( state.productions ) do
        if not production.isComplete then
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
            self:buildStates( nextState )
        end
    end
end

function ParserGenerator:addReduceActions()
    for _, state in ipairs( self.stateManager.states ) do
        for _, production in ipairs( state.productions ) do
            if production.isComplete then
                self:addReduceAction( state, production )
            end
        end
    end
end

--- Adds a reduce action for a given state and production
---@param state State
---@param production Production
function ParserGenerator:addReduceAction( state, production )
    for _, symbol in pairs( production.lookaheads ) do
        state:addReduceAction( symbol, production )
    end
end

return ParserGenerator
