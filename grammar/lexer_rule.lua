---@class LexerRule
---@field token Symbol
---@field pattern string
---@field isSkipped boolean
local LexerRule = {}
LexerRule.__index = LexerRule
LexerRule.__type = "LexerRule"

--- Creates a new instance of a LexerRule
---@param token Symbol
---@param pattern string
---@param isSkipped boolean
---@return LexerRule
function LexerRule.new( token, pattern, isSkipped )
    local lexerRule = setmetatable( {}, LexerRule )
    lexerRule.token = token
    lexerRule.pattern = pattern
    lexerRule.isSkipped = isSkipped

    return lexerRule
end

return LexerRule
