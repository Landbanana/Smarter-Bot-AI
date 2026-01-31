---@class Errortools
local Errortools = {}

do
    local error = error

    ---@param s string
    ---@param level? integer
    function Errortools.ferror(s, level, ...)
        return error(s:format(...), (level or 1) + 1)
    end
end

do
    local _raise --[=[@[lsp_optimization("delayed_definition")]]=] do
        local error = error

        ---@param success boolean
        ---@param err any
        ---@param ... any
        ---@return ...
        _raise = function(success, err, ...)
            if success then
                return err, ...
            else
                return error(err, 4)
            end
        end
    end

    local pcall = pcall

    ---@generic F
    ---@param f F
    ---@param ... Parameters<F>...
    ---@return ReturnType<F>...
    function Errortools.raise(f, ...)
        return _raise(pcall(f, ...))
    end
end

do
    local Acronym = Acronym
    local Error = ServerLogMessageType.Error
    local Red = Color.Red
    local template = ("[%s LUA ERROR] (%s) %s"):format(SERVER and "SV" or "CL", "%s", "%s")

    local Log = Logger.Log
    local select = select

    ---@param namespace? string
    ---@param msg string
    ---@param ... any
    function Errortools.logError(namespace, msg, ...)
        return Log(template:format(namespace or Acronym, (select("#", ...) > 0) and msg:format(...) or msg), Red, Error)
    end
end

do
    local Acronym = Acronym
    local Error = ServerLogMessageType.Error
    local template = ("[%s LUA WARN] (%s) %s"):format(SERVER and "SV" or "CL", "%s", "%s")
    local Yellow = Color.Yellow

    local Log = Logger.Log
    local select = select

    ---@param namespace? string
    ---@param msg string
    ---@param ... any
    function Errortools.logWarn(namespace, msg, ...)
        return Log(template:format(namespace or Acronym, (select("#", ...) > 0) and msg:format(...) or msg), Yellow, Error)
    end
end

return Errortools