local Symbol = require( "grammar.symbol" )

---@class SymbolManager
---@field symbols table<string, Symbol>
---@field isTerminal table<string, boolean>
local SymbolManager = {}
SymbolManager.__index = SymbolManager
SymbolManager.__type = "SymbolManager"

--- Creates a new instance of a SymbolManager
---@return SymbolManager
function SymbolManager.new()
    local symbolManager = setmetatable( {}, SymbolManager )
    symbolManager.symbols = {}
    symbolManager.isTerminal = {}

    return symbolManager
end

--- Returns a symbol for the given name and caches it.
---@param name string
---@param isTerminal boolean
---@return Symbol
function SymbolManager:getSymbol( name, isTerminal )
    if self.symbols[name] then
        if self.isTerminal[name] ~= isTerminal then
            error( "A symbol with the same name already exists in a different configuration" )
        end

        return self.symbols[name]
    end

    local symbol = Symbol.new( name, isTerminal )
    self.symbols[name] = symbol
    self.isTerminal[name] = isTerminal

    return symbol
end

return SymbolManager
