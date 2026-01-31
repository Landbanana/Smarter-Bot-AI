---@class (partial) Control
---@field package modules {[string]:Module}
local Control = {modules={}}


do
    local ConfigOptionsModules---@type Config.Section

    for c in Config.data --[=[@as fun():(Config.Base)]=] do
        if c.name == "Modules" then
            ConfigOptionsModules = c
            break
        end
    end

    local modules = Control.modules

    local logWarn = Errortools.logWarn
    local prefixAcronym = Stringtools.prefixAcronym
    local requireSpecific = requireSpecific

    for c in ConfigOptionsModules --[=[@as fun():(Config.SectionToggle)]=] do
        local name = c.name
        local module = requireSpecific(("SBAI.Shared.Modules.%s"):format(name)) ---@type Module?
        
        if module == nil then
            logWarn(prefixAcronym("Control"), "Cannot find files for Module: %s", name)
        else
            module.config = c
            modules[name] = module
        end
    end
end

do
    local modules = Control.modules

    ---@public
    function Control.start()
        for m in modules --[=[@as fun():(Module)]=] do
            m:activate()
        end
    end
end

do
    local modules = Control.modules

    ---@public
    function Control.stop()
        for m in modules --[=[@as fun():(Module)]=] do
            m:deactivate()
        end
    end
end
 
return Control