local Node = require( "grammar_parsing.node" )
local NodeType = require( "grammar_parsing.grammar_types" ).NodeType

---@class SequenceNode : Node
---@field elements Node[]
local SequenceNode = {}
SequenceNode.__index = SequenceNode
SequenceNode.__type = "SequenceNode"

setmetatable( SequenceNode, { __index = Node } )

--- Creates a new instance of a SequenceNode
---@param elements Node[]
---@return SequenceNode
function SequenceNode.new( elements )
    local line = elements[1] and elements[1].line or 0
    local column = elements[1] and elements[1].column or 0

    local sequenceNode = Node.new( NodeType.SEQUENCE, line, column ) --[[@as SequenceNode]]
    setmetatable( sequenceNode, SequenceNode )
    sequenceNode.elements = elements

    return sequenceNode
end

return SequenceNode
