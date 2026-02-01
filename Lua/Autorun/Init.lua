local _ENV = require("SBAI.Base.env") --if CLIENT then return end


GameMain = LuaUserData.CreateStatic("Barotrauma.GameMain")

---@export global
---@class SBAI
SBAI = {}

SBAI.Acronym = Acronym --[=[@readonly]=] ---@public
SBAI.ConfigPath = ToolBox.CleanUpPath(table.concat({Game.SaveFolder,  "ModConfigs",  Stringtools.prefixAcronym("json")}, "/")) --[=[@readonly]=] --[=[@as string]=] ---@public
SBAI.ModPath = ModPath --[=[@readonly]=] ---@public

do
    local Acronym = Acronym
    local contentPackage = nil ---@type Barotrauma.ContentPackage?

    for v in Game.GetEnabledContentPackages() --[[@as fun():(Barotrauma.ContentPackage)]] do
        if v.NameMatches(Acronym) then
            contentPackage = v
            break
        end
    end
    if contentPackage == nil then return error("Unable to find SBAI ContentPackage") end
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

OLD.ENV.SBAI = SBAI
return SBAI