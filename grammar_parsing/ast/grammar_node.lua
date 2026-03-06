local Node = require( "grammar_parsing.node" )
local NodeType = require( "grammar_parsing.grammar_types" ).NodeType

---@class GrammarNode : Node
---@field tokenDeclarations LexerRuleNode[]
---@field ruleDeclarations ParserRuleNode[]
local GrammarNode = {}
GrammarNode.__index = GrammarNode
GrammarNode.__type = "GrammarNode"

setmetatable( GrammarNode, { __index = Node } )

--- Creates a new instance of a GrammarNode
---@param tokenDeclarations LexerRuleNode[]
---@param ruleDeclarations ParserRuleNode[]
---@return GrammarNode
function GrammarNode.new( tokenDeclarations, ruleDeclarations )
    local grammarNode = Node.new( NodeType.GRAMMAR, 1, 1 ) --[[@as GrammarNode]]
    setmetatable( grammarNode, GrammarNode )
    grammarNode.tokenDeclarations = tokenDeclarations
    grammarNode.ruleDeclarations = ruleDeclarations

    return grammarNode
end

return GrammarNode
