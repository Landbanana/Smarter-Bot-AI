SBAI = require("SBAI")

if  CLIENT or
    Game.IsSingleplayer
then
    require("SBAI.Client.configGui")(SBAI.namespace)
end

SBAI.Control.Activate()

local util = require("SBAI.Shared.util")

printOrders = util.debug.PrintOrders


-- for p in ContentPackageManager.RegularPackages do
--     print(p.Name)
-- end

