require( "io" )

local Types = require( "grammar_parsing.grammar_types" )
local TokenType = Types.TokenType
local Token = require( "grammar_parsing.token" )

---@type table<string, TokenType>
local characterToType = {
    [":"] = TokenType.COLON,
    [";"] = TokenType.SEMICOLON,
    ["("] = TokenType.LPAREN,
    [")"] = TokenType.RPAREN,
    ["|"] = TokenType.ALTERNATION,
    ["?"] = TokenType.OPTIONAL,
    ["*"] = TokenType.ZERO_OR_MORE,
    ["+"] = TokenType.ONE_OR_MORE
}

---@class GrammarLexer
---@field text string
---@field origin string
---@field position integer
---@field line integer
---@field column integer
local GrammarLexer = {}
GrammarLexer.__index = GrammarLexer
GrammarLexer.__type = "GrammarLexer"

--- Creates a new instance of a GrammarLexer
---@param text string
---@return GrammarLexer
function GrammarLexer.new( text )
    local grammarLexer = setmetatable( {}, GrammarLexer )
    grammarLexer.text = text
    grammarLexer.position = 1
    grammarLexer.line = 1
    grammarLexer.column = 1

    return grammarLexer
end

--- Creates a new instance of a GrammarLexer from a string
---@param text string
---@param name string?
---@return GrammarLexer
function GrammarLexer.fromString( text, name )
    local grammarLexer = GrammarLexer.new( text )
    grammarLexer.origin = name or "unknown"

    return grammarLexer
end

--- Creates a new instance of a GrammarLexer from the contents of a file
---@param filepath string
---@return GrammarLexer
function GrammarLexer.fromFile( filepath )
    local file, errmsg = io.open( filepath, "r" )
    if not file then
        error( "Could not open " .. filepath .. " for reading: " .. errmsg )
    end

    local contents = file:read( "*a" )
    file:close()

    local grammarLexer = GrammarLexer.new( contents )
    grammarLexer.origin = filepath

    return grammarLexer
end

--- Advances the position and column
---@param amount integer?
function GrammarLexer:advance( amount )
    self.position = self.position + ( amount or 1 )
    self.column = self.column + ( amount or 1 )
end

--- Gets the next token in the stream
---@return Token
function GrammarLexer:getNextToken()
    if self.position > #self.text then
        return Token.new( "", TokenType.EOF, self.line, self.column )
    end

    local text = self.text:sub( self.position )

    local newlineStart, newlineEnd = text:find( "^[\r\n]+" )
    if newlineStart and newlineEnd then
        local newlineLength = ( newlineEnd - newlineStart ) + 1

        self.position = self.position + newlineLength
        self.line = self.line + newlineLength
        self.column = 1

        return self:getNextToken()
    end

    local whitespaceStart, whitespaceEnd = text:find( "^%s+" )
    if whitespaceStart and whitespaceEnd then
        local whitespaceLength = ( whitespaceEnd - whitespaceStart ) + 1
        self:advance( whitespaceLength )

        return self:getNextToken()
    end

    local character = text:match( "^[:;()|?*+]" )
    if character then
        self:advance()

        return Token.new( character, characterToType[character], self.line, self.column )
    end

    if text:find( "^skip" ) then
        self:advance( 4 )

        return Token.new( "skip", TokenType.SKIP, self.line, self.column )
    end

    local terminal = text:match( "^[A-Z][A-Z0-9_]*" )
    if terminal then
        local token = Token.new( terminal, TokenType.TERMINAL, self.line, self.column )
        self:advance( #terminal )

        return token
    end

    local nonTerminal = text:match( "^[a-z][a-zA-Z0-9_]*" )
    if nonTerminal then
        local token = Token.new( nonTerminal, TokenType.NON_TERMINAL, self.line, self.column )
        self:advance( #nonTerminal )

        return token
    end

    if text:find( "^->" ) then
        local token = Token.new( "->", TokenType.ARROW, self.line, self.column )
        self:advance( 2 )

        return token
    end

    if text:find( "^\"" ) then
        local offset = 2
        local hasFullString = false

        while offset <= #text do
            local character = text:sub( offset, offset )

            if character == "\\" then
                offset = offset + 1
            elseif character == "\"" then
                hasFullString = true
                break
            end

            offset = offset + 1
        end

        if not hasFullString then
            error( "Malformed string at line " .. self.line .. " column " .. self.column )
        end

        local token = Token.new( text:sub( 2, offset - 1 ), TokenType.STRING, self.line, self.column )
        self:advance( offset )

        return token
    end

    error( "Unexpected input at line " .. self.line .. " column " .. self.column )
end

return GrammarLexer
