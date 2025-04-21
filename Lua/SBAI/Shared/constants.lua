local Constants = {
    Name="Smarter Bot AI",
    Acronym="SBAI",
    Version="1.5.0",
    Path=table.pack(...)[1] --[[@type string]],
    ModConfigsDirPath=Game.SaveFolder.."/ModConfigs", --[[@type string]]
    D_TIMER_NOISE=0.1,
    D_PETITEM_TEMPLATE="creepingorange"
}

Constants.ConfigPath = Constants.ModConfigsDirPath.."/"..Constants.Acronym..".json" --[[@type string]]

return Constants