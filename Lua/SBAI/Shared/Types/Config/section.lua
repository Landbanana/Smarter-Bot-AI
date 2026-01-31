---@namespace Config

---@class (partial) Section: Base<Json[]>
---@operator div(Base[]):Section
---@field public cls Section
---@field public super Base<Json[]>
---@field public find fun(self, name:string):(Base)
---@field public flatten fun(self):({[string]:(Json)})
---@field public get fun(self, name:string):(Json)
---@field public set fun(self, v:Json, name:string)
---@field public [integer] string
---@field public [string] Base
---@field protected _find fun(self, g:fun():(string?)):(Base?)
---@field protected _find fun(self, g:nil, name:string):(Base?)
---@field package __iterator fun(self):((fun<J:Json>(t:Json):(Base<J>)), Section)
Types.Config.Section = Types.new("Config.Section", "Config.Base", {
})

local ConfigSection = Types.Config.Section

---@public
---@param name string
---@param ... any
---@return Section
---@nodiscard
function ConfigSection:__new(name, ...)
    return ConfigSection.super.__new(self, name, ...) ---@as Section
end

function ConfigSection:flatten()
    local out = {}

    for c in self --[=[@as fun():(Base)]=] do
        local v = c:get()
        out[c.name] = v
    end
    return out
end

do
    local ferror = ferror

    function ConfigSection:get(name)
        if name == nil then return self:flatten() end

        local out = self:_find(nil, name)
        
        if out == nil then
            return ferror("Unknown config name: %s", 2, name)
        else
            return out:get()
        end
    end
end

do
    local error = error
    local ferror = ferror

    function ConfigSection:set(v, name)
        if name == nil then return error("Cannot direct set Config.Section values", 2) end
        
        local out = self:_find(nil, name)

        if out == nil then
            return ferror("Unknown config name: %s", 2, name)
        else
            return out:set(v)
        end
    end
end

do
    local ferror = ferror

    function ConfigSection:find(name)
        local out = self:_find(nil, name)

        if out == nil then
            return ferror("Unknown config name: %s", 2, name)
        else
            return out
        end
    end
end

do
    local gmatch = string.gmatch
    
    function ConfigSection:_find(g, name)
        g = g or gmatch(name, "[^%.]+")

        local s = g()
        

        if s ~= nil then
            local obj = self[s]
            
            if obj ~= nil then
                return (obj._findOp or obj._find)(obj, g)
            else
                return nil
            end
        else
            return self
        end
    end
end

---@package
---@param t Base[]
---@return Section
---@nodiscard
function ConfigSection:__div(t)
    local m = #self
    local n = #t

    if m > n then
        for i=m,n + 1,-1 do
            local name = self[i]

            self[i] = nil
            self[name] = nil
        end
    end

    for i=1,n do
        local v = t[i]
        local name = v.name

        self[i] = name
        self[name] = v
    end

    return self
end

-- do
--     local isInstance = Types.isInstance

--     function ConfigSection.sortComp(c1, c2)
--         if isInstance(c1, "Config.Option") then
--             if isInstance(c2, "Config.Option") then
--                 return c1.name < c2.name
--             end
--         elseif isInstance(c1, "Config.SectionToggle") then
--             if isInstance(c2, "Config.Option") then
--                 return true
--             elseif isInstance(c2, "Config.SectionToggle") then
--                 return c1.name < c2.name
--             end
--         elseif isInstance(c1, "Config.Section") then
--             if isInstance(c2, "Config.Option") or isInstance(c2, "Config.SectionToggle") then
--                 return true
--             else
--                 return c1.name < c2.name
--             end
--         end
--         return false
--     end
-- end

function ConfigSection:__iterator()
    local i = 0
    
    return function(t)
        i = i + 1
        return t[t[i]]
    end, self
end

if Net ~= false then
    do
        function ConfigSection:parse(msg)
            for c in self --[=[@as fun():(Base)]=] do
                c:parse(msg)
            end
        end
    end

    do
        function ConfigSection:serialize(msg)
            for c in self --[=[@as fun():(Base)]=] do
                c:serialize(msg)
            end
        end
    end
end

do
    local serialize = json.serialize

    ---@private
    ---@return string
    ---@nodiscard
    function ConfigSection:__tostring()
        return serialize(self:flatten())
    end
end

return Types.Config.Section