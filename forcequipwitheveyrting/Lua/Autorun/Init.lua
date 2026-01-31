SBAI = require("SBAI")

if  CLIENT or
    Game.IsSingleplayer
then
    require("SBAI.Client.configGui")(SBAI.namespace)
end

SBAI.Control.Activate()


-- local function keysOnly(t, k)
--     k = next(t, k)
--     return k
-- end

-- local test = setmetatable({}, {
--     __iterator=function(t)
--         return keysOnly, t
--     end
-- })

-- test["A"] = true
-- test["B"] = true
-- test["C"] = true
-- test["D"] = true

-- for k, v in test do
--     print(k, v)
-- end