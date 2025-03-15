if (Game.IsMultiplayer and SERVER) or not Game.IsMultiplayer then
    SBAI = {}
    SBAI.Path = ...
    dofile(SBAI.Path.."/Lua/SBAI/Server/ItemHelper.Lua")
    dofile(SBAI.Path.."/Lua/SBAI/Server/AiObjective.Lua")
end