local Constants = {
    Name="Smarter Bot AI",
    Acronym="SBAI",
    Version="1.6.4",
    Path=ToolBox.CleanUpPath(table.pack(...)[1]),
    ModConfigsDirPath=ToolBox.CleanUpPath(Game.SaveFolder.."/ModConfigs"), --[[@type string]]

    CLR_TYPE_POSTFIX = CLIENT and "Barotrauma" or "DedicatedServer", -- This is super dumb

    MAX_FLOAT=3.402823E+38,
    MAX_INT=2147483647,

    D_TIMER_NOISE=0.1,
    D_PETITEM_TEMPLATE="creepingorange",
    D_NONTHREATENING_STUN=20,

    ---@enum Constants.ID_ORDER
    ID_ORDER = {
        FABRICATE_ITEMS = Identifier("sbai_fabricateitems"),
        IGNORE_ROOM = Identifier("sbai_ignoreroom"),
        PERFORM = Identifier("sbai_perform"),
        SBAI_CATEGORY = Identifier("sbai"),
        UNIGNORE_ROOM = Identifier("sbai_unignoreroom")
    },

    ---@enum ID_OBJECTIVE
    ID_OBJECTIVE = {
        PERFORM = Identifier("sbai_perform"),
        PET_PLAY = Identifier("sbai_petplay")
    },

    ---@enum ID_OBJECTIVE_BASE
    ID_OBJECTIVE_BASE = {
        CONTAIN_ITEM = Identifier("contain item"),
        DECONSTRUCT_ITEM = Identifier("deconstruct item"),
        GET_ITEM = Identifier("get item"),
        GOTO = Identifier("go to"),
        IDLE = Identifier("idle"),
        LOAD_ITEM = Identifier("load item"),
        LOAD_ITEMS = Identifier("loaditems"),
        OPERATE_ITEM = Identifier("operate item"),
        OPERATE_REACTOR = Identifier("operatereactor"),
        POWER_UP = Identifier("powerup"),
        WAIT = Identifier("wait")
    }
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
        [Constants.ID_OBJECTIVE.PERFORM]=Constants.ID_OBJECTIVE_BASE.OPERATE_ITEM,
        [Constants.ID_OBJECTIVE.PET_PLAY]=Constants.ID_OBJECTIVE_BASE.GOTO,
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