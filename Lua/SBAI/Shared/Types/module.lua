do
    local concat = concat

    ---@class Module: Object
    ---@field public cls Module
    ---@field public config Config.SectionToggle
    ---@field public id string
    ---@field public isActive boolean
    ---@field public moduleName string
    ---@field protected _activate fun(self, config:{[string]:Json})
    ---@field protected _deactivate fun(self, config:{[string]:Json})
    ---@field protected _instances Deque<Module>
    ---@field protected _namespace Deque<string>
    ---@field package activateParts {[string]:fun(self:Module, config:{enable:boolean, [string]:Json}|boolean)}
    ---@field package addedHooks Deque<{[1]:string, [2]:string}>
    ---@field package addedInits Deque<fun()>
    ---@field package addedPatches Deque<{[1]:string, [2]:string, [3]:string, [4]:string[]?, [5]:("Before"|"After")}>
    ---@field package addedRoundTables Deque<table>
    ---@field package commonModules {[string]:CommonModule}
    ---@field package deactivateParts {[string]:fun(instance:Module, config:{enable:boolean, [string]:Json}|boolean)}
    Types.Module = Types.new("Module", "Object", {
        config = Types.Desc.Property--[[@as Desc.Property<Config.SectionToggle>]](nil,
            Types.Desc.Property.getT,
            ---@param v Config.SectionToggle
            function(self, cls, obj, v)
                if self:getT(cls, obj) == nil then
                    local moduleName = v.name

                    obj.moduleName = moduleName
                    obj._namespace:push(moduleName)
                    return self:setT(cls, obj, v)
                else
                    return self:setF(cls, obj, v)
                end
            end);
        id = Types.Desc.TiedConstant--[[@as Desc.TiedConstant<Module>]](
            function(self, cls, obj)
                local _namespace = obj._namespace
                local out = concat(_namespace, ".", _namespace.i, _namespace.j)

                return out
            end);
        activateParts = Types.Desc.Lazy(Tabletools.new);
        addedHooks = Types.Desc.Lazy(Types.Deque.newF);
        addedInits = Types.Desc.Lazy(Types.Deque.newF);
        addedPatches = Types.Desc.Lazy(Types.Deque.newF);
        addedRoundTables = Types.Desc.Lazy(Types.Deque.newF);
        deactivateParts = Types.Desc.Lazy(Tabletools.new);
        moduleName = Types.Desc.Readonly(nil);
        _instances = Types.Deque();
        _deactivate = Functools.devnull;
    })
end

local Module = Types.Module

do
    local _instances = Module._instances

    local clear = Tabletools.clear
    local rawget = rawget

    Hook.Add(Module.__name, "roundEnd",
    function(...)
        for obj in _instances --[=[@as fun():(Module)]=] do
            local addedRoundTables = rawget(obj, "addedRoundTables")

            if addedRoundTables ~= nil then
                for t in addedRoundTables --[=[@as fun():(table)]=] do
                    clear(t)
                end
            end
        end
    end)
end

do
    local _instances = Module._instances

    Hook.Add(Module.__name, "roundStart",
    function(...)
        for obj in _instances --[=[@as fun():(Module)]=] do
            obj:init()
        end
    end)
end

do
    local namespaceStart = Stringtools.prefixAcronym("Modules")
    local Deque = Types.Deque

    ---@public
    ---@param activate? fun(self:Module, config:{[string]:Json})
    ---@param deactivate? fun(self:Module, config:{[string]:Json})
    ---@param ... any
    ---@nodiscard
    function Module:__new(activate, deactivate, ...)
        local obj = Module.super.__new(self, ...)

        obj.isActive = false
        obj._activate = activate
        obj._deactivate = deactivate

        local _namespace = Deque()

        obj._namespace = _namespace
        _namespace:push(namespaceStart)

        obj._instances:push(obj)
        return obj
    end
end

do
    local ferror = ferror
    local rawget = rawget
    local requireSpecific = requireSpecific

    ---@param name string
    ---@return table?
    function Module:addCommonModule(name)
        local commonModule = requireSpecific(("SBAI.Shared.CommonModules.%s"):format(name)) ---@type CommonModule?

        if commonModule then
            commonModule:activate(self.moduleName)
            return rawget(commonModule, "export")
        else
            return ferror("Unknown CommonModule name: %s", 2, name)
        end
    end
end

do
    local Add = Hook.Add
    local raise = raise

    ---@public
    ---@param eventName string
    ---@param f fun(...:any):(any)
    function Module:addHook(eventName, f)
        local id = self.id

        raise(Add, id, eventName, f)
        return self.addedHooks:push({eventName, id})
    end
end

do

    ---@public
    ---@param f fun()
    function Module:addInit(f)
        return self.addedInits:push(f)
    end
end

do
    local Patch = Hook.Patch
    local raise = raise

    ---@public
    ---@generic T:System.Object
    ---@param typeName `T`
    ---@param methodName keyof T
    ---@param parameterTypes? string[]
    ---@param hookType "Before"|"After"
    ---@param f fun(instance:T, ptable:Barotrauma.LuaCsHook.ParameterTable):(any)
    function Module:addPatch(typeName, methodName, parameterTypes, hookType, f)
        local id = self.id

        raise(Patch, id, typeName, methodName, parameterTypes, hookType, f)
        return self.addedPatches:push({id, typeName, methodName, parameterTypes, hookType})
    end
end

do
    local partial1 = Functools.partial1

    ---@public
    ---@generic T:table
    ---@param t T
    ---@param f? fun(t:T)
    function Module:addRoundTable(t, f)
        self.addedRoundTables:push(t)
        if f then
            return self:addInit(partial1(f, t))
        end
    end
end

do
    local logError = Errortools.logError
    local pcall = pcall

    ---@public
    ---@generic P
    ---@param f fun(self, ...:P)
    ---@return boolean
    function Module:pcall(f, ...)
        local success, msg = pcall(f, self, ...)

        if success then
            return true
        else ---@cast msg -?
            local id = self.id

            logError(id, ("%s>>\n    %s"):format(id, msg))
            return false
        end
    end
end

do
    local rawget = rawget

    function Module:init()
        local addedInits = rawget(self, "addedInits")

        if addedInits ~= nil then
            for f in addedInits --[=[@as fun():(fun())]=] do
                f()
            end
        end
    end
end

do
    local Game = Game

    ---@protected
    ---@param data? any
    ---@return boolean
    ---@nodiscard
    function Module:_activateBase(data)
        self.isActive = true

        local success = (((not Game.RoundStarted) or self:pcall(self.init)) and self:pcall(self._activate, data))

        if not success then
            self:_deactivateBase(data)
        end
        return success
    end
end

do
    local _remove --[=[@[lsp_optimization("delayed_definition")]]=] do
        local Remove = Hook.Remove
        local unpack = table.unpack

        _remove = function(v)
            return Remove(unpack(v, 1, 2))
        end
    end

    local _removePatch --[=[@[lsp_optimization("delayed_definition")]]=] do
        local RemovePatch = Hook.RemovePatch
        local unpack = table.unpack

        _removePatch = function(v)
            return RemovePatch(unpack(v, 1, 5))
        end
    end

    local rawget = rawget

    ---@protected
    ---@param data? any
    function Module:_deactivateBase(data)
        local addedHooks = rawget(self, "addedPatches")

        if addedHooks ~= nil then
            addedHooks:clearF(_remove)
        end

        local addedInits = rawget(self, "addedInits")

        if addedInits ~= nil then
            addedInits:clear()
        end

        local addedPatches = rawget(self, "addedPatches")

        if addedPatches ~= nil then
            addedPatches:clearF(_removePatch)
        end

        local addedRoundTables = rawget(self, "addedRoundTables")

        if addedRoundTables ~= nil then
            addedRoundTables:clear()
        end

        local _deactivate = rawget(self, "_deactivate") ---@cast _deactivate +?

        if _deactivate then
            self:pcall(_deactivate, data == nil and self.config:flatten() or data)
        end

        self.isActive = false
    end
end

do
    ---@public
    ---@param k string
    ---@param f fun(self:Module, config:{enable:boolean, [string]:Json}|boolean)
    function Module:activateOption(k, f)
        self.activateParts[k] = f
    end
end

do
    ---@public
    ---@param k string
    ---@param f fun(self:Module, config:{enable:boolean, [string]:Json}|boolean)
    function Module:deactivateOption(k, f)
        self.deactivateParts[k] = f
    end
end

do
    local next = next
    local rawget = rawget
    local type = type

    function Module:activate()
        local config = self.config:flatten()

        if config.enable then
            if self:_activateBase(config) then
                local activateParts = rawget(self, "activateParts")

                if activateParts ~= nil then
                    local _namespace = self._namespace

                    for k, f in next, activateParts do
                        local _config = config ---@type {enable:boolean, [string]:Json}|boolean
                        local n = 0 ---@type integer
                        local doPart ---@type boolean?
                        local _

                        for s in k:gmatch("([^%.]+)") do
                            n = n + 1
                            _namespace:push(s)
                            _config = config[s]

                            local configType = type(config)

                            if configType == "table" then
                                if _config.enable == false then
                                    doPart = false
                                    break
                                end
                            elseif configType == "boolean" then
                                if not _config then
                                    doPart = false
                                    break
                                end
                            end
                        end

                        local success = true

                        if doPart then
                            success = self:pcall(f, _config)
                        end

                        for _=1,n do
                            _namespace:pop()
                        end

                        if not success then
                            return self:deactivate(config)
                        end
                    end
                end
            end
        end
    end
end

do
    local next = next
    local rawget = rawget
    local type = type

    ---@param config? {[string]:Json}
    function Module:deactivate(config)
        if not self.isActive then return end
        self:_deactivateBase(config)

        local deactivateParts = rawget(self, "deactivateParts")

        if deactivateParts ~= nil then
            local _namespace = self._namespace

            for k, f in next, deactivateParts do
                local _config = config ---@type {enable:boolean, [string]:Json}|boolean
                local n = 0 ---@type integer
                local doPart ---@type boolean?
                local _

                for s in k:gmatch("([^%.]+)") do
                    n = n + 1
                    _namespace:push(s)
                    _config = config[s]

                    local configType = type(_config)

                    if configType == "table" then
                        if _config.enable == false then
                            doPart = false
                            break
                        end
                    elseif configType == "boolean" then
                        if not _config then
                            doPart = false
                            break
                        end
                    end
                end

                if doPart then
                    self:pcall(f, _config)
                end

                for _=1,n do
                    _namespace:pop()
                end
            end
        end
    end
end

return Types.Module