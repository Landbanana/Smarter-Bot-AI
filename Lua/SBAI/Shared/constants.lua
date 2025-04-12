local Constants = {
    Name="Smarter Bot AI",
    Acronym="SBAI",
    Version="1.3.2",
    Path=...,
    ModConfigsDirPath = Game.SaveFolder.."/ModConfigs" --[[@type string]]
}

Constants.ConfigPath = Constants.ModConfigsDirPath.."/"..Constants.Acronym..".json" --[[@type string]]

return Constants