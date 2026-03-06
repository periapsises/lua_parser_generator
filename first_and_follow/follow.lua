local FollowSet = require( "first_and_follow.follow_set" )

--- Initializes the follow sets for a given grammar
---@param grammar Grammar
---@return table<Symbol, FollowSet>
local function initializeFollowSets( grammar )
    ---@type table<Symbol, FollowSet>
    local followSets = {}

    for _, parserRule in ipairs( grammar.parserRules ) do
        if not followSets[parserRule.left] then
            local followSet = FollowSet.new()

            followSets[parserRule.left] = followSet
        end
    end

    followSets[grammar.startRule.left]:add( grammar.eofSymbol )

    return followSets
end

--- Runs an iteration of generating follow sets for the grammar.
--- Returns true if anything was changed
---@param followSets table<Symbol, FollowSet>
---@param firstSets table<Symbol, FirstSet>
---@param grammar Grammar
---@return boolean
local function iterateFollowSetsGeneration( followSets, firstSets, grammar )
    local changed = false

    ---@param followSet FollowSet
    ---@param symbols Symbol[]
    local function addAllTerminals( followSet, symbols )
        for _, symbol in ipairs( symbols ) do
            changed = changed or symbol.isTerminal and followSet:add( symbol )
        end
    end

    ---@param parserRule ParserRule
    ---@param position integer
    ---@param followSet FollowSet
    ---@return boolean
    local function addAllFirstsAfter( parserRule, position, followSet )
        for followingPosition = position + 1, #parserRule.right do
            local followingSymbol = parserRule.right[followingPosition]
            local followingFirstSet = firstSets[followingSymbol]

            addAllTerminals( followSet, followingFirstSet.list )

            if not followingFirstSet.canBeEmpty then
                return false
            end
        end

        return true
    end

    for _, parserRule in ipairs( grammar.parserRules ) do
        local symbolCount = #parserRule.right
        local ruleFollowSet = followSets[parserRule.left]

        for currentPosition = 1, symbolCount do
            local currentSymbol = parserRule.right[currentPosition]

            if not currentSymbol.isTerminal then
                local followSet = followSets[currentSymbol]
                if not followSet then
                    followSet = FollowSet.new()
                    followSets[currentSymbol] = followSet
                end
                local suffixCanBeEmpty = addAllFirstsAfter( parserRule, currentPosition, followSet )

                if suffixCanBeEmpty then
                    addAllTerminals( followSet, ruleFollowSet.list )
                end
            end
        end
    end

    return changed
end

--- Computes the follow sets of a given grammar.
---@param firstSets table<Symbol, FirstSet>
---@param grammar Grammar
---@return table<Symbol, FollowSet>
local function computeFollowSets( firstSets, grammar )
    local followSets = initializeFollowSets( grammar )

    repeat
        local changed = iterateFollowSetsGeneration( followSets, firstSets, grammar )
    until not changed

    return followSets
end

return computeFollowSets
