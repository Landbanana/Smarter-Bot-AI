SBAI = require("SBAI")

if  CLIENT or
    Game.IsSingleplayer
then
    require("SBAI.Client.configGui")(SBAI.namespace)
end

SBAI.Control.Activate()

--local util = require("SBAI.Shared.util")

--util.debug.PrintAllMethodNames("Barotrauma.AIObjectiveGetItem")