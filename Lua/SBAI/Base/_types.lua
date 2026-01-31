---@meta types


---@class ENV
ENV = ENV

ENV.OLD = {
    ENV = _ENV,
    require=require,
    Hook=Hook --[=[@as Barotrauma.LuaCsHook]=],
    LuaUserData=LuaUserData ---@as Barotrauma.LuaUserData
}

OLD = ENV.OLD

---@param k string
---@param f fun(v:any)
function onGlobalLoad(k, f) end

---@class Object
---@field public cls Object
---@field public super Object
---@field public __name string
---@field protected __new fun<S:Object>(self:S, ...:any):(S)
---@field package __call fun<S:Object>(self:S, ...:any):(S)
---@field package __desc table<string, Descriptor>
---@field package __index any
---@field package __metatable table<string, Descriptor>
---@field package __newindex any

---@generic O:Object
---@class Types
---@field public [string] O
Types = {}

---@public
---@generic O:Object, S:Object
---@[constructor("__new", "Object")]
---@param name `O`
---@param super? `S`
---@param namespace? table
---@return O
---@nodiscard
Types.new = function(name, super, namespace) end

-- ---@class Types.Config
Types.Config = {}

--- ---@class Types.Desc
Types.Desc = {}

Types.UI = {}

-- ---@class Types.LFBChanges
Types.LFBChanges = {}

---@alias Identity<T> T extends infer P and P or never

---@alias GetParameter<F extends function> std.Select<std.Unpack<Parameters<F> extends infer P and P or never>,2>

---@alias RemoveSelf<S> std.RawGet<std.RawGet<S, "__new"> extends infer F and Parameters<F> or never, 1> extends S and (std.RawGet<S, "__new"> extends fun(self:any, ...:infer P):(any) and P or never) or Parameters<std.RawGet<S, "__new">>

---@alias Constructor<O:Object> (std.RawGet<O, "__new"> extends infer F and F or never)

---@alias ConstructorParameters2<O:Object> Parameters<Constructor<O>>

---@alias ConstructorReturnType<O:Object> ReturnType<Constructor<O>>


---@alias Super<O:Object, S:Object> Replace<S, {__new:fun(self:O, ...:ConstructorParameters2<S>...):(O)}>


-----@class Class<O:Object, S:(Object?)>: {cls:O, super:Super<O,S>} | ({cls:nil, super:nil}&(Object extends (nil extends S and Object or S) and S or Object))

-----@class Class<O:Object, S:(Object?)>: {cls:O, super:Super<O, Object extends (nil extends S and Object or S) and S or Object>} | Replace<Object extends (nil extends S and Object or S) and S or Object, {cls:nil, super:nil}>

---@alias NullDefault<T, D> nil extends T and std.NotNull<D> or std.NotNull<T>

---@alias ParametersNoSelf<f extends function> f extends (fun(self:any, ...: infer P):any) and P or never

---@alias Json {[string]:(Json)}|(Json[])|boolean|number|float|string

---@alias Remove<T, R> T&-Pick<T,R>

---@alias Add<T, A> A&(T + A)

---@alias Replace<T, R> Add<Remove<T, [keyof R]>, R>

---@alias foo<K,V> (fun(tbl: any): (K,V))

---@alias Iterator (fun(tbl: any): (number, integer))

---@alias Iterable<V> Iterator<V>|V[]

---@class Sentinel: {}

---@alias Session
---| `Client`
---| `Server`
---| `Shared`

---@class PackT<T>

---@alias UnpackT<T> {[K in keyof T]: T[K] extends PackT<infer U> and U or unknown}

---@alias ReturnType<T extends function> T extends (fun(...:any):infer R) and R or any

---@alias Pick<T, K extends keyof T> {[P in K]: T[P];}

---@alias ReplaceArg1<F, O, N> F extends fun(var00:O, ...:(infer P)):(infer R) and fun(var00:N, ...:P...):(R...) or F

---@alias ReplaceReturn1<F, O, N> F extends fun(...:(infer P)):(infer R) and fun(...:P...):(ReturnType<fun(...:P...):({[K in keyof R]:K extends 0 and (R[K] extends O and N or R[K]) or R[K];})>) or F


---@generic P
---@param t:P
---@return std.Select<std.Unpack<ConstructorParameters2<Property>>, "#">
local function testN(...)

end


---@alias NotZero<T> 0 extends std.Select<std.Unpack<T>, "#"> and nil or T...