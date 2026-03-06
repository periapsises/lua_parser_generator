---@class Action
---@field type ActionType
---@field state State?
---@field production Production?
local Action = {}

--- Creates a new instance of an action
---@param type ActionType
---@return Action
function Action.new( type )
    local action = setmetatable( {}, Action )
    action.type = type
    action.state = nil
    action.production = nil

    return action
end

return Action
