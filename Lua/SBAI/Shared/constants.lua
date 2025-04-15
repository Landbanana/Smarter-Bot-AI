local Constants = {
    Name="Smarter Bot AI",
    Acronym="SBAI",
    Version="1.4.1",
    Path=...,
    ModConfigsDirPath = Game.SaveFolder.."/ModConfigs", --[[@type string]]
    D_TIMER_NOISE = 0.1
}

Constants.ConfigPath = Constants.ModConfigsDirPath.."/"..Constants.Acronym..".json" --[[@type string]]

return Constants