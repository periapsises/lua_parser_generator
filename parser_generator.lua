local Log = require( "util.logging" )
local Ansi = require( "util.ansi" )
local ParserGenerator = require( "parser_generator.parser_generator" )
local CodeGenerator   = require( "parser_generator.code_generator" )

local NAME = "LuaParserGen"
local VERSION = "v0.0.1"

local function showHelp()
    Ansi.print( "{BrightGreen}" .. NAME .. " " .. VERSION .. "{Green} A parser generator for Lua, built on LR(1) principles." )
    print()
    Ansi.print( "{BrightBlue}USAGE:{Blue} " .. arg[-1] .. " " .. arg[0] .. " [options] <input-file>{Reset}" )
    print()
    Ansi.print( "ARGUMENTS: {BrightYellow}<input-file>{Reset} The path to the grammar definition file (.gmr) to be processed." )
    print()
    Ansi.print( "OPTIONS:" )
    Ansi.print( "    {BrightCyan}-o{Reset}, {BrightCyan}--output <file>{Reset} Specifies the path and filename for the generated Lua parser file." )
    Ansi.print( "                        If omitted, the output will be named after the input file (e.g. \"MyGrammar.gmr\" becomes \"MyGrammar.lua\")" )
    Ansi.print( "    {BrightCyan}-v{Reset}, {BrightCyan}--verbose{Reset}       Enables verbose logging, printing detailed steps of the generation process to the console." )
    Ansi.print( "    {BrightCyan}-h{Reset}, {BrightCyan}--help{Reset}          Prints this help message and exits." )
    Ansi.print( "    {BrightCyan}--version{Reset}           Prints the version number and exits." )
end

local inputFile
local outputPath

if #arg == 0 then
    return showHelp()
end

local position = 1
while arg[position] do
    local argument = arg[position]

    if argument == "-h" or argument == "--help" then
        return showHelp()
    elseif argument == "--version" then
        return print( NAME .. " " .. VERSION )
    elseif argument == "-o" or argument == "--output" then
        if outputPath then
            return Log.error( "Cannot specify an output path twice" )
        end

        outputPath = arg[position + 1]
        if not outputPath then
            return Log.error( "An output path must be specified after '" .. argument .. "'" )
        end

        position = position + 1
    elseif argument == "-v" or argument == "--verbose" then
        Log.verbose = true
    else
        if inputFile then
            return Log.error( "Extra argument '" .. argument .. "'" )
        end

        inputFile = argument
    end

    position = position + 1
end

if not inputFile then
    return Log.error( "The path to an input file must be specified" )
end

if not outputPath then
    local inputFileName = inputFile:match( "([^\\/]+)$" )
    if inputFileName:find( "%." ) then
        inputFileName = inputFileName:match( "([^.]+)" )
    end

    outputPath = inputFileName .. ".lua"
end

local parserGenerator = ParserGenerator.new( inputFile, outputPath )
parserGenerator:generate()

if Log.verbose then
    local function printProduction( production )
        local content = ( production.position == 0 and ". " or "" )
        for i, symbol in ipairs( production.rule.right ) do
            content = content .. symbol.name .. ( i == production.position and " . " or " " )
        end

        print( "    " .. production.rule.left.name .. " -> " .. content )
    end

    local function actionToString( action )
        if action.type == 1 then
            return "SHIFT(" .. action.state.id .. ")"
        elseif action.type == 2 then
            return "REDUCE(" .. action.production.rule.left.name .. ")"
        else
            return "ACCEPT"
        end
    end

    for i, state in ipairs( parserGenerator.stateManager.states ) do
        print( "State " .. i .. ":" )

        for _, production in ipairs( state.productions ) do
            printProduction( production )
        end

        print()

        for symbol, action in pairs( state.actions ) do
            print( "    " .. symbol.name .. " -> " .. actionToString( action ) )
        end

        print()
    end
end

Log.info( "Generating parser to '" .. outputPath .. "'..." )

local codeGenerator = CodeGenerator.new( parserGenerator )
local source        = codeGenerator:emit()

local outputFile = io.open( outputPath, "w" )
if not outputFile then
    return Log.error( "Could not open output file '" .. outputPath .. "' for writing" )
end

outputFile:write( source )
outputFile:close()

Ansi.print( "{BrightGreen}Done!{Reset} Parser written to '" .. outputPath .. "'" )
