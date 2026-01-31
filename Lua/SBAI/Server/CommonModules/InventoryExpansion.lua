---@class (constructor) Barotrauma.Inventory
---@field public SBAI_findAllItems fun(instance:Barotrauma.Inventory, checkForDuplicates:boolean?, recursive:boolean?, p:fun(inventory:Barotrauma.Inventory, item:Barotrauma.Item):(boolean)):(fun():Barotrauma.Item?)
---@field public SBAI_hasAnyItem fun(instance:Barotrauma.Inventory, recursive:boolean?, p:fun(inventory:Barotrauma.Inventory, item:Barotrauma.Item):(boolean)):(boolean)


---@param self CommonModule
local function activate(self)
    local addInvMethod = Functools.partial2(self.addMethod, self, "Barotrauma.Inventory")
    local addItemInvMethod = Functools.partial2(self.addMethod, self, "Barotrauma.ItemInventory")
    local addCharInvMethod = Functools.partial2(self.addMethod, self, "Barotrauma.CharacterInventory")

    do
        local recursiveFindAllItems --[=[@[lsp_optimization("delayed_definition")]]=] do
            local yield = yield

            ---@async
            ---@param instance Barotrauma.Inventory
            ---@param checkForDuplicates boolean?
            ---@param p fun(inventory:Barotrauma.Inventory, item:Barotrauma.Item):(boolean)
            ---@param iEnumerable fun():(Barotrauma.Item)
            recursiveFindAllItems = function(instance, checkForDuplicates, p, iEnumerable)
                yield()
                for item in iEnumerable do
                    if p(instance, item) then yield(item) end

                    local ownInventory = item.OwnInventory
                    
                    if ownInventory ~= nil then
                        for subItem in ownInventory:SBAI_findAllItems(checkForDuplicates, true, p) do
                            yield(subItem)
                        end
                    end
                end
            end  
        end

        local nonrecursiveFindAllItems --[=[@[lsp_optimization("delayed_definition")]]=] do
            local yield = yield

            ---@async
            ---@param instance Barotrauma.Inventory
            ---@param p fun(inventory:Barotrauma.Inventory, item:Barotrauma.Item):(boolean)
            ---@param iEnumerable fun():(Barotrauma.Item)
            nonrecursiveFindAllItems = function(instance, p, iEnumerable)
                yield()
                for item in iEnumerable do
                    if p(instance, item) then yield(item) end
                end
            end
        end

        local wrap = wrap

        ---@param instance Barotrauma.Inventory
        ---@param checkForDuplicates boolean?
        ---@param recursive boolean?
        ---@param p fun(inventory:Barotrauma.Inventory, item:Barotrauma.Item):(boolean)
        ---@return fun():(Barotrauma.Item?)
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
        addInvMethod("findAllItems", findAllItems)
    end

    do
        ---@param instance Barotrauma.Inventory
        ---@param recursive boolean?
        ---@param p fun(inventory:Barotrauma.Inventory, item:Barotrauma.Item):(boolean)
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
        addInvMethod("hasAnyItem", hasAnyItem)
    end
end

return Types.CommonModule("InventoryExpansion", activate)