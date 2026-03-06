local currentIDCounter = 0
local function getNewID()
    currentIDCounter = currentIDCounter + 1
    return currentIDCounter
end

local Types = {}

---@enum TokenType
Types.TokenType = {
    EOF          = getNewID(),
    NEWLINE      = getNewID(),
    COLON        = getNewID(),
    SEMICOLON    = getNewID(),
    TERMINAL     = getNewID(),
    NON_TERMINAL = getNewID(),
    LPAREN       = getNewID(),
    RPAREN       = getNewID(),
    ALTERNATION  = getNewID(),
    OPTIONAL     = getNewID(),
    ZERO_OR_MORE = getNewID(),
    ONE_OR_MORE  = getNewID(),
    STRING       = getNewID(),
    ARROW        = getNewID(),
    SKIP         = getNewID(),
}

---@enum NodeType
Types.NodeType = {
    GRAMMAR      = getNewID(),
    SYMBOL       = getNewID(),
    LEXER_RULE   = getNewID(),
    PARSER_RULE  = getNewID(),
    SEQUENCE     = getNewID(),
    ALTERNATION  = getNewID(),
    OPTIONAL     = getNewID(),
    ONE_OR_MORE  = getNewID(),
    ZERO_OR_MORE = getNewID(),
}

local typeToStringLookup = {}

for name, type in pairs( Types.TokenType ) do
    typeToStringLookup[type] = name
end

for name, type in pairs( Types.NodeType ) do
    typeToStringLookup[type] = name
end

function Types.typeToString( type )
    return typeToStringLookup[type]
end

return Types
