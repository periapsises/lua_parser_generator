---@class RuleInformation
---@field rule Symbol
---@field alternativeCount integer
---@field optionalCount integer
---@field zeroOrMoreCount integer
---@field oneOrMoreCount integer
---@field position integer
local RuleInformation = {}
RuleInformation.__index = RuleInformation
RuleInformation.__type = "RuleInformation"

--- Creates a new instance of a RuleInformation
---@param rule Symbol
---@param position integer
---@return RuleInformation
function RuleInformation.new( rule, position )
    local ruleInformation = setmetatable( {}, RuleInformation )
    ruleInformation.rule = rule
    ruleInformation.alternativeCount = 0
    ruleInformation.optionalCount = 0
    ruleInformation.zeroOrMoreCount = 0
    ruleInformation.oneOrMoreCount = 0
    ruleInformation.position = position

    return ruleInformation
end

function RuleInformation:getAlternativeName()
    self.alternativeCount = self.alternativeCount + 1
    return self.rule.name .. "_alternative_" .. self.alternativeCount
end

function RuleInformation:getOptionalName()
    self.optionalCount = self.optionalCount + 1
    return self.rule.name .. "_optional_" .. self.optionalCount
end

function RuleInformation:getZeroOrMoreName()
    self.zeroOrMoreCount = self.zeroOrMoreCount + 1
    return self.rule.name .. "_zero_or_more_" .. self.zeroOrMoreCount
end

function RuleInformation:getOneOrMoreName()
    self.oneOrMoreCount = self.oneOrMoreCount + 1
    return self.rule.name .. "_one_or_more_" .. self.oneOrMoreCount
end

return RuleInformation
