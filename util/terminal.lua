local ffi = require( "ffi" )
local bit = require( "bit" )

local Terminal = {}
local _color_support_cache = nil

ffi.cdef [[
    // POSIX (libc)
    int isatty(int fd);

    // Windows (kernel32.dll & msvcrt.dll)
    typedef void* HANDLE;
    typedef unsigned int DWORD;

    // From kernel32.dll
    HANDLE GetStdHandle(DWORD nStdHandle);
    int GetConsoleMode(HANDLE hConsoleHandle, DWORD* lpMode);
    int SetConsoleMode(HANDLE hConsoleHandle, DWORD dwMode);

    // From msvcrt.dll
    int _isatty(int fd);
    int _fileno(void* stream);
]]

local WIN_CONST = {
    STD_OUTPUT_HANDLE = -11,
    ENABLE_VIRTUAL_TERMINAL_PROCESSING = 0x0004
}

local function isTerminal()
    local ok, lib

    if ffi.os == "Windows" then
        ok, lib = pcall(ffi.load, "msvcrt")
        if ok then
            return lib._isatty(1) ~= 0
        end
    else
        local libc_names = {"c", "libc.so.6", "libc.dylib"}
        for _, name in ipairs(libc_names) do
            ok, lib = pcall(ffi.load, name)
            if ok and lib.isatty then
                return lib.isatty(1) ~= 0
            end
        end
    end

    return false
end

local function checkColorSupport()
    if not isTerminal() then
        return false
    end

    if ffi.os == "Windows" then
        local ok, kernel32 = pcall(ffi.load, "kernel32")
        if not ok then
            return false
        end

        local stdout = kernel32.GetStdHandle(WIN_CONST.STD_OUTPUT_HANDLE)
        local mode = ffi.new("DWORD[1]")
        if kernel32.GetConsoleMode(stdout, mode) == 0 then
            return false
        end

        local newMode = bit.bor(mode[0], WIN_CONST.ENABLE_VIRTUAL_TERMINAL_PROCESSING)
        if kernel32.SetConsoleMode(stdout, newMode) == 0 then
            return false
        end

        return true
    else
        local term = os.getenv("TERM")
        if not term or term == "" or term == "dumb" then
            return false
        end

        return term
    end
end

function Terminal.supportsColor()
    if _color_support_cache then
        return _color_support_cache
    end

    _color_support_cache = checkColorSupport()
    return _color_support_cache
end

return Terminal
