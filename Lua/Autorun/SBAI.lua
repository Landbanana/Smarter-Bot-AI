if SERVER or Game.IsSingleplayer then
    SBAI = {}
    SBAI.Path = ...
    SBAI.Namespace = {"SBAI"}
    function SBAI.GetNamespace() return table.concat(SBAI.Namespace, ".") end

    dofile(SBAI.Path.."/Lua/SBAI/Server/ItemHelper.Lua")
    dofile(SBAI.Path.."/Lua/SBAI/Server/AiObjective.Lua")
end