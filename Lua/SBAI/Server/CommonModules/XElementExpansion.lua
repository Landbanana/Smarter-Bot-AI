local Types = require("SBAI.Shared.types")

---@param self Types.CommonModule
local function activate(self)
    LuaUserData.RegisterExtensionType("Barotrauma.XMLExtensions")

    ---@class System.Xml.Linq.XElement
    ---@field public GetAttributeIdentifierArray fun(key:string, def?:Barotrauma.Identifier[]):Barotrauma.Identifier[]
    ---@field public GetAttributeIdentifier fun(key:string, def?:Barotrauma.Identifier):Barotrauma.Identifier
end

return Types.CommonModule.new(activate)