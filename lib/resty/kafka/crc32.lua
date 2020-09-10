local ffi = require("ffi")
local bit = require("bit")

local bxor = bit.bxor
local rshift = bit.rshift
local band = bit.band
local cast = ffi.cast
-- local crc32_short = ngx.crc32_short

local _M = {}

local crc32_table16 = ffi.new("const uint32_t[16]", {
    0x00000000, 0x1db71064, 0x3b6e20c8, 0x26d930ac,
    0x76dc4190, 0x6b6b51f4, 0x4db26158, 0x5005713c,
    0xedb88320, 0xf00f9344, 0xd6d6a3e8, 0xcb61b38c,
    0x9b64c2b0, 0x86d3d2d4, 0xa00ae278, 0xbdbdf21c
})

local function crc32_short_init()
    return 0xffffffff
end

_M.init = crc32_short_init

local function crc32_short_update(part, crc)
    local c, m
    crc = band(crc, 0xffffffff)
    -- crc = cast("uint32_t", crc or 0xffffffff)
    for i = 1, #part do
        c = part:byte(i)
        m = band(bxor(crc, band(c, 0xf)), 0xf)
        crc = bxor(crc32_table16[m], rshift(crc, 4))
        m = band(bxor(crc, rshift(c, 4)), 0xf)
        crc = bxor(crc32_table16[m], rshift(crc, 4))
    end
    return crc
end

_M.update = crc32_short_update

local function crc32_short_finish(crc)
    crc = cast("uint32_t", crc)
    return tonumber(bxor(crc, 0xffffffff))
end

_M.finish = crc32_short_finish

local function pure_crc32_short(str)
    return crc32_short_finish(crc32_short_update(str, crc32_short_init()))
end

function _M.hash(str)
    return crc32_short_finish(crc32_short_update(str, crc32_short_init()))
end

function _M.hash_talbe(str, crc)
    local ncrc = crc or crc32_short_init()
    if type(str) == "string" then
        ncrc = crc32_short_update(str, ncrc)
    elseif type(str) == "table" then
        for _, k in ipairs(str) do
            ncrc = _M.hash_talbe(k, ncrc)
        end
    else
        error("invalid str")
    end

    if not crc then
        return crc32_short_finish(ncrc)
    end

    return ncrc
end

local function call(self, str)
    if type(str) == "string" then
        return crc32_short_finish(crc32_short_update(str, crc32_short_init()))
    elseif type(str) == "table" then
        return _M.hash_talbe(str)
    else
        error("invalid array")
    end
end

function _M.tb_len(tb)
    local len = 0
    for _, k in ipairs(tb) do
        len = len + ((type(k) == "table") and _M.tb_len(k) or #k)
    end
    return len
end

setmetatable(_M, {__call = call})
return _M
