local State = require( "parser_generator.state" )

---@class StateManager
---@field states State[]
---@field stateByUUID table<string, State>
---@field grammar Grammar
---@field stateCount integer
local StateManager = {}
StateManager.__index = StateManager
StateManager.__type = "StateManager"

--- Creates a new instance of a StateManager
---@param grammar Grammar
---@return StateManager
function StateManager.new( grammar )
    local stateManager = setmetatable( {}, StateManager )
    stateManager.states = {}
    stateManager.stateByUUID = {}
    stateManager.grammar = grammar
    stateManager.stateCount = 0

    return stateManager
end

--- Gets a state for the given productions and caches it.
---@param productions Production[]
---@return State # The state for the given productions
---@return boolean # Whether the state was created or retrieved from the cache
function StateManager:getStateForProductions( productions )
    local uuid = State.getUUIDFromProductions( productions )
    if self.stateByUUID[uuid] then
        return self.stateByUUID[uuid], false
    end

    self.stateCount = self.stateCount + 1

    local state = State.new( productions, self.stateCount )
    state:expandProductions( self.grammar )

    table.insert( self.states, state )
    self.stateByUUID[uuid] = state

    return state, true
end

return StateManager
