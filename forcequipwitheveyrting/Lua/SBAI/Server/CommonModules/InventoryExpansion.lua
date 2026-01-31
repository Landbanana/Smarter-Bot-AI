local Constants = require("SBAI.Shared.constants")
local util = require("SBAI.Shared.util")
local Types = require("SBAI.Shared.types")

---@param self Types.CommonModule
local function activate(self)

    local AddMethod do
        local _AddMethod = self.AddMethod
        local Partial2 = util.functools.Partial2

        local addInvMethod = Partial2(_AddMethod, self, "Barotrauma.Inventory")
        local addItemInvMethod = Partial2(_AddMethod, self, "Barotrauma.ItemInventory")
        local addCharInvMethod = Partial2(_AddMethod, self, "Barotrauma.CharacterInventory")

        function AddMethod(methodName, method)
            return addInvMethod(methodName, method) and
                addItemInvMethod(methodName, method) and
                addCharInvMethod(methodName, method)
        end
    end

    do
        local recursiveFindAllItems do
            local yield = coroutine.yield

            ---@param instance Barotrauma.Inventory
            ---@param checkForDuplicates boolean?
            ---@param p fun(inventory:Barotrauma.Inventory, item:Barotrauma.Item):boolean
            ---@param iEnumerable fun():Barotrauma.Item
            function recursiveFindAllItems(instance, checkForDuplicates, p, iEnumerable)
                yield()
                for item in iEnumerable do
                    if p(instance, item) then yield(item) end

                    local ownInventory = item.OwnInventory
                    
                    if ownInventory then
                        for subItem in ownInventory:SBAI_findAllItems(checkForDuplicates, true, p) do
                            yield(subItem)
                        end
                    end
                end
            end
        end

        local nonrecursiveFindAllItems do
            local yield = coroutine.yield

            ---@param instance Barotrauma.Inventory
            ---@param p fun(inventory:Barotrauma.Inventory, item:Barotrauma.Item):boolean
            ---@param iEnumerable fun():Barotrauma.Item
            function nonrecursiveFindAllItems(instance, p, iEnumerable)
                yield()
                for item in iEnumerable do
                    if p(instance, item) then yield(item) end
                end
            end
        end

        local wrap = coroutine.wrap

        ---@param instance Barotrauma.Inventory
        ---@param checkForDuplicates boolean?
        ---@param recursive boolean?
        ---@param p fun(inventory:Barotrauma.Inventory, item:Barotrauma.Item):boolean
        ---@return fun():Barotrauma.Item?
        local function findAllItems(instance, checkForDuplicates, recursive, p)
            local iEnumerable = checkForDuplicates ~= nil and instance.GetAllItems(checkForDuplicates) or instance.AllItems
            local coFindAllItems

            if recursive then
                coFindAllItems = wrap(recursiveFindAllItems)
                coFindAllItems(instance, checkForDuplicates, p, iEnumerable)
            else
                coFindAllItems = wrap(nonrecursiveFindAllItems)
                coFindAllItems(instance, p, iEnumerable)
            end
            
            return coFindAllItems
        end

        AddMethod("findAllItems", findAllItems)
        ---@class Barotrauma.Inventory
        ---@field public SBAI_findAllItems fun(instance:Barotrauma.Inventory, checkForDuplicates:boolean?, recursive:boolean?, p:fun(inventory:Barotrauma.Inventory, item:Barotrauma.Item):boolean):fun():Barotrauma.Item?
    end

    do
        ---@param instance Barotrauma.Inventory
        ---@param recursive boolean?
        ---@param p fun(inventory:Barotrauma.Inventory, item:Barotrauma.Item):boolean
        ---@return boolean
        local function hasAnyItem(instance, recursive, p)
            local iEnumerable = instance.GetAllItems(false)

            if recursive then
                for item in iEnumerable do
                    local ownInventory = item.OwnInventory

                    if p(instance, item) then return true end
                    if  ownInventory and
                        ownInventory:SBAI_hasAnyItem(true, p)
                    then
                        return true
                    end
                end
                return false
            else
                for item in iEnumerable do
                    if p(instance, item) then return true end
                end
                return false
            end
        end

        AddMethod("hasAnyItem", hasAnyItem)
        ---@class Barotrauma.Inventory
        ---@field public SBAI_hasAnyItem fun(instance:Barotrauma.Inventory, recursive:boolean?, p:fun(inventory:Barotrauma.Inventory, item:Barotrauma.Item):boolean):boolean
    end
end

return Types.CommonModule.new(activate)