local UUID = require( "util.uuid" )

---@class Production
---@field rule ParserRule
---@field position number
---@field lookaheads table<string, Symbol>
---@field isComplete boolean
---@field uuid string
local Production = {}
Production.__index = Production
Production.__type = "Production"

--- Creates a new production for a rule
---@param rule ParserRule # The rule this production represents
---@param position number # The current position in the rule
---@return Production
function Production.new( rule, position )
    local production = setmetatable( {}, Production )
    production.rule = rule
    production.position = position
    production.lookaheads = {}
    production.isComplete = position == #rule.right
    production.uuid = UUID.new()

    return production
end

--- Gets the next symbol the production expects
---@return Symbol?
function Production:getNextSymbol()
    if self.isComplete then return end

    return self.rule.right[self.position + 1]
end

return Production
