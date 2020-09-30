local crc = require("crc32")
math.randomseed(os.clock())
local char = string.char
local random = math.random
local function rand()
        local a,b = {}
        for i = 1, 16 do
                b = math.ceil(random(255))
            a[i] = char(b)
        end

        return table.concat(a)
end
local a = tostring(rand())
local b = tostring(rand())..tostring(rand())..tostring(rand())..tostring(rand())
local c = tostring(rand())..tostring(rand())..tostring(rand())..tostring(rand())
local d = tostring(rand())..tostring(rand())..tostring(rand())..tostring(rand())
local e = tostring(rand())..tostring(rand())..tostring(rand())..tostring(rand())
local f = tostring(rand())..tostring(rand())..tostring(rand())..tostring(rand())
local g = tostring(rand())..tostring(rand())..tostring(rand())..tostring(rand())
a = a .. b..c..d..e..f..g
--a = a .. b..c..d..e..f..g
--a = a .. b..c..d..e..f..g
-- a = "0123456789"
-- a = a .. tostring(rand())
-- a = a .. tostring(rand()) .. rand()
print(a)
print("str len:", #a)

local crcn = ngx.crc32_short
local crcnl = ngx.crc32_long
local crclg = crc.long
local crcst = crc.short
if crclg(a) ~= crcn(a) then
        print("nb")
elseif crcst(a) ~= crcnl(a) then
        print("nb 1")
end


local cnt = 100000

local s = os.clock()
for i = 1, cnt do
        crcnl(a)
end
local e = os.clock()
print("ngx long:", e  -s)

local s = os.clock()
for i = 1, cnt do
        crcn(a)
end
local e = os.clock()
print("ngx short:", e  -s)

local s = os.clock()
for i = 1, cnt do
        crclg(a)
end
local e = os.clock()
print("long:", e  -s)

local s = os.clock()
for i = 1, cnt do
        crcst(a)
end
local e = os.clock()
print("short:", e  -s)

--[[
long 总是比short 性能好一倍
str越长, long越接近 ngx long
3字节以内 long比ngx.crc32_long更好, 4为差距最大的情况

str len:3
ngx long:0.000522
ngx short:0.000879
long:0.00021
short:0.000283

str len:4
ngx long:0.000622
ngx short:0.001218
long:0.003295
short:0.005023

str len:400
ngx long:0.124463
ngx short:0.25242
long:0.143659
short:0.283386
]]


