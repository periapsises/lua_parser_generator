local Node = require( "grammar_parsing.node" )
local NodeType = require( "grammar_parsing.grammar_types" ).NodeType

---@class OptionalNode : Node
---@field expression Node
local OptionalNode = {}
OptionalNode.__index = OptionalNode
OptionalNode.__type = "OptionalNode"

setmetatable( OptionalNode, { __index = Node } )

--- Creates a new instance of an OptionalNode
---@param expression Node
---@return OptionalNode
function OptionalNode.new( expression )
    local optionalNode = Node.new( NodeType.OPTIONAL, expression.line, expression.column ) --[[@as OptionalNode]]
    setmetatable( optionalNode, OptionalNode )
    optionalNode.expression = expression

    return optionalNode
end

return OptionalNode
