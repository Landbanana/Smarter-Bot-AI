local Constants = require("SBAI.Shared.constants")
local util = require("SBAI.Shared.util")
local Types = require("SBAI.Shared.types")

do
    local AutoRegisterType = util.AutoRegisterType

    AutoRegisterType("Barotrauma.AIObjectiveDeconstructItem")

    local descriptor = AutoRegisterType("Barotrauma.AIObjectiveDeconstructItems")
    LuaUserData.MakeMethodAccessible(descriptor, "IsValidTarget", {"Barotrauma.Item"})
    LuaUserData.MakePropertyAccessible(descriptor, "MaxTargets")
end

---@param self Types.Module
---@param options table
local function activatePurchasedItems(self, options)
    local yield = coroutine.yield

    local autoOrder = options["autoOrder"]
    local doCrateOrder --[[@type fun(item:Barotrauma.Item)]]

    if autoOrder == 1 then
        local DeconstructItems --[[@type System.Collections.Generic.HashSet*1Barotrauma*Item]]

        self:RegisterStrongRef("Item.DeconstructItems", "System.Collections.Generic.HashSet`1[Barotrauma.Item]", "Barotrauma.Item",
        function(strongRef) DeconstructItems = strongRef end)

        --orderPrefab = OrderPrefab.Prefabs[Identifier("deconstructthis")]
        ---@param item Barotrauma.Item
        function doCrateOrder(item)
            return DeconstructItems.Add(item)
        end
    elseif autoOrder == 2 then
        local Game = Game
        local Order = Order
        local orderPrefab = OrderPrefab.Prefabs[Identifier("ignorethis")]

        ---@param item Barotrauma.Item
        function doCrateOrder(item)
            return Game.GameSession.CrewManager.AddOrder(Order(orderPrefab, item))
        end
    end

    local n

    self:AddPatch("Barotrauma.CargoManager", "GetOrCreateCargoContainerFor", nil,
    function(instance, ptable)
        n = #ptable["availableContainers"]
    end, Hook.HookMethodType.Before)

    self:AddPatch("Barotrauma.CargoManager", "GetOrCreateCargoContainerFor", nil,
    function(instance, ptable)
        local itemContainer = ptable.ReturnValue --[[@type Barotrauma.Items.Components.ItemContainer]]

        if itemContainer then
            if ptable["availableContainers"][n + 1] ~= nil then
                doCrateOrder(itemContainer.Item)
            end
        end
        n = nil
    end, Hook.HookMethodType.After)
end

---@param self Types.Module
---@param options table
local function activateDeconstructInBulk(self, options)
    local deconstructItemsId = Constants.ID_OBJECTIVE_BASE.DECONSTRUCTITEMS
    local maxCheck = options["maxCheck"]

    local DeconstructItems --[[@type System.Collections.Generic.HashSet*1Barotrauma*Item]]

    self:RegisterStrongRef("Item.DeconstructItems", "System.Collections.Generic.HashSet`1[Barotrauma.Item]", "Barotrauma.Item",
    function(strongRef) DeconstructItems = strongRef end)

    self:AddPatch("Barotrauma.AIObjectiveDeconstructItem","<Act>b__13_0", nil,
    function(instance, ptable)
        local curObj = instance.objectiveManager.CurrentObjective

        if curObj.Identifier == deconstructItemsId then
            local moveItemObj = ptable.ReturnValue --[[@type Barotrauma.AIObjectiveMoveItem]]
            local targetItem = moveItemObj.TargetItem
        
            moveItemObj.Equip = false

            do
                local moveStack = true

                for item in targetItem.GetStackedItems() do
                    if  not (DeconstructItems.Contains(item) and
                        curObj.IsValidTarget(item))
                    then
                        moveStack = false
                        break
                    end
                end
                if moveStack then
                    moveItemObj.TakeWholeStack = true
                end
            end
        end
    end, Hook.HookMethodType.After)

    self:AddPatch("Barotrauma.AIObjectiveGetItem", ".ctor",
    {"Barotrauma.Character", "Barotrauma.Item", "Barotrauma.AIObjectiveManager", "System.Boolean", "System.Single"},
    function(instance, ptable)
        local character = ptable["character"] --[[@type Barotrauma.Character]]

        if  character.IsOnPlayerTeam then
            local curObj = ptable["objectiveManager"].CurrentObjective --[[@type Barotrauma.AIObjective]]

            if curObj.Identifier == deconstructItemsId then
                local targetItem = ptable["targetItem"] --[[@type Barotrauma.Item]]
                local nearbyItems = {}
                local i = 0

                local rootContainer = targetItem.RootContainer

                if rootContainer then
                    for item in DeconstructItems do --[[@cast item Barotrauma.Item]]
                        if  item.RootContainer == rootContainer and
                            item ~= targetItem
                        then
                            i = i + 1
                            nearbyItems[i] = item
                            if i >= maxCheck then break end
                        end
                    end
                end

                -- if  not nearbyItems:IsEmpty() and
                --     curObj.CurrentSubObjective.CurrentSubObjective.TakeWholeStack
                -- then
                --     for item in targetItem.GetStackedItems() do
                --         nearbyItems:Remove(item)
                --     end
                -- end

                if i > 0 then
                    instance.Completed.add(
                    function()
                        -- if rootContainer then
                        --     for item in next, curObj.Objectives do
                        --         if item.RootContainer == rootContainer then
                        --             character.TryPutItemInAnySlot(item)
                        --         end
                        --     end
                        -- end
                        for j=1,i,1 do
                            local item = nearbyItems[j]

                            if  not item.IsOwnedBy(character) and
                                curObj.IsValidTarget(item)
                            then
                                character.TryPutItemInAnySlot(item)
                            end
                            --if not character.TryPutItemInAnySlot(item) then return end
                        end
                    end)
                end
            end
        end
    end, Hook.HookMethodType.After)

    local getList

    do
        local new = Types.Set.new
        local wrap = coroutine.wrap
        local yield = coroutine.yield
        local setmetatable = setmetatable

        local nonInvContainers_mt = {
            __index=function(t, k)
                local out = {}

                out[1] = 1

                t[k] = out
                return out
            end
        }

        ---@param character Barotrauma.Character
        ---@return Barotrauma.item
        local function co(character)
            yield()
            local nonInvContainers = setmetatable({}, nonInvContainers_mt)
            local looseItems = {}
            local i = 0

            for item in DeconstructItems do --[[@cast item Barotrauma.Item]]
                if item.IsOwnedBy(character) then
                    yield(item)
                else
                    local rootContainer = item.RootContainer

                    if rootContainer then
                        local subSection = nonInvContainers[rootContainer]
                        local j = subSection[1] + 1

                        subSection[1] = j
                        subSection[j] = item
                    else
                        i = i + 1
                        looseItems[i] = item
                    end
                end
            end
            local countedItems = new()

            for items in nonInvContainers do
                for j=2,items[1],1 do
                    for item in items[j].GetStackedItems() do
                        if not countedItems[item] then
                            countedItems:Add(item)
                            yield(item)
                        end
                    end
                end
            end
            for j=1,i,1 do
                yield(looseItems[j])
            end
        end

        ---@param character Barotrauma.Character
        ---@return fun():Barotrauma.Item
        function getList(character)
            local out = wrap(co)

            out(character)
            return out
        end
    end

    self:AddPatch("Barotrauma.AIObjectiveDeconstructItems", "GetList", nil,
    function(instance, ptable)
        local character = instance.character

        if instance.character.IsOnPlayerTeam then
            ptable.PreventExecution = true
            
            local maxOut = instance.MaxTargets
            local out = {}
            local i = 0

            for item in getList(character) do
                i = i + 1
                out[i] = item
                if i >= maxOut then break end
            end
            return out
        end
    end, Hook.HookMethodType.Before)
end

---@param self Types.Module
---@param options table
local function activateOnlyUseShipDeconstructor(self, options)
    local AIObjectiveDeconstructItem = self:RegisterStatic("Barotrauma.AIObjectiveDeconstructItem")
    local playerDeconstructors = self:RegisterTable(nil, "ROUND_END") --[=[@type Barotrauma.Item[]]=]
    local getNumPlayerDeconstructors

    do
        local n = -1
        do
            local Deconstructor = Components.Deconstructor
            local Submarine = Submarine

            ---@return integer
            function getNumPlayerDeconstructors()
                if n < 0 then
                    n = 0
                    for item in Submarine.MainSub.GetItems(true) do
                        if item.GetComponent(Deconstructor) ~= nil then
                            n = n + 1
                            playerDeconstructors[n] = item
                        end
                    end
                end
                return n
            end
        end
        
        do
            local Character = Character

            self:AddInit(
            function()
                n = -1
                for c in Character.CharacterList do
                    if  c.IsHuman and
                        c.IsBot and
                        c.IsOnPlayerTeam and
                        c.AIController.objectiveManager.HasOrder(AIObjectiveDeconstructItem)
                    then
                        return getNumPlayerDeconstructors()
                    end
                end
            end)
        end
    end

    do
        local Deconstructor = Components.Deconstructor

        local FindItems = util.FindItems
        local GetClosest = util.GetClosest
        local PoweredItemHasNeededPower = util.PoweredItemHasNeededPower

        self:AddPatch("Barotrauma.AIObjectiveDeconstructItem", "FindDeconstructor", nil,
        function(instance, ptable)
            local character = instance.character

            if character.IsOnPlayerTeam then
                if getNumPlayerDeconstructors() > 0 then
                    ---@type Barotrauma.Item
                    local closestDeconItem = GetClosest(character.WorldPosition, FindItems(nil, playerDeconstructors, nil, nil,
                    function(_, i)
                        return i.GetComponent(Deconstructor).InputContainer.Inventory.CanBePut(instance.Item) and
                            i.HasAccess(character) and
                            PoweredItemHasNeededPower(i)
                    end))

                    ptable.PreventExecution = true

                    if closestDeconItem ~= nil then
                        return closestDeconItem.GetComponent(Deconstructor)
                    end
                end
            end
        end, Hook.HookMethodType.Before)
    end
end

---@param self Types.Module
local function activate(self)
    self:DoOption("PurchasedItemCrates", activatePurchasedItems)
    self:DoOption("DeconstructInBulk", activateDeconstructInBulk)
    self:DoOption("OnlyUseShipDeconstructor", activateOnlyUseShipDeconstructor)
end

return Types.Module.new(activate)