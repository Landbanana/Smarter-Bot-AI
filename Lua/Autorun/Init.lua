if SERVER or Game.IsSingleplayer then
    require("SBAI.config")
    require("SBAI.Server.ItemGroup")
    require("SBAI.Server.Characters.AI.Objective.AIObjectiveCombat")
    require("SBAI.Server.Characters.AI.Objective.AIObjectiveContainItem")
    require("SBAI.Server.Characters.AI.Objective.AIObjectiveDeconstructItem")
    require("SBAI.Server.Characters.AI.Objective.AIObjectiveFightIntruders")
    require("SBAI.Server.Characters.AI.Objective.AIObjectiveLoadItem")
    require("SBAI.Server.Characters.AI.Objective.AIObjectiveLoadItems")
    require("SBAI.Server.Items.ItemInventory")
end