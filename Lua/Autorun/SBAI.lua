if SERVER or Game.IsSingleplayer then
    SBAI = {}
    SBAI.Path = ...
    dofile(SBAI.Path.."/Lua/SBAI/Server/ItemHelper.Lua")
    dofile(SBAI.Path.."/Lua/SBAI/Server/AiObjective.Lua")
end