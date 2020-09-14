-- Copyright (C) Dejiang Zhu(doujiang24)

local kafka_request = require "resty.kafka.request"
local response = require "resty.kafka.response"


local to_int32 = response.to_int32
local setmetatable = setmetatable
local tcp = ngx.socket.tcp


local _M = {}
local mt = { __index = _M }


function _M.new(self, host, port, socket_config, username, password)
    return setmetatable({
        host = host,
        port = port,
        config = socket_config,
        username = username,
        password = password
    }, mt)
end

-- CorrelationId 0 clientid 为空
local SaslHandshake_api_v1 = "\x00\x00\x00\x11\x00\x11\x00\x01\x00\x00\x00\x00\x00\x00\x00\x05PLAIN"
local function sasl_plain_auth(self, sock, username, password)

    local correlation_id = 0
    -- SaslHandshake req 17
    local SaslHandshake = kafka_request.pack_saslhandshake(correlation_id, "", "PLAIN")
    local bytes, err = sock:send(SaslHandshake)
    if not bytes then
        return nil, err, true
    end

    -- SaslHandshake resp
    local data, err = sock:receive(4)
    if not data then
        if err == "timeout" then
            sock:close()
            return nil, err
        end
        return nil, err, true
    end

    local len = to_int32(data)

    local data, err = sock:receive(len)
    if not data then
        if err == "timeout" then
            sock:close()
            return nil, err
        end
        return nil, err, true
    end
    local resp = response:new(data, 1)
    if resp.correlation_id ~= correlation_id then
        sock:close()
        return nil, "SaslHandshake failed:correlation_id wrong"
    end
    local errno = resp:int16()
    if errno ~= 0 then
        sock:close()
        return nil, "SaslHandshake return errno:" .. errno
    end

    -- SaslAuthenticate req 36
    correlation_id = 1
    local sasl_auth = kafka_request.pack_saslauth(correlation_id, "", username, password)
    local bytes, err = sock:send(sasl_auth)
    if not bytes then
        return nil, err
    end
    -- SaslAuthenticate resp 
    local data, err = sock:receive(4)
    if not data then
        if err == "timeout" then
            sock:close()
            return nil, err
        end
        return nil, err
    end

    local len = to_int32(data)

    local data, err = sock:receive(len)
    if not data then
        if err == "timeout" then
            sock:close()
            return nil, err
        end
        return nil, err
    end
    local resp = response:new(data, 1)
    if resp.correlation_id ~= correlation_id then
        sock:close()
        return nil, "SaslHandshake failed:correlation_id wrong"
    end
    local errno = resp:int16()
    if errno ~= 0 then
        sock:close()
        return nil, "SaslHandshake return errno:" .. errno
    end
    return true
end

function _M.send_receive(self, request)
    local sock, err = tcp()
    if not sock then
        return nil, err, true
    end

    sock:settimeout(self.config.socket_timeout)

    local ok, err = sock:connect(self.host, self.port)
    if not ok then
        return nil, err, true
    end

    local cnt, err = sock:getreusedtimes()
    if 0 == cnt then
        if self.config.ssl then
            -- TODO: add reused_session for better performance of short-lived connections
            local _, err = sock:sslhandshake(false, self.host, self.config.ssl_verify)
            if err then
                return nil, "failed to do SSL handshake with " ..
                            self.host .. ":" .. tostring(self.port) .. ": " .. err, true
            end
        end

        if self.username and self.password then
            ok, err = sasl_plain_auth(self, sock, self.username, self.password)
            if not ok then
                return nil, err, true
            end
        end
    elseif err then
        return nil, err
    end

    local bytes, err = sock:send(request:package())
    if not bytes then
        return nil, err, true
    end

    local data, err = sock:receive(4)
    if not data then
        if err == "timeout" then
            sock:close()
            return nil, err
        end
        return nil, err, true
    end

    local len = to_int32(data)

    local data, err = sock:receive(len)
    if not data then
        if err == "timeout" then
            sock:close()
            return nil, err
        end
        return nil, err, true
    end

    sock:setkeepalive(self.config.keepalive_timeout, self.config.keepalive_size)

    return response:new(data, request.api_version), nil, true
end


return _M
