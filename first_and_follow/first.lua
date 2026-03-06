local FirstSet = require( "first_and_follow.first_set" )

--- Initializes the first sets for a given grammar
---@param grammar Grammar
---@return table<Symbol, FirstSet>
local function initializeFirstSets( grammar )
    ---@type table<Symbol, FirstSet>
    local firstSets = {}

    for _, lexerRule in ipairs( grammar.lexerRules ) do
        local firstSet = FirstSet.new()
        firstSet:add( lexerRule.token )

        firstSets[lexerRule.token] = firstSet
    end

    for _, parserRule in ipairs( grammar.parserRules ) do
        local firstSet = FirstSet.new()

        if #parserRule.right == 0 then
            firstSet.canBeEmpty = true
        end

        firstSets[parserRule.left] = firstSet
    end

    return firstSets
end

--- Runs an iteration of generating first sets for the grammar.
--- Returns true if anything was changed
---@param firstSets table<Symbol, FirstSet>
---@param grammar Grammar
---@return boolean
local function iterateFirstSetsGeneration( firstSets, grammar )
    local changed = false

    for _, parserRule in ipairs( grammar.parserRules ) do
        local rightHandSideCanBeEmpty = true
        for _, symbol in ipairs( parserRule.right ) do
            if symbol.isTerminal then
                rightHandSideCanBeEmpty = false
                break
            end

            if not firstSets[symbol].canBeEmpty then
                rightHandSideCanBeEmpty = false
                break
            end
        end

        if rightHandSideCanBeEmpty and not firstSets[parserRule.left].canBeEmpty then
            firstSets[parserRule.left].canBeEmpty = true
            changed = true
        end

        for _, symbol in ipairs( parserRule.right ) do
            local firstSet = firstSets[symbol]

            for _, firstSetSymbol in ipairs( firstSet.list ) do
                if firstSetSymbol.isTerminal then
                    changed = changed or firstSets[parserRule.left]:add( firstSetSymbol )
                end
            end

            if symbol.isTerminal or not firstSets[symbol].canBeEmpty then
                break
            end
        end
    end

    return changed
end

--- Computes the first sets of a given grammar.
---@param grammar Grammar
---@return table<Symbol, FirstSet>
local function computeFirstSets( grammar )
    local firstSets = initializeFirstSets( grammar )

    repeat
        local changed = iterateFirstSetsGeneration( firstSets, grammar )
    until not changed

    return firstSets
end

return computeFirstSets
