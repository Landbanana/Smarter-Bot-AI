---@class ENV: global
local ENV = {} do
    for k, v in next, _ENV do
        ENV[k] = v
    end

    ENV.ENV = ENV

    ENV.OLD = {
        ENV=_ENV,
        require=require,
        Hook=Hook --[=[@as Barotrauma.LuaCsHook]=],
        LuaUserData=LuaUserData ---@as Barotrauma.LuaUserData
    }
    ---@type table<string, {n:integer, [integer]:fun(v:any)}>
    local callbacks = {}

    ---@param k string
    ---@param f fun(v:any)
    function ENV.onGlobalLoad(k, f)
        local entry = callbacks[k]

        if entry == nil then
            entry = {f, n=1}
            callbacks[k] = entry
        else
            local n = entry.n + 1

            entry.n = n
            entry[n] = f
        end
    end

    local rawset = rawset

    setmetatable(ENV, {
        ---@param t ENV
        ---@param k string
        ---@param v any
        __newindex=function(t, k, v)
            local entry = callbacks[k]

            if entry ~= nil then
                for i=1,entry.n do
                    entry[i](v)
                end
                callbacks[k] = nil
            end
            return rawset(t, k, v)
        end
    })
end

local _ENV = ENV

Acronym = "SBAI" ---@readonly
ModPath = (...) ---@type string ---@readonly

--- disable networking for Singleplayer

Net = not Game.IsSingleplayer ---@type Net|boolean

-- modified "require" function to auto include new _ENV

require_raw = require
do
    local require_raw = require_raw

    ---@param modname string
    ---@return any
    function require(modname)
        return require_raw(modname, ENV) ---@diagnostic disable-line: redundant-parameter
    end
end

do
    local _requireAll --[=[@[lsp_optimization("delayed_definition")]]=] do
        local _tryRequire --[=[@[lsp_optimization("delayed_definition")]]=] do
            local ModPath = ModPath

            local CleanUpPath = ToolBox.CleanUpPath ---@as fun(path:string):(string)
            local CleanUpPathCrossPlatform = ToolBox.CleanUpPathCrossPlatform ---@as fun(path:string, correctFilenameCase:boolean, directory:string):(string)
            local DirectoryExists = File.DirectoryExists ---@as fun(path:string):(boolean)
            local Exists = File.Exists ---@as fun(path:string):(boolean)
            local require = require

            ---@param modnameBase string
            ---@param dirBase string
            ---@param fileStr string
            ---@param gameType "Shared"|"Server"|"Client"
            ---@return any
            _tryRequire = function(modnameBase, dirBase, fileStr, gameType)
                local modname = modnameBase:format(gameType, "%s")
                local dirStr = dirBase:format(gameType)

                if DirectoryExists(CleanUpPath(("%s/%s"):format(ModPath, dirStr))) then
                    local newFileStr = CleanUpPathCrossPlatform(("%s/%s"):format(dirStr, fileStr), true, ModPath)

                    if Exists(CleanUpPath(("%s/%s"):format(ModPath, newFileStr))) then
                        return require(modname:format(newFileStr:match("([%w_]+)%.lua$")))
                    end
                end
            end
        end

        ---@param modname string
        ---@return string, string, string
        local function _pre(modname)
            local modnameBase = (modname:gsub("%.Shared%.", ".%%s."))
            local dirBase, fileBase = ("Lua/%s.lua"):format((modnameBase:gsub("%.", "/"))):match("^(.-)/([^/]+%.lua)$")

            ---@cast dirBase -?
            ---@cast fileBase -?

            modnameBase = ("%s.%s"):format(modnameBase:match("^(.-)%.[^%.]+$"), "%s")

            return modnameBase, dirBase, fileBase
        end

        if Net == false then
            ---@param modname string
            ---@return any
            ---@nodiscard
            _requireAll = function(modname)
                local modnameBase, dirBase, fileBase = _pre(modname)
                local out = _tryRequire(modnameBase, dirBase, fileBase, "Shared")

                out = _tryRequire(modnameBase, dirBase, fileBase, "Server") or out
                out = _tryRequire(modnameBase, dirBase, fileBase, "Client") or out
                return out
            end
        elseif SERVER then
            ---@param modname string
            ---@return any
            ---@nodiscard
            _requireAll = function(modname)
                local modnameBase, dirBase, fileBase = _pre(modname)
                local out = _tryRequire(modnameBase, dirBase, fileBase, "Shared")

                out = _tryRequire(modnameBase, dirBase, fileBase, "Server") or out
                return out
            end
        else
            ---@param modname string
            ---@return any
            ---@nodiscard
            _requireAll = function(modname)
                local modnameBase, dirBase, fileBase = _pre(modname)
                local out = _tryRequire(modnameBase, dirBase, fileBase, "Shared")

                out = _tryRequire(modnameBase, dirBase, fileBase, "Client") or out
                return out
            end
        end
    end

    requireSpecific = _requireAll

    -- local cache = {}

    -- ---@param modname string
    -- ---@return any
    -- function requireSpecific(modname)
    --     local out = cache[modname]

    --     if out == nil then
    --         out = _requireAll(modname)
    --         cache[modname] = out
    --     end
    --     return out
    -- end
end

Types = require("SBAI.Base.types")

Errortools = require("SBAI.Base.errortools") do
    ferror = Errortools.ferror
    raise = Errortools.raise
end

Mathtools = require("SBAI.Base.mathtools")

Stringtools = require("SBAI.Base.stringtools")

do
    LuaUserData = Types.LFBChanges.LuaUserData
    Hook = Types.LFBChanges.Hook
end

Debugtools = require("SBAI.Base.debugtools")

Itertools = require("SBAI.Base.itertools")

Functools = require("SBAI.Base.functools")

Tabletools = require("SBAI.Base.tabletools") do
    concat = table.concat
end

Cotools = require("SBAI.Base.cotools") do
    yield = coroutine.yield
    wrap = coroutine.wrap
end

return ENV