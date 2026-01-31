local _ENV = require("SBAI.Base.env") --if CLIENT then return end

--

GameMain = LuaUserData.CreateStatic("Barotrauma.GameMain")

-- LuaUserData.RegisterType("MoonSharp.Interpreter.Script")
-- LuaUserData.RegisterType("MoonSharp.Interpreter.ScriptOptions")
-- print(GameMain.LuaCs.Lua.Options.TailCallOptimizationThreshold)


local betterRegisterType = select(2,  debug.getupvalue(_ENV.OLD.LuaUserData.RegisterType, 4)) ---@type std.RawGet<Barotrauma.LuaUserData, "RegisterType">
local betterCreateStatic = select(2, debug.getupvalue(_ENV.OLD.LuaUserData.CreateStatic, 1))

betterRegisterType("Barotrauma.LuaCsSetup")
betterRegisterType("MoonSharp.Interpreter.Script")


local LuaCsSetup = GameMain.LuaCs


local IUDD_script = betterRegisterType("MoonSharp.Interpreter.Script")

local Script = LuaCsSetup.Lua

print(Script)


Script = _ENV.OLD.LuaUserData.CreateUserDataFromDescriptor(Script, IUDD_script)


print(Script.ScrjptOptions)


--betterRegisterType("MoonSharp.Interpreter.UserData")


---@class MoonSharp.Interpreter.UserData: MoonSharp.Interpreter.RefIdObject
local UserData =select(2, debug.getupvalue(betterRegisterType, 2))

-- for kalue(_ENV.OLD.LuaUserData.CreateStatic, 4))
-- select(2, debug.getup, v in next,  do
--     print(k)
-- end


---@export globa
---@class SBAI
SBAI = {}

SBAI.Acronym = Acronym --[=[@readonly]=] ---@public
SBAI.ConfigPath = ToolBox.CleanUpPath(table.concat({Game.SaveFolder,  "ModConfigs",  Stringtools.prefixAcronym("json")}, "/")) --[=[@readonly]=] --[=[@as string]=] ---@public
SBAI.ModPath = ModPath --[=[@readonly]=] ---@public

do
    local contentPackage = GameMain.LuaCs.GetPackage(ContentPackageId.Parse("3343911734"))

    SBAI.ContentPackage = contentPackage
    SBAI.Name =  contentPackage.Name --[=[@readonly]=] --[=[@as string]=] ---@public
    SBAI.Version = contentPackage.ModVersion:lower() --[=[@readonly]=] --[=[@as string]=] ---@public
end

--[[ ROUND SUMMARY ADD SEPARATORS
MEDICALCLINICUI.EnsureTextDoesntOverflow
STEAM UI UTIL
INSTALLEDTAB.CREATESIDEBARS
EventEditorScreen CHANGE TYPE]]



--- =============================================
--- ALL ENV STUFF IS SAFE TO USE AFTER THIS POINT
--- (or it should be, anyway)
--- =============================================

-- do
--     local InitSem = Types.Semaphore(0)

--     ISemR = Functools.partial1(InitSem.release, InitSem) ---@as fun()
--     ISemA = Functools.partial1(InitSem.acquire, InitSem)
-- end

--- Set networking if applicable

if Net ~= false then
    Net = requireSpecific("SBAI.Shared.net")
end
Config = requireSpecific("SBAI.Shared.config")

SBAI.Config = Config

Control = requireSpecific("SBAI.Shared.control")



local debugtools = require("SBAI.Base.debugtools")
local net = require("SBAI.Client.net")


do
    local start = Control.start
    local stop = Control.stop

    function Config.onUpdate()
        stop()
        return start()
    end
end


if SERVER or Game.IsSingleplayer then
    Config.load()
    Config.save()
end

if SERVER then
    local _onUpdate = Config.onUpdate
    local sendUpdate = Config.sendUpdate

    function Config.onUpdate()
        _onUpdate()
        return sendUpdate()
    end
end

if Net ~= false then
    Net.start()
    Net.init()
end


-- do
--     local print, ipairs, Wait = print, ipairs, Timer.Wait
--     local PerformanceCounter = LuaUserData.CreateStatic("Barotrauma.LuaCsPerformanceCounter").__new() ---@type Barotrauma.LuaCsPerformanceCounter

--     PerformanceCounter.EnablePerformanceCounter = true

--     local function yTail(n, out, i)
--         n = n or 0
--         if n % 1000 == 0 then i = (i or 0) + 1; out[i] = PerformanceCounter.MemoryUsage end
--         if n > 0 then return yTail(n - 1, out, i) end
--         print("DONE")
--     end

--     local function nTail(n, out, i)
--         n = n or 0
--         if n % 1000 == 0 then i = (i or 0) + 1; out[i] = PerformanceCounter.MemoryUsage end
--         if n > 0 then return nTail(n - 1, out, i) end
--         print("DONE")
--     end


--     function OLD.ENV._G.foos(n, doTailCall, i)
--         local out = {}


--         if doTailCall then
--             yTail(100000, out, 1)
--         else
--             nTail(100000, out, 1)
--         end
--     end
-- end

OLD.ENV._G.SBAI = SBAI
return SBAI