if SERVER or Game.IsSingleplayer then
    SBAI = {}
    SBAI.Path = ...
    SBAI.Namespace = {"SBAI"}
    function SBAI.GetNamespace() return table.concat(SBAI.Namespace, ".") end

    dofile(SBAI.Path.."/Lua/SBAI/Util.Lua")
    dofile(SBAI.Path.."/Lua/SBAI/Server/ItemGroup.Lua")
    dofile(SBAI.Path.."/Lua/SBAI/Server/AiObjective.Lua")
end