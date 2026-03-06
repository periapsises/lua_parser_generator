---@class Symbol
---@field name string
---@field isTerminal boolean
local Symbol = {}
Symbol.__index = Symbol
Symbol.__type = "Symbol"

--- Creates a new instance of a Symbol
---@param name string
---@param isTerminal boolean
---@return Symbol
function Symbol.new( name, isTerminal )
    local symbol = setmetatable( {}, Symbol )
    symbol.name = name
    symbol.isTerminal = isTerminal

    return symbol
end

return Symbol
