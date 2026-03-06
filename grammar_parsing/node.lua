---@class Node
---@field type integer
---@field line integer
---@field column integer
local Node = {}
Node.__index = Node
Node.__type = "Node"

--- Creates a new instance of a Node
---@param type integer
---@param line integer
---@param column integer
---@return Node
function Node.new( type, line, column )
    local node = setmetatable( {}, Node )
    node.type = type
    node.line = line
    node.column = column

    return node
end

return Node
