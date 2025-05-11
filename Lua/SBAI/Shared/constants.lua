local Constants = {
    Name="Smarter Bot AI",
    Acronym="SBAI",
    Version="1.6.3b",
    Path=ToolBox.CleanUpPath(table.pack(...)[1]),
    ModConfigsDirPath=ToolBox.CleanUpPath(Game.SaveFolder.."/ModConfigs"), --[[@type string]]

    CLR_TYPE_POSTFIX = CLIENT and "Barotrauma" or "DedicatedServer",

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

return Constants