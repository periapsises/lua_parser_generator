local Node = require( "grammar_parsing.node" )
local NodeType = require( "grammar_parsing.grammar_types" ).NodeType

---@class ZeroOrMoreNode : Node
---@field expression Node
local ZeroOrMoreNode = {}
ZeroOrMoreNode.__index = ZeroOrMoreNode
ZeroOrMoreNode.__type = "ZeroOrMoreNode"

setmetatable( ZeroOrMoreNode, { __index = Node } )

--- Creates a new instance of a ZeroOrMoreNode
---@param expression Node
---@return ZeroOrMoreNode
function ZeroOrMoreNode.new( expression )
    local zeroOrMoreNode = Node.new( NodeType.ZERO_OR_MORE, expression.line, expression.column ) --[[@as ZeroOrMoreNode]]
    setmetatable( zeroOrMoreNode, ZeroOrMoreNode )
    zeroOrMoreNode.expression = expression

    return zeroOrMoreNode
end

return ZeroOrMoreNode
