local Terminal = require( "util.terminal" )

local colors = {
    Black = 30,
    Red = 31,
    Green = 32,
    Yellow = 33,
    Blue = 34,
    Magenta = 35,
    Cyan = 36,
    Gray = 37,
    DarkGray = 90,
    BrightRed = 91,
    BrightGreen = 92,
    BrightYellow = 93,
    BrightBlue = 94,
    BrightMagenta = 95,
    BrightCyan = 96,
    White = 97,
    Reset = 0
}

local Ansi = {}

local function formatColor( color )
    if not colors[color] then
        return ""
    end

    return "\27[" .. colors[color] .. "m"
end

local function stripColor()
    return ""
end

---@param text string
function Ansi.format( text )
    local formatter = Terminal.supportsColor() and formatColor or stripColor
    local result = string.gsub( text, "{([^}]+)}", formatter )

    return result
end

---@param text string
function Ansi.print( text )
    print( Ansi.format( text ) )
end

---@param text string
---@param ... any
function Ansi.printf( text, ... )
    local formatted = string.format( text, ... )
    print( Ansi.format( formatted ) )
end

return Ansi
