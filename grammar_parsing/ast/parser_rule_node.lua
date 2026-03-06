local Node = require( "grammar_parsing.node" )
local NodeType = require( "grammar_parsing.grammar_types" ).NodeType

---@class ParserRuleNode : Node
---@field rule SymbolNode
---@field definition Node
local ParserRuleNode = {}
ParserRuleNode.__index = ParserRuleNode
ParserRuleNode.__type = "RuleNode"

setmetatable( ParserRuleNode, { __index = Node } )

--- Creates a new instance of a RuleNode
---@param rule SymbolNode
---@param definition Node
---@return ParserRuleNode
function ParserRuleNode.new( rule, definition )
    local ruleNode = Node.new( NodeType.PARSER_RULE, rule.line, rule.column ) --[[@as ParserRuleNode]]
    setmetatable( ruleNode, ParserRuleNode )
    ruleNode.rule = rule
    ruleNode.definition = definition

    return ruleNode
end

return ParserRuleNode
