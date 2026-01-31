---@class (partial) Net
---@field package registry {[Net.MsgType]:fun(msg:Barotrauma.Networking.IReadMessage, sender?:Barotrauma.Networking.Client)}
local Net = {registry={}}

---@package
Net.MsgType = {
    "INIT",
    "DEAD",
    "CONFIG_UPDATE",
    "CONFIG_REQUEST"
} ---@type Net.MsgType[]

do
    ---@package
    ---@type {[Net.MsgType]:integer}
    Net.TypeMsg = {} do
        local TypeMsg = Net.TypeMsg
        local MsgType = Net.MsgType
        local n = #MsgType

        for i=1,n do
            TypeMsg[MsgType[i]] = i
        end
    end
end


---@param msgType Net.MsgType
---@param f fun(msg:Barotrauma.Networking.IReadMessage, client?:Barotrauma.Networking.Client)
function Net.register(msgType, f)
    Net.registry[msgType] = f
end

do
    local registry = Net.registry
    local MsgType = Net.MsgType

    Net.start = Functools.partial2(Networking.Receive, Acronym,
    ---@param msg Barotrauma.Networking.IReadMessage
    ---@param client? Barotrauma.Networking.Client
    function(msg, client)
        local msgType = MsgType[msg.ReadByte()]

        print((">> %s"):format(msgType))
        return registry[msgType](msg, client)
    end) ---@type fun() ---@public
end

---@public
---@type fun()
Net.stop = Functools.partial1(Networking.Remove, Acronym)

do
    local dataTypeMatch --[=[@[lsp_optimization("delayed_definition")]]=] do
        local serialize = json.serialize

        dataTypeMatch = (Types.Match() --[=[@as Match<boolean|number|string|table|nil,fun(msg:Barotrauma.Networking.IWriteMessage, data:any)>]=])
            :case("boolean", function(msg, data) return msg.WriteBoolean(data) end)
            :case("number", function(msg, data) return msg.WriteDouble(data) end)
            :case("string", function(msg, data) return msg.WriteString(data) end)
            :case("table", function(msg, data) return msg.WriteString(serialize(data)) end)
            :case("nil", Functools.devnull)
    end

    local Acronym = Acronym
    local TypeMsg = Net.TypeMsg

    local select = select
    local Start = Networking.Start
    local type = type

    ---@public
    ---@param msgType Net.MsgType
    ---@param ... (boolean|number|string|table|nil)
    function Net.write(msgType, ...)
        print(("%s >>"):format(msgType))

        local msg = Start(Acronym)
        local n = select("#", ...)

        msg.WriteByte(TypeMsg[msgType])

        for i=1,n do
            local data = (select(i, ...))

            dataTypeMatch:eval(type(data))(msg, data)
        end
        return msg
    end
end

do
    local write = Net.write

    ---@public
    ---@param msgType Net.MsgType
    ---@param client? Barotrauma.Networking.Client
    ---@param ... (boolean|number|string|table|nil)
    function Net.writeSend(msgType, client, ...)
        return Net.send(write(msgType, ...), client)
    end
end

return Net