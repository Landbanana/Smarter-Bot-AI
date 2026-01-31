---@class AbstractCollection<T>: Object
---@field public cls AbstractCollection<T>
---@field public isEmpty boolean
---@field public clear fun(self)
---@field public copy fun(self):(self)
---@field public tolist fun(self):(T[])
---@field protected _maxStr integer
---@field protected __iterator fun(self):fun(...:any):(T, any...)
---@field protected __len fun(self):(integer)
Types.AbstractCollection = Types.new--[=[@<AbstractCollection<T>, Object>]=]("AbstractCollection", "Object", {
    isEmpty = Types.Desc.TiedConstant--[=[@as Desc.TiedConstant<AbstractCollection<T>>]=](
    function(self, cls, obj)
            for _ in obj do
                return true
            end
            return false
    end);
    _maxStr = 5;
    clear = Types.AbstractFunction;
    copy = Types.AbstractFunction;
    __iterator = Types.AbstractFunction;
    __len = Types.AbstractFunction;
})

local AbstractCollection = Types.AbstractCollection

---@nodiscard
function AbstractCollection:tolist()
    local out = {}
    local i = 0

    for v in self do
        i = i + 1
        out[i] = v
    end
    return out
end

return Types.AbstractCollection