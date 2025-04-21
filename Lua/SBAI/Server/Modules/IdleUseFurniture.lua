local util = require("SBAI.Shared.util")
local Types = require("SBAI.Shared.types")

LuaUserData.MakeFieldAccessible(Descriptors["Barotrauma.Item"], "_chairItems")

---@param self Types.Module
local function activate(self)
    local ids = {} --[=[@type {[System.Int32]:true}]=]

    local _chairItems = setmetatable(self:RegisterTable("ROUND_END"), {
        __call=function(t)
            if not t.data then
                do
                    local ItemList = util.UnregisteredStaticDescriptors["System.Collections.Generic.List`1[[Barotrauma.Item]]"]

                    t.data = LuaUserData.CreateUserDataFromDescriptor(ItemList.Static(Item, {}), ItemList.Descriptor)
                end

                for item in Item.ItemList do --[[@cast item Barotrauma.Item]]
                    if ids[item.Prefab.Identifier.HashCode] then
                        t.data.Add(item)
                    end
                end
            end
            return t.data
        end
    })

    self:AddHook("roundStart",
    function()
        return _chairItems()
    end)

    self:AddPatch("Barotrauma.Item", "get_ChairItems", nil,
    function(instance, ptable)
        ptable.PreventExecution = true

        return _chairItems()
    end, Hook.HookMethodType.Before)

    do
        local predicates = {} --[[@type table<string,(fun(prefab:Barotrauma.ItemPrefab):boolean)>]]

        ---@param name string
        ---@param predicate fun(prefab:Barotrauma.ItemPrefab):boolean
        local function addPredicate(name, predicate)
            if self.options[name] then
                predicates[name] = predicate
            end
        end

        do
            local ValsContain = util.ValsContain

            addPredicate("Chairs", function(prefab)
                return ValsContain(prefab.Tags, "chair")
            end)
        end

        addPredicate("Beds", function(prefab)
            if prefab.Category == 2 then
                for element in prefab.ConfigElement.Elements() do
                    if  element.Name.ToString():lower() == "controller" and
                        element.GetAttribute("canbeselected") then
                        for subElement in element.Elements() do
                            return subElement.Name.ToString():lower() == "requireditem" and
                                subElement.GetAttribute("items").value == "deepdivinglarge" and
                                subElement.GetAttribute("requireempty").Value == "true"
                        end
                    end
                end
            end
        end)
        
        for prefab in ItemPrefab.Prefabs do
            for func in predicates do --[[@cast func fun(prefab:Barotrauma.ItemPrefab):boolean]]
                if func(prefab) then
                    ids[prefab.Identifier.HashCode] = true
                    break
                end
            end
        end
    end
end

return Types.Module.new(activate)