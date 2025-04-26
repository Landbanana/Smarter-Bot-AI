local Constants = {
    Name="Smarter Bot AI",
    Acronym="SBAI",
    Version="1.5.2d",
    Path=table.pack(...)[1] --[[@type string]],
    ModConfigsDirPath=Game.SaveFolder.."/ModConfigs", --[[@type string]]

    MAX_FLOAT=3.402823E+38,

    D_TIMER_NOISE=0.1,
    D_PETITEM_TEMPLATE="creepingorange",
    D_NONTHREATENING_STUN=20
}

Constants.ConfigPath = Constants.ModConfigsDirPath.."/"..Constants.Acronym..".json" --[[@type string]]

return Constants