local Constants = {
    Name="Smarter Bot AI",
    Acronym="SBAI",
    Version="1.6.5",
    Path=ToolBox.CleanUpPath(table.pack(...)[1]),
    ModConfigsDirPath=ToolBox.CleanUpPath(Game.SaveFolder.."/ModConfigs"), --[[@type string]]

    CLR_TYPE_POSTFIX = CLIENT and "Barotrauma" or "DedicatedServer", -- This is super dumb

    MAX_FLOAT=3.402823E+38,
    MAX_INT=2147483647,

    D_TIMER_NOISE=0.1,
    D_PETITEM_TEMPLATE="creepingorange",
    D_NONTHREATENING_STUN=20,

    ---@enum Constants.ID_ORDER
    ID_ORDER={
        FABRICATEITEMS = Identifier("sbai_fabricateitems"),
        IGNOREROOM = Identifier("sbai_ignoreroom"),
        PERFORM = Identifier("sbai_perform"),
        SBAICATEGORY = Identifier("sbai"),
        UNIGNORE_ROOM = Identifier("sbai_unignoreroom")
    },

    ---@enum ID_OBJECTIVE
    ID_OBJECTIVE={
        PERFORM = Identifier("sbai_perform"),
        PETPLAY = Identifier("sbai_petplay"),
        REPLENISH = Identifier("sbai_replenish"),
        REPLENISHCLEAN = Identifier("sbai_replenishclean")
    },

    ---@enum ID_OBJECTIVE_BASE
    ID_OBJECTIVE_BASE={
        CLEANUPITEM = Identifier("cleanup item"),
        CONTAINITEM = Identifier("contain item"),
        DECONSTRUCTITEM = Identifier("deconstructitem"),
        DECONSTRUCTITEMS = Identifier("deconstructitems"),
        GETITEM = Identifier("get item"),
        GOTO = Identifier("go to"),
        IDLE = Identifier("idle"),
        LOADITEM = Identifier("load item"),
        LOADITEMS = Identifier("loaditems"),
        OPERATEITEM = Identifier("operate item"),
        OPERATEREACTOR = Identifier("operatereactor"),
        POWERUP = Identifier("powerup"),
        WAIT = Identifier("wait")
    },
    ---@enum ITEMS_PER_FRAME
    ITEMS_PER_FRAME={
        OTHER=10,
        PLAYER=100
    },

    ---@enum TYPE_OBJECTIVE_BASE
    TYPE_OBJECTIVE_BASE={
        CLEANUPITEM = "Barotrauma.AIObjectiveCleanupItem",
        CONTAINITEM = "Barotrauma.AIObjectiveContainItem",
        DECONSTRUCTITEM = "Barotrauma.AIObjectiveDeconstructItem",
        GETITEM = "Barotrauma.AIObjectiveGetItem",
        GOTO = "Barotrauma.AIObjectiveGoTo",
        IDLE = "Barotrauma.AIObjectiveIdle",
        LOADITEM = "Barotrauma.AIObjectiveLoadItem",
        LOADITEMS = "Barotrauma.AIObjectiveLoadItems",
        BASE = "Barotrauma.AIObjective",
        OPERATEITEM = "Barotrauma.AIObjectiveOperateItem",
        OPERATEREACTOR = "Barotrauma.AIObjectiveOperateItem",
        POWERUP = "Barotrauma.AIObjectiveOperateItem",
        WAIT = "Barotrauma.AIObjectiveGoTo"
    },

    ID_COMMON={Identifier("smallitem"), Identifier("mediumitem")},
    ID_EMPTY = Identifier.Empty
}
-- ---@enum NETWORK_MSG
-- Constants.NETWORK_MSG = {
--     CONF_UPD=Constants.Acronym..".ConfigUpdate",
--     CONF_REQ=Constants.Acronym..".ConfigRequest"
-- }


Constants.ConfigPath = ToolBox.CleanUpPath(Constants.ModConfigsDirPath.."/"..Constants.Acronym..".json")

Constants.defaultNestedMethodNames = {
    ["Barotrauma.ItemPrefab[<GetMaxStackSize>g__MaxStackWithExtra|]"]="<GetMaxStackSize>g__MaxStackWithExtra|352_0",
    ["Barotrauma.CrewManager[<CreateContextualOrderNodes>g__AddIgnoreOrder|]"]="<CreateContextualOrderNodes>g__AddIgnoreOrder|167_0"
}


do
    local ID_OBJECTIVE_BASE = Constants.ID_OBJECTIVE_BASE

    Constants.ID_OBJECTIVE_TO_BASE = setmetatable({
        [Constants.ID_OBJECTIVE.PERFORM]=Constants.ID_OBJECTIVE_BASE.OPERATEITEM,
        [Constants.ID_OBJECTIVE.PETPLAY]=Constants.ID_OBJECTIVE_BASE.GOTO,
        [Constants.ID_OBJECTIVE.REPLENISH]=Constants.ID_OBJECTIVE_BASE.CONTAINITEM,
        [Constants.ID_OBJECTIVE.REPLENISHCLEAN]=Constants.ID_OBJECTIVE_BASE.CLEANUPITEM
    },
    {
        ---@param t table<ID_OBJECTIVE|ID_OBJECTIVE_BASE,ID_OBJECTIVE_BASE>
        ---@param k ID_OBJECTIVE|ID_OBJECTIVE_BASE
        ---@return unknown
        __index=function(t, k)
            for v in ID_OBJECTIVE_BASE do
                if v == k then
                    t[k] = v
                    return v
                end
            end
            error("Cannot find base objective for objId: "..k.Value, 2)
        end
    })
end

return Constants