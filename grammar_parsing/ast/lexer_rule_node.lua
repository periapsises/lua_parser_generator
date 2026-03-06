local Node = require( "grammar_parsing.node" )
local NodeType = require( "grammar_parsing.grammar_types" ).NodeType

---@class LexerRuleNode : Node
---@field name Token
---@field content Token
---@field isSkipped boolean
local LexerRuleNode = {}
LexerRuleNode.__index = LexerRuleNode
LexerRuleNode.__type = "TokenNode"

setmetatable( LexerRuleNode, { __index = Node } )

--- Creates a new instance of a TokenNode
---@param name Token
---@param content Token
---@param isSkipped boolean
---@return LexerRuleNode
function LexerRuleNode.new( name, content, isSkipped )
    local tokenNode = Node.new( NodeType.LEXER_RULE, name.line, name.column ) --[[@as LexerRuleNode]]
    setmetatable( tokenNode, LexerRuleNode )
    tokenNode.name = name
    tokenNode.content = content
    tokenNode.isSkipped = isSkipped

    return tokenNode
end

return LexerRuleNode
