SBAI = {}

SBAI.Path = ...

if (Game.IsMultiplayer and SERVER) or not Game.IsMultiplayer then
    dofile(SBAI.Path.."/Lua/SBAI/Server/ItemHelper.Lua")
    dofile(SBAI.Path.."/Lua/SBAI/Server/AiObjective.Lua")
end