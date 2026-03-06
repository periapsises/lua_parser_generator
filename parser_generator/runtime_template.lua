return [=[
local function lex( input )
    local tokens = {}
    local pos    = 1

    while pos <= #input do
        local matched = false

        for _, rule in ipairs( LEXER_RULES ) do
            local m = string.match( input, "^" .. rule.pattern, pos )
            if m then
                if not rule.skip then
                    table.insert( tokens, { token = rule.token, value = m } )
                end
                pos     = pos + #m
                matched = true
                break
            end
        end

        if not matched then
            error( "Unexpected character '"
                .. string.sub( input, pos, pos )
                .. "' at position " .. pos )
        end
    end

    table.insert( tokens, { token = "EOF", value = "" } )
    return tokens
end

local function parse( input )
    local tokens     = lex( input )
    local tokenIndex = 1
    local stateStack = { 1 }
    local nodeStack  = {}

    while true do
        local state  = stateStack[#stateStack]
        local token  = tokens[tokenIndex]
        local action = ACTION[state] and ACTION[state][token.token]

        if not action then
            error( "Unexpected token '" .. token.token
                .. "' (value: '" .. token.value
                .. "') in state " .. state )
        end

        if action.type == "shift" then
            table.insert( stateStack, action.state )
            table.insert( nodeStack, {
                type      = "token",
                tokenType = token.token,
                value     = token.value,
            } )
            tokenIndex = tokenIndex + 1

        elseif action.type == "reduce" then
            local children = {}
            for _ = 1, action.len do
                table.remove( stateStack )
                table.insert( children, 1, table.remove( nodeStack ) )
            end

            local topState  = stateStack[#stateStack]
            local gotoState = GOTO[topState] and GOTO[topState][action.lhs]

            if not gotoState then
                error( "No GOTO entry for state " .. topState
                    .. " and non-terminal '" .. action.lhs .. "'" )
            end

            table.insert( stateStack, gotoState )
            table.insert( nodeStack, {
                type     = "node",
                rule     = action.lhs,
                children = children,
            } )

        elseif action.type == "accept" then
            return nodeStack[1]
        end
    end
end

return { parse = parse, lex = lex }
]=]
