---@class Types
local Types = {}

do
    local error = error

    ---@param ... any
    ---@return any
    ---@[deprecated("Abstract function needs to be overridden")]
    function Types.AbstractFunction(...)
        return error("Unimplemented abstract function", 2)
    end
end

do
    local descKey = {} ---@type Sentinel

    do
        local type = type

        ---@public
        ---@param v any
        ---@return TypeGuard<Object>
        ---@nodiscard
        function Types.isObject(v)
            return type(v) == "table" and v[descKey] ~= nil
        end
    end

    ---@type {[Object]:{[string]:true}}
    local superMap = {}

    do
        local _Types = Types

        ---@public
        ---@generic C:Object, S:Object
        ---@param cls C
        ---@param super `S`
        ---@return TypeGuard<S>
        ---@nodiscard
        function Types.isSubclass(cls, super)
            return (cls.__name == super) or (superMap[cls][super] == true)
        end
    end

    do
        local isObject = Types.isObject
        local isSubclass = Types.isSubclass

        ---@public
        ---@generic C:Object
        ---@param v any
        ---@param cls `C`
        ---@return TypeGuard<C>
        ---@nodiscard
        function Types.isInstance(v, cls)
            return isObject(v) and isSubclass(v.cls, cls)
        end
    end

    local new --[=[@[lsp_optimization("delayed_definition")]]=] do
        local cls_mt = {} do
            function cls_mt:__call(...)
                return self:__new(...)
            end

            ---@param cls Object
            ---@param k string
            ---@return any
            ---@nodiscard
            function cls_mt.__index(cls, k)
                if cls == cls.cls then
                    local desc = cls[descKey][k] ---@type Desc.Property

                    if desc ~= nil then
                        return desc:get(cls, cls)
                    end
                end
            end

            do
                local rawset = rawset

                ---@param cls Object
                ---@param k string
                ---@return any
                ---@param v any
                function cls_mt.__newindex(cls, k, v)
                    if cls == cls.cls then
                        local desc = cls[descKey][k] ---@type Desc.Base

                        if desc ~= nil then
                            return desc:set(cls, cls, v)
                        end
                    end
                    return rawset(cls, k, v)
                end
            end

            local format = string.format

            ---@generic C:Object
            ---@param cls C
            ---@return string
            ---@nodiscard
            function cls_mt.__tostring(cls)
                return format("%s: S", cls.__name)
            end
        end

        local Object = {} do
            do
                local setmetatable = setmetatable

                ---@generic C:Object
                ---@param cls C
                ---@param ... any
                ---@return C
                ---@nodiscard
                function Object.__new(cls, ...)
                    return setmetatable({cls=cls}, cls)
                end
            end

            local format = string.format
            local topointer --[=[@type fun(t:table):(string)]=] do
                topointer = function(t) return "ERROR" end
                onGlobalLoad("Tabletools", function(v) topointer = v.topointer end)
            end

            function Object:__tostring()
                return format("%s: %s", self.cls.__name, topointer(self))
            end
        end

        ---@param obj Object
        ---@param k string
        ---@return any
        ---@nodiscard
        local function __index(obj, k)
            local cls = obj.cls ---@type Object
            local desc = cls[descKey][k] ---@type Desc.Property

            if desc == nil then
                return cls[k]
            else
                return desc:get(cls, obj)
            end
        end

        local __newindex --[=[@[lsp_optimization("delayed_definition")]]=] do
            local rawset = rawset

            ---@param obj Object
            ---@param k string
            ---@param v any
            __newindex = function(obj, k, v)
                local cls = obj.cls
                local desc = cls[descKey][k] ---@type Desc.Property

                if desc == nil then
                    return rawset(obj, k, v)
                else
                    return desc:set(cls, obj, v)
                end
            end
        end

        local isInstance = Types.isInstance
        local next = next
        local setmetatable = setmetatable

        ---@generic O:Object, S:Object
        ---@param name `O`
        ---@param super? S
        ---@param namespace table
        ---@return O
        ---@nodiscard
        new = function(name, super, namespace)
            local desc = nil ---@type {[string]:Desc.Base}?

            for k, v in next, namespace do
                if isInstance(v, "Desc.Property") then
                    if not desc then
                        desc = {}
                    end

                    v:update(k, namespace)
                    desc[k] = v
                    namespace[k] = nil
                end
            end

            if super == nil then
                if not desc then
                    desc = {}
                end
                super = Object ---@as Object
                superMap[namespace] = {Object=true}
            else

                local superMapSpecific = {[super.__name]=true}

                superMap[namespace] = superMapSpecific

                for k in next, superMap[super] do
                    superMapSpecific[k] = true
                end

                if desc then
                    for k, v in next, super[descKey] do
                        if desc[k] == nil then
                            desc[k] = v
                        end
                    end
                else
                    desc = super[descKey]
                end
            end

            namespace.cls = namespace
            namespace.super = super
            namespace[descKey] = desc
            namespace.__index = __index
            namespace.__name = name
            namespace.__newindex = __newindex

            for k, v in next, super do
                if namespace[k] == nil then
                    namespace[k] = v
                end
            end

            namespace.__call = namespace.__new

            function namespace.newF(...)
                return namespace:__new(...)
            end



            return setmetatable(namespace, cls_mt)
        end
    end

    rawset(Types, "new",
    ---@public
    ---@generic O:Object, S:Object
    ---@param name `O`
    ---@param super? `S`
    ---@param namespace? table
    ---@return O
    ---@nodiscard
    function(name, super, namespace)
        local _super = nil ---@type Object?

        if super == nil then super = "Object" end

        if super ~= "Object" then
            for s in super:gmatch("[^%.]+") do

                _super = (_super or Types)[s]

            end
        end
        namespace = namespace or {}
        return new(name, _super, namespace) ---@diagnostic disable-line: generic-constraint-mismatch
    end)
end

do
    local types_mt = {} do
        rawset(Types, 1, "Types")

        local ModPath = ModPath

        local CleanUpPath = ToolBox.CleanUpPath
        local concat = table.concat
        local DirectoryExists = File.DirectoryExists ---@as fun(path:string):(boolean)
        local error = error
        local rawget = rawget
        local requireSpecific = requireSpecific
        local setmetatable = setmetatable

        ---@param t Types
        ---@param k string
        types_mt.__index=function(t, k)
            local out
            local prePath = rawget(t, 1) ---@type string

            if DirectoryExists(CleanUpPath(concat({ModPath, "Lua", "SBAI", "Shared", prePath:format("/"), k}, "/"))) then
                out = setmetatable({("%s%s%s"):format(prePath, "%s", k)}, types_mt)
            else
                out = requireSpecific(("SBAI.Shared.%s.%s"):format(prePath:format("."), k))
            end

            if out == nil then
                return error(("Unknown type: %s"):format(("%s%s%s"):format(prePath, ".", k):sub(7)), 2)
            end

            t[k] = out
            return out
        end
    end
    setmetatable(Types, types_mt)
end

return Types