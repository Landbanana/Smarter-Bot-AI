SBAI = require("SBAI")

local Config = require("SBAI.Shared.config")

if  CLIENT or
    Game.IsSingleplayer
then
    require("SBAI.Client.configGui")(SBAI.namespace)
end

Config.Load()
SBAI.Control.Activate()

local util = require("SBAI.Shared.util")

-- for s in util.debug.GetAllMethodNames("Barotrauma.AIObjectiveContainItem") do
--     print(s)
-- end