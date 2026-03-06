---@class ParserRule
---@field left Symbol
---@field right Symbol[]
---@field position integer
local ParserRule = {}
ParserRule.__index = ParserRule
ParserRule.__type = "Rule"

--- Creates a new instance of a Rule
---@param left Symbol # The left symbol of the rules
---@param right Symbol[] # The symbols on the right of the rule
---@param position integer
---@return ParserRule
function ParserRule.new( left, right, position )
    local rule = setmetatable( {}, ParserRule )
    rule.left = left
    rule.right = right
    rule.position = position

    return rule
end

function ParserRule:__tostring()
    local output = self.left.name .. ": "
    for _, symbol in ipairs( self.right ) do
        output = output .. symbol.name .. " "
    end

    if #self.right == 0 then
        output = output .. "<empty>"
    end

    return output
end

return ParserRule
