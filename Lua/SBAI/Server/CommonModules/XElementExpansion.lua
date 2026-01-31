---@class (constructor) System.Xml.Linq.XElement
---@field public GetAttributeFloat fun(key:string, def?:number):(number)
---@field public GetAttributeIdentifier fun(key:string, def?:Barotrauma.Identifier):(Barotrauma.Identifier)
---@field public GetAttributeIdentifierArray fun(key:string, def?:Barotrauma.Identifier[]):(Barotrauma.Identifier[])
---@field public GetAttributeString fun(key:string, def?:string):(string)

---@param self CommonModule
local function activate(self)
    return LuaUserData.RegisterExtensionType("Barotrauma.XMLExtensions")
end

return Types.CommonModule("XElementExpansion", activate)