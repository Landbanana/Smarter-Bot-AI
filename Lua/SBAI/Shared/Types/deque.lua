---@class Deque<T>: AbstractCollection<T>
---@operator add(any):Deque<T>
---@operator sub(any):Deque<T?>
---@field public cls Deque<T>
---@field public super AbstractCollection<T>
---@field public i integer
---@field public j integer
---@field public isEmpty boolean
---@field public clearF fun(self, f:fun(v:T))
---@field public peek fun(self):(T?)
---@field public peekL fun(self):(T?)
---@field public pop fun(self):(T?)
---@field public popL fun(self):(T?)
---@field public push fun(self, v:T)
---@field public pushL fun(self, v:T)
---@field public [integer] T
---@field protected __new fun<S:Deque<T>>(self:S, ...:any):(S)
---@field package __iterator fun(self):(fun(t:self):(T), self)
---@field package __add fun(self, v:T):(Deque<T>)
---@field package __sub fun(self, v:T):(Deque<T>)
Types.Deque = Types.new--[[@<Deque<T>, AbstractCollection<T>>]]("Deque", "AbstractCollection", {
    i = 1;
    j = 0;
    isEmpty = Types.Desc.TiedConstant(
    ---@param cls Deque
    ---@param obj Deque
    function(self, cls, obj)
        return obj.i > obj.j
    end);
})

local Deque = Types.Deque

function Deque:clear()
    local _i, _j = self.i, self.j

    for i=_i,_j do
        self[i] = nil
    end
    self.i = Deque.i
    self.j = Deque.j
end

function Deque:copy()
    local out, _i, _j = Deque(), self.i, self.j

    for i=_i,_j do
        out[i] = self[i]
    end
    out.i = _i
    out.j = _j
    return out
end

function Deque:clearF(f)
    local _i, _j = self.i, self.j

    for i=_i,_j do
        local v = self[i]

        f(v)
        self[i] = nil
    end
    self.i = Deque.i
    self.j = Deque.j
end

---@nodiscard
function Deque:peek()
    return self[self.j]
end

---@nodiscard
function Deque:peekL()
    return self[self.i]
end

function Deque:pop()
    local j = self.j

    if self.i > j then return nil end

    local out = self[j]

    self[j] = nil
    self.j = j - 1
    return out
end

function Deque:popL()
    local i = self.i

    if i > self.j then return nil end

    local out = self[i]

    self[i] = nil
    self.i = i + 1
    return out
end

function Deque:push(v)
    if v == nil then return end

    local j = self.j + 1

    self.j = j
    self[j] = v
end

function Deque:pushL(v)
    if v == nil then return end

    local i = self.i - 1

    self.i = i
    self[i] = v
end

---@param n integer|1
function Deque:rotate(n)
    if #self < 2 then return end
    for i=1,(n or 1) do
        self:pushL(self:pop())
    end
end

---@param n integer|1
function Deque:rotateL(n)
    if #self < 2 then return end
    for i=1,(n or 1) do
        self:push(self:popL())
    end
end

function Deque:__iterator()
    local i = self.i - 1

    return function(t)
        i = i + 1
        return t[i]
    end, self
end

function Deque:__add(v)
    self:push(v)
    return self
end

function Deque:__sub(v)
    self:pushL(v)
    return self
end

function Deque:__len()
    return self.j - self.i + 1
end

return Types.Deque