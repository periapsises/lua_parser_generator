---@class FollowSet
---@field list Symbol[]
---@field hasSymbol table<Symbol, boolean>
local FollowSet = {}
FollowSet.__index = FollowSet
FollowSet.__type = "FollowSet"

--- Creates an instance of a FollowSet.
---@return FollowSet
function FollowSet.new()
    local followSet = setmetatable( {}, FollowSet )
    followSet.list = {}
    followSet.hasSymbol = {}

    return followSet
end

--- Adds a symbol to the set.
--- Returns wether or not the symbol was added to the list.
---@param symbol Symbol
---@return boolean
function FollowSet:add( symbol )
    if self.hasSymbol[symbol] then return false end
    self.hasSymbol[symbol] = true

    table.insert( self.list, symbol )
    return true
end

--- Adds symbols from a list.
---@param symbols Symbol[]
function FollowSet:addFrom( symbols )
    for _, symbol in ipairs( symbols ) do
        self:add( symbol )
    end
end

return FollowSet
