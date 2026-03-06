local Node = require( "grammar_parsing.node" )
local NodeType = require( "grammar_parsing.grammar_types" ).NodeType

---@class AlternationNode : Node
---@field alternatives SequenceNode[]
local AlternationNode = {}
AlternationNode.__index = AlternationNode
AlternationNode.__type = "AlternationNode"

setmetatable( AlternationNode, { __index = Node } )

--- Creates a new instance of an AlternationNode
---@param alternatives SequenceNode[]
---@return AlternationNode
function AlternationNode.new( alternatives )
    local alternationNode = Node.new( NodeType.ALTERNATION, alternatives[1].line, alternatives[1].column ) --[[@as AlternationNode]]
    setmetatable( alternationNode, AlternationNode )
    alternationNode.alternatives = alternatives

    return alternationNode
end

return AlternationNode
