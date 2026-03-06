local Node = require( "grammar_parsing.node" )
local NodeType = require( "grammar_parsing.grammar_types" ).NodeType

---@class OneOrMoreNode : Node
---@field expression Node
local OneOrMoreNode = {}
OneOrMoreNode.__index = OneOrMoreNode
OneOrMoreNode.__type = "OneOrMoreNode"

setmetatable( OneOrMoreNode, { __index = Node } )

--- Creates a new instance of a OneOrMoreNode
---@param expression Node
---@return OneOrMoreNode
function OneOrMoreNode.new( expression )
    local oneOrMoreNode = Node.new( NodeType.ONE_OR_MORE, expression.line, expression.column ) --[[@as OneOrMoreNode]]
    setmetatable( oneOrMoreNode, OneOrMoreNode )
    oneOrMoreNode.expression = expression

    return oneOrMoreNode
end

return OneOrMoreNode
