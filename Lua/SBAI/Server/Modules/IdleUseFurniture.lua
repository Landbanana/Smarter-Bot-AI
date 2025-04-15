local SBAI = require("SBAI")
local util = require("SBAI.Shared.util")

LuaUserData.MakeFieldAccessible(Descriptors["Barotrauma.Item"], "_chairItems")

---@param namespace Namespace
---@param options table
return function(namespace, options)
    local identifiers = {} --[=[@type Barotrauma.Identifier[]]=]

    local _chairItems = setmetatable({}, {
        __call=function(t)
            if not t.data then
                do
                    local ItemList = util.UnregisteredStaticDescriptors["System.Collections.Generic.List`1[[Barotrauma.Item]]"]

                    t.data = LuaUserData.CreateUserDataFromDescriptor(ItemList.Static(Item, {}), ItemList.Descriptor)
                end

                for item in Item.ItemList do --[[@cast item Barotrauma.Item]]
                    for id in identifiers do --[[@cast id Barotrauma.Identifier]]
                        if item.Prefab.Identifier == id then
                            t.data.Add(item)
                            break
                        end
                    end
                end
            end
            return t.data
        end
    })

    util.RegisterClear(_chairItems, util.CLEAR_REG.ROUND_END)

    SBAI.Hook.Add("roundStart", namespace(),
    function()
        return _chairItems()
    end)

    SBAI.Hook.Patch(namespace(), "Barotrauma.Item", "get_ChairItems",
    function(instance, ptable)

        ptable.PreventExecution = true

        return _chairItems()
    end, Hook.HookMethodType.Before)

    do
        local predicates = {} --[[@type table<string,(fun(prefab:Barotrauma.ItemPrefab):boolean)>]]

        ---@param name string
        ---@param predicate fun(prefab:Barotrauma.ItemPrefab):boolean
        local function addPredicate(name, predicate)
            if options[name] then
                predicates[name] = predicate
            end
        end

        addPredicate("Chairs", function(prefab)
            return util.ValsContain(prefab.Tags, "chair")
        end)

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
        
        do
            local i = 0

            for func in predicates do --[[@cast func fun(prefab:Barotrauma.ItemPrefab):boolean]]
                for prefab in ItemPrefab.Prefabs do
                    if func(prefab) then
                        i = i + 1
                        identifiers[i] = prefab.Identifier
                    end
                end
            end
        end
    end
end