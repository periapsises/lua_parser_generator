local Ansi = require( "util.ansi" )

local Log = {}
Log.verbose = false

function Log.info( message, ... )
    if not Log.verbose then return end

    Ansi.printf( "{BrightCyan}INFO:{Reset} " .. message, ... )
end

function Log.warn( message, ... )
    if not Log.verbose then return end

    Ansi.printf( "{BrightYellow}WARN:{Reset} " .. message, ... )
end

function Log.error( message, ... )
    Ansi.printf( "{BrightRed}ERROR:{Reset} " .. message, ... )
end

return Log
