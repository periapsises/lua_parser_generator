---@class FirstSet
---@field list Symbol[]
---@field hasSymbol table<Symbol, boolean>
---@field canBeEmpty boolean
local FirstSet = {}
FirstSet.__index = FirstSet
FirstSet.__type = "FirstSet"

--- Creates an instance of a FirstSet.
---@return FirstSet
function FirstSet.new()
    local firstSet = setmetatable( {}, FirstSet )
    firstSet.list = {}
    firstSet.hasSymbol = {}
    firstSet.canBeEmpty = false

    return firstSet
end

--- Adds a symbol to the set.  
--- Returns wether or not the symbol was added to the list.
---@param symbol Symbol
---@return boolean
function FirstSet:add( symbol )
    if self.hasSymbol[symbol] then return false end
    self.hasSymbol[symbol] = true

    table.insert( self.list, symbol )
    return true
end

--- Adds symbols from a list.
---@param symbols Symbol[]
function FirstSet:addFrom( symbols )
    for _, symbol in ipairs( symbols ) do
        self:add( symbol )
    end
end

return FirstSet
