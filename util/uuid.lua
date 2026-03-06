local ffi = require( "ffi" )
local bit = require( "bit" )

local os = ffi.os

ffi.cdef [[
    typedef unsigned char uuid_bytes_t[16];

    void uuid_generate(uuid_bytes_t out);

    typedef struct {
        unsigned int   Data1;
        unsigned short Data2;
        unsigned short Data3;
        unsigned char  Data4[8];
    } GUID;

    int UuidCreate(GUID* guid);

    typedef struct SHA256state_st SHA256_CTX;

    int SHA256_Init(SHA256_CTX* context);
    int SHA256_Update(SHA256_CTX* context, const void* data, size_t length);
    int SHA256_Final(unsigned char* md, SHA256_CTX* context);

    unsigned long ERR_get_error();
    void ERR_error_string_n(unsigned long error, char* buffer, size_t length);

    void* malloc(size_t size);
    void* memcpy(void* destination, const void* source, size_t size);
    void free(void* pointer);

    int strcmp(const char* string1, const char* string2);
]]

---@class GUID
---@field Data1 number
---@field Data2 number
---@field Data3 number
---@field Data4 number[]

local uuidLib
local rpcLib
local sslLib

local function loadLibraries()
    if os == "Windows" then
        rpcLib = ffi.load("Rpcrt4")
    else
        for _, libName in ipairs{ "uuid", "libuuid.so.1", "libuuid.dylib" } do
            local ok, lib = pcall( ffi.load, libName )
            if ok then
                uuidLib = lib
                break
            end
        end

        if not uuidLib then
            print( "Warning: Could not load libuuid. UUID.new() might fail." )
        end
    end

    for _, libName in ipairs{ "ssl", "libcrypto-3-x64", "libssl.so", "libssl.dylib", "crypto", "libcrypto.so", "libcrypto.dylib" } do
        local ok, lib = pcall( ffi.load, libName )
        if ok then
            sslLib = lib
            break
        end
    end

    if not sslLib then
        print( "Warning: Could not load OpenSSL (libssl/libcrypto). UUID.merge() will fail." )
    end
end

loadLibraries()

local band, rshift, bor = bit.band, bit.rshift, bit.bor

local function formatUUIDString( bytes )
    return string.format( "%02x%02x%02x%02x-%02x%02x-%02x%02x-%02x%02x-%02x%02x%02x%02x%02x%02x",
        bytes[0], bytes[1], bytes[2], bytes[3], bytes[4], bytes[5], bytes[6], bytes[7],
        bytes[8], bytes[9], bytes[10], bytes[11], bytes[12], bytes[13], bytes[14], bytes[15] )
end

local UUID = {}

--- Creates a new UUID
---@return string
function UUID.new()
    local bytes = ffi.new( "uuid_bytes_t" )

    if os == "Windows" then
        if not rpcLib then error( "Rcprt4.dll is not loaded." ) end

        local guid = ffi.new( "GUID" ) --[[@as GUID]]
        local result = rpcLib.UuidCreate( guid )

        if result ~= 0 then error( "UuidCreate failed with code: " .. result ) end

        local data1 = guid.Data1
        local data2 = guid.Data2
        local data3 = guid.Data3

        bytes[0] = band( rshift( data1, 24 ), 255 )
        bytes[1] = band( rshift( data1, 16 ), 255 )
        bytes[2] = band( rshift( data1, 8 ), 255 )
        bytes[3] = band( data1, 255 )
        bytes[4] = band( rshift( data2 , 8 ), 255 )
        bytes[5] = band( data2, 255 )
        bytes[6] = band( rshift( data3 , 8 ), 255 )
        bytes[7] = band( data3, 255 )

        for i = 0, 7 do
            bytes[8 + i] = guid.Data4[i]
        end
    else
        if not uuidLib then error( "libuuid is not loaded." ) end

        uuidLib.uuid_generate( bytes )
    end

    return formatUUIDString( bytes )
end

local function sha256( data )
    if not sslLib then error( "OpenSSL library is not loaded." ) end

    local contextPointer = ffi.C.malloc( 256 )
    if contextPointer == nil then error( "Failed to allocate memory for SHA256_CTX." ) end

    contextPointer = ffi.cast( "SHA256_CTX*", contextPointer )

    local result = sslLib.SHA256_Init( contextPointer )
    if result ~= 1 then
        ffi.C.free( contextPointer )
        error( "SHA256_Init failed." )
    end

    result = sslLib.SHA256_Update( contextPointer, data, #data )
    if result ~= 1 then
        ffi.C.free( contextPointer )
        error( "SHA256_Update failed." )
    end

    local hashOutput = ffi.new( "unsigned char[?]", 32 )
    result = sslLib.SHA256_Final( hashOutput, contextPointer )
    ffi.C.free( contextPointer )

    if result ~= 1 then error( "SHA256_Final failed." ) end

    return hashOutput
end

--- Merges existing UUIDs together into a new one
---@param uuids string[]
---@return string
function UUID.merge( uuids )
    if not uuids then error( "Missing argument to UUID.merge: uuids " ) end
    if type( uuids ) ~= "table" then error( "Invalid argument to UUID.merge: uuids - Expected table but got " .. type( uuids ) ) end
    if #uuids == 0 then error( "Invalid argument to UUID.merge: uuids table cannot be empty" ) end

    if not sslLib then error( "OpenSSL library is not loaded." ) end

    local sortedUUIDs = {}
    for i = 1, #uuids do sortedUUIDs[i] = uuids[i] end

    table.sort( sortedUUIDs )

    local canonicalString = table.concat( sortedUUIDs, "\0" )
    local hashBytesData = sha256( canonicalString )

    local uuidBytes = ffi.new( "uuid_bytes_t" )
    ffi.copy( uuidBytes, hashBytesData, 16 )

    uuidBytes[6] = bor( band( uuidBytes[6], 0x0f ), 0x50 )
    uuidBytes[8] = bor( band( uuidBytes[8], 0x3f ), 0x80 )

    return formatUUIDString( uuidBytes )
end

return UUID
