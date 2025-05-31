local Constants = require("SBAI.Shared.constants")
local util = require("SBAI.Shared.util")
local Types = require("SBAI.Shared.types")

---@param self Types.CommonModule
local function activate(self)
    local AddMethod = util.functools.Partial2(self.AddMethod, self, "Barotrauma.Inventory")

    do
        local FilterList = util.itertools.FilterList
        local wrap = coroutine.wrap
        local yield = coroutine.yield

        ---@param instance Barotrauma.Inventory
        ---@param checkForDuplicates boolean?
        ---@param recursive boolean?
        ---@param p fun(v:Barotrauma.Item):boolean
        ---@return fun():Barotrauma.Item?
        local function findAllItems(instance, checkForDuplicates, recursive, p)
            local iEnumerable = checkForDuplicates ~= nil and instance.GetAllItems(checkForDuplicates) or instance.AllItems

            if recursive then
                return wrap(function()
                    for item in iEnumerable do
                        local ownInventory = item.OwnInventory

                        if p(item) then yield(item) end
                        if ownInventory then
                            for subItem in ownInventory:SBAI_findAllItems(checkForDuplicates, true, p) do
                                yield(subItem)
                            end
                        end
                    end
                end)
            else
                return FilterList(iEnumerable, p)
            end
        end

        AddMethod("findAllItems", findAllItems)
        ---@class Barotrauma.Inventory
        ---@field public SBAI_findAllItems fun(instance:Barotrauma.Inventory, checkForDuplicates:boolean?, recursive:boolean?, p:fun(v:Barotrauma.Item):boolean):fun():Barotrauma.Item?
    end

    do
        ---@param instance Barotrauma.Inventory
        ---@param recursive boolean?
        ---@param p fun(v:Barotrauma.Item):boolean
        ---@return boolean
        local function hasAnyItem(instance, recursive, p)
            local iEnumerable = instance.GetAllItems(false)

            if recursive then
                for item in iEnumerable do
                    local ownInventory = item.OwnInventory

                    if p(item) then return true end
                    if  ownInventory and
                        ownInventory:SBAI_hasAnyItem(true, p)
                    then
                        return true
                    end
                end
                return false
            else
                for item in iEnumerable do
                    local ownInventory = item.OwnInventory

                    if p(item) then return true end
                end
                return false
            end
        end

        AddMethod("hasAnyItem", hasAnyItem)
        ---@class Barotrauma.Inventory
        ---@field public SBAI_hasAnyItem fun(instance:Barotrauma.Inventory, recursive:boolean?, p:fun(v:Barotrauma.Item):boolean):boolean
    end
end

return Types.CommonModule.new(activate)