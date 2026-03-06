local Node = require( "grammar_parsing.node" )
local NodeType = require( "grammar_parsing.grammar_types" ).NodeType

---@class SymbolNode : Node
---@field name Token
---@field isTerminal boolean
local SymbolNode = {}
SymbolNode.__index = SymbolNode
SymbolNode.__type = "SymbolNode"

setmetatable( SymbolNode, { __index = Node } )

--- Creates a new instance of a SymbolNode
---@param symbol Token
---@param isTerminal boolean
---@return SymbolNode
function SymbolNode.new( symbol, isTerminal )
    local symbolNode = Node.new( NodeType.SYMBOL, symbol.line, symbol.column ) --[[@as SymbolNode]]
    setmetatable( symbolNode, SymbolNode )
    symbolNode.name = symbol
    symbolNode.isTerminal = isTerminal

    return symbolNode
end

return SymbolNode
