---@namespace Config

---@class (partial) Option<J:Json>: Base<J>
---@field public cls Option<J>
---@field public super Base<J>
---@field public onSave Event<fun()>
---@field public onSet fun(self, v?:J):(boolean)
---@field protected __new fun<S:Option<J>>(self:S, name:string, default?:J, ...):(S)
---@field protected _serialType string
---@field protected _value J
---@field protected _findOp fun(self, g:fun():(string?)):(Option<J>?)
---@field protected _validate fun(self, v?:any):J
---@field private _default J
Types.Config.Option = Types.new--[=[@<Option<J>, Base<J>>]=]("Config.Option", "Config.Base", {
    onSave = Types.Desc.Constant--[=[@<Base>]=](Types.Event(false, false));
    onSet = Functools.yesMan;
    _validate = Types.AbstractFunction;
})

local ConfigOption = Types.Config.Option

---@nodiscard
function ConfigOption:__new(name, default, ...)
    local obj = ConfigOption.super.__new(self, name, ...) ---@as Option

    obj._default = default
    return obj
end

-- ---@public
-- ---@return Json
-- ---@nodiscard
-- function ConfigOption:flatten()
--     return self.value
-- end

do
    local copy = Tabletools.copy
    local next = next
    local setmetatable = setmetatable

    ---@public
    ---@param t? {[string]:any}
    ---@return Option
    ---@nodiscard
    function ConfigOption:copyWith(t)
        local out = copy(self)

        setmetatable(out, self.cls)

        for k, v in next, t do
            out[k] = v
        end
        return out
    end
end

---@nodiscard
function ConfigOption:get()
    local v = self._value

    if v == nil then
        return self._default
    else
        return v
    end
end

function ConfigOption:set(v)
    v = self:_validate(v)
    if v == self:get() then
        return
    elseif self:onSet(v) == true then
        self._value = v
    end
end

do
    function ConfigOption:_findOp(g)
        if g() == nil then
            return self
        else
            return nil
        end
    end
end

do
    local tostring = tostring

    ---@private
    ---@return string
    ---@nodiscard
    function ConfigOption:__tostring()
        return tostring(self:get())
    end
end

if Net ~= false then
    function ConfigOption:parse(msg)
        return self:set(msg["Read"..self._serialType]())
    end

    function ConfigOption:serialize(msg)
        return msg["Write"..self._serialType](self:get())
    end
end

return Types.Config.Option