local Node = require( "grammar_parsing.node" )

---@class Token : Node
---@field text string
local Token = {}
Token.__index = Token
Token.__type = "Token"

setmetatable( Token, { __index = Node } )

--- Creates a new instance of a Token
---@param text string
---@param type number
---@param line number
---@param column number
---@return Token
function Token.new( text, type, line, column )
    local token = Node.new( type, line, column ) --[[@as Token]]
    setmetatable( token, Token )
    token.text = text

    return token
end

return Token
