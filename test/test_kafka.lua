--  resty -I../lib test_kafka.lua
local producer = require "resty.kafka.producer"

local producer_cfg = { producer_type = "async",
                            refresh_interval=30000,
                            -- keepalive_size = 200,
                            api_version = 2,
                            username = "test",
                            password = "test"
                        }
local broker_list = {{host = "172.24.185.82", port = 9092}}
local bp, err = producer:new(broker_list, producer_cfg)
if not bp then
    return nil, err
end


local msg = "0123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789"
msg = msg .. msg .. msg .. msg .. msg
print(#msg)
local c, e = 0, 0
while true do
    local ok, err = bp:send("t", "1", msg)
    if not ok then
        if err == "buffer overflow" then
            -- ngx.sleep(0.001)
        else
            ngx.log(ngx.ERR, err)
        end
        e = e + 1
    end
    c = c + 1
    if c %1 == 0 then
        ngx.sleep(0.001)
    end
    
end