local UUID = require( "util.uuid" )
local Action = require( "parser_generator.action" )
local ActionType = require( "parser_generator.action_type" )

---@class State
---@field id integer
---@field initialProductions Production[]
---@field productions Production[]
---@field uuid string
---@field actions table<Symbol, Action>
local State = {}
State.__index = State
State.__type = "State"

---@param productions Production[]
---@return string
function State.getUUIDFromProductions( productions )
    if #productions == 1 then
        return productions[1].uuid
    end

    local uuids = {}
    for _, production in ipairs( productions ) do
        table.insert( uuids, production.uuid )
    end

    return UUID.merge( uuids )
end

--- Creates a new instance of a state
---@return State
function State.new( productions, id )
    local state = setmetatable( {}, State )
    state.id = id
    state.initialProductions = productions
    state.productions = {}
    state.uuid = State.getUUIDFromProductions( productions )
    state.actions = {}

    for _, production in ipairs( productions ) do
        table.insert( state.productions, production )
    end

    return state
end

---@param grammar Grammar
function State:expandProductions( grammar )
    local visited = {}
    for _, production in ipairs( self.productions ) do
        local nextSymbol = production:getNextSymbol()

        if nextSymbol and not nextSymbol.isTerminal and not visited[nextSymbol.name] then
            visited[nextSymbol.name] = true
            local rules = grammar.rulesOfSymbol[nextSymbol]
            for _, rule in ipairs( rules ) do
                table.insert( self.productions, grammar.productions[rule][1] )
            end
        end
    end
end

--- Renders an LR item (production with dot) as a human-readable string.
---@param production Production
---@return string
local function formatItem( production )
    local rule  = production.rule
    local parts = { rule.left.name .. " ->" }

    for i, sym in ipairs( rule.right ) do
        if i == production.position + 1 then
            table.insert( parts, "." )
        end
        table.insert( parts, sym.name )
    end

    if production.isComplete then
        table.insert( parts, "." )
    end

    return table.concat( parts, " " )
end

--- Finds all items in this state that want to shift the given symbol.
---@param symbol Symbol
---@return string[]
function State:shiftItemsFor( symbol )
    local items = {}
    for _, production in ipairs( self.productions ) do
        if production:getNextSymbol() == symbol then
            table.insert( items, "    shift:  " .. formatItem( production ) )
        end
    end
    return items
end

function State:addAction( symbol, action )
    local existingAction = self.actions[symbol]
    if existingAction then
        local header = "\nConflict in state " .. self.id .. " on lookahead '" .. symbol.name .. "':\n"

        if existingAction.type == ActionType.SHIFT and action.type == ActionType.SHIFT then
            local lines = { header }
            for _, item in ipairs( self:shiftItemsFor( symbol ) ) do
                table.insert( lines, item )
            end
            table.insert( lines, "    shift:  (into state " .. action.state.id .. " — duplicate)" )
            error( table.concat( lines, "\n" ) )

        elseif existingAction.type == ActionType.SHIFT and action.type == ActionType.REDUCE then
            local lines = { header }
            for _, item in ipairs( self:shiftItemsFor( symbol ) ) do
                table.insert( lines, item )
            end
            table.insert( lines, "    reduce: " .. formatItem( action.production ) )
            error( table.concat( lines, "\n" ) )

        elseif existingAction.type == ActionType.REDUCE and action.type == ActionType.REDUCE then
            local lines = { header }
            table.insert( lines, "    reduce: " .. formatItem( existingAction.production ) )
            table.insert( lines, "    reduce: " .. formatItem( action.production ) )
            error( table.concat( lines, "\n" ) )

        elseif existingAction.type == ActionType.REDUCE and action.type == ActionType.SHIFT then
            local lines = { header }
            table.insert( lines, "    reduce: " .. formatItem( existingAction.production ) )
            for _, item in ipairs( self:shiftItemsFor( symbol ) ) do
                table.insert( lines, item )
            end
            error( table.concat( lines, "\n" ) )

        else
            error( header .. "    (unknown conflict type)" )
        end
    end

    self.actions[symbol] = action
end

--- Adds a shift action for a given symbol
---@param symbol Symbol
---@param state State
function State:addShiftAction( symbol, state )
    local action = Action.new( ActionType.SHIFT )
    action.state = state
    self:addAction( symbol, action )
end

--- Adds a reduce action for a given symbol
---@param symbol Symbol
---@param production Production
function State:addReduceAction( symbol, production )
    local action = Action.new( ActionType.REDUCE )
    action.production = production
    self:addAction( symbol, action )
end

--- Adds an accept action
function State:addAcceptAction( symbol )
    local action = Action.new( ActionType.ACCEPT )
    -- Accept action can override other actions (it's the final state)
    if self.actions[symbol] and self.actions[symbol].type ~= ActionType.ACCEPT then
        -- Replace existing action with accept
        self.actions[symbol] = action
    else
        self:addAction( symbol, action )
    end
end

return State
