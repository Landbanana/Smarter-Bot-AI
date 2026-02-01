---@class Debugtools
local Debugtools = {}

--- ============================================================================================================
---
---                                     https://stackoverflow.com/a/72370663
---
--- ============================================================================================================

do
    local autoMt1 ---@[lsp_optimization("delayed_definition")]

    onGlobalLoad("Tabletools",
    ---@param v Tabletools
    function(v)
        autoMt1 = v.autoMt1
    end)

    local totMt = {__index=function(...) return 0 end}

    local center = Stringtools.center
    local clock = os.clock
    local concat = table.concat
    local formatFloat = Stringtools.formatFloat
    local ipairs = ipairs

    local next = next
    local print = print

    local select = select
    local setmetatable = setmetatable
    local tostring = tostring
    local type = type
    local upper = string.upper


    ---@param m? integer 10
    ---@param n? integer 100
    ---@param f1 fun()
    ---@param ... (fun())...
    function Debugtools.Benchmark(n, m, f1, ...)
        if m == nil then m = 10 end
        if n == nil then n = 100 end


        local tab2 = ("‖color:0,0,0,0‖____‖end‖")
        local fs = {f1, ...}
        local rowNames = {} ---@type table<integer, string>
        local rN = 0
        local data = setmetatable({}, autoMt1)


        for j=1,m do
            local dataJ = data[j] ---@type table

            rN = rN + 1
            rowNames[rN] = tostring(j)

            for id, f in ipairs(fs) do
                local t1, t2, dt ---@type number, number, number

                t1 = clock()
                for _=1,n do
                    f()
                end
                t2 = clock()
                dt = t2 - t1
                dataJ[id] = dt
            end
        end

        for id, f in ipairs(fs) do
            local tot = 0.0

            for j=1,m do
                tot = tot + data[j][id]
            end
            data[m + 1][id] = tot
            data[m + 2][id] = tot/m
        end

        rowNames[m + 1] = "∑"
        rowNames[m + 2] = "μ"



        -- data[m + 1] = tot
        -- rowNames[m + 1] = "tot"
        -- data[m + 2]= avg
        -- rowNames[m + 2] = "avg"



        for j, dataJ in ipairs(data) do
            local dataS = {"["..center(rowNames[j], 3, "%s").."]"}
            local k = 1
            for v in dataJ do
                k = k + 1
                dataS[k] = formatFloat(v, 3)
            end
            data[j] = concat(dataS, tab2)
        end
        return concat(data, "\n")


        -- local dataS = {"-<|><|>-"..tab2..(("\[F%u\]"):rep(fNum, tab2))}

        -- local rowTemplate
        -- for id=1,fNum do
        --     dataS[j + 1] = ("[%s]"):format(center(j, 8, "%u"))..(("%s[%s]"):format(tab2, center(dataF[j], 8, "%g"))):rep(fNum).."\n"
        --     ("]%s["):format(tab2)

        -- end



        -- for id, fOut in ipairs(data) do
        --    -- "-<|><|>-"        [   F%u   ]        [   F1   ]--[    1    ]   _______  _______
        -- end

    end
end

if CSActive then




    do
        local DoWithTempRegistrations = LuaUserData.DoWithTempRegistrations
        local GetType = LuaUserData.GetType
        local print = print

        ---@param className string
        ---@return string[]
        local function inner(className)
            for v in GetType(className).GetMethods(4 + 8 + 16 + 32) do
                local name = v.Name --[[@type string]]

                print(name)
            end
        end

        ---@param className string
        function Debugtools.PrintAllMethodNames(className)
            return DoWithTempRegistrations({
                "System.Type",
                "System.Reflection.RuntimeMethodInfo"
            }, inner, className)
        end
    end

    do
        local DoWithTempRegistrations = LuaUserData.DoWithTempRegistrations
        local GetType = LuaUserData.GetType
        local print = print

        ---@param className string
        ---@return string[]
        local function inner(className)
            for v in GetType(className).GetFields(4 + 8 + 16 + 32) do
                local name = v.Name --[[@type string]]

                print(name)
            end
        end

        ---@param className string
        function Debugtools.PrintAllFieldNames(className)
            return DoWithTempRegistrations({
                "System.Type",
                "System.Reflection.RuntimeFieldInfo"
            }, inner, className)
        end
    end

    do
        local DoWithTempRegistrations = LuaUserData.DoWithTempRegistrations
        local GetType = LuaUserData.GetType
        local next = next

        ---@param className string
        ---@param mainFuncName string
        ---@param nestedFuncName string
        ---@return string?
        local function inner(className, mainFuncName, nestedFuncName)
            local pattern = "<"..mainFuncName..">g__"..nestedFuncName.."|"

            for k, v in next, GetType(className).GetMethods(4 + 8 + 16 + 32) do
                local name = v.Name --[[@type string]]

                if name:match(pattern) then
                    return name
                end
            end
        end

        ---@param className string
        ---@param mainFuncName string
        ---@param nestedFuncName string
        ---@return string?
        function Debugtools.GetNestedMethodName(className, mainFuncName, nestedFuncName)
            return DoWithTempRegistrations({
                "System.Type",
                "System.Reflection.RuntimeMethodInfo"
            }, inner, className, mainFuncName, nestedFuncName)
        end
    end

    do
        local GetNestedMethodName = Debugtools.GetNestedMethodName

        ---@param className string
        ---@param mainFuncName string
        ---@param nestedFuncName string
        ---@param default string
        ---@return string
        function Debugtools.CheckNestedMethodName(className, mainFuncName, nestedFuncName, default)
            return GetNestedMethodName(className, mainFuncName, nestedFuncName) or default
        end
    end




    -- ENV_OLD.LuaUserData.RegisterType("System.Type")
    -- ENV_OLD.LuaUserData.RegisterType("System.Reflection.RuntimeMethodInfo")
    -- ENV_OLD.LuaUserData.RegisterType("Barotrauma.TabMenu")
    -- ENV_OLD.LuaUserData.RegisterType("System.Reflection.RuntimeCustomAttributeData")
    -- ENV_OLD.LuaUserData.RegisterType("System.Runtime.CompilerServices.CompilerGeneratedAttribute")
    -- local CompilerGeneratedAttribute = ENV_OLD.LuaUserData.CreateStatic("System.Runtime.CompilerServices.CompilerGeneratedAttribute")
    -- ENV_OLD.LuaUserData.MakeFieldAccessible(Descriptors["Barotrauma.GameSession"], "tabMenu")

    -- for subType in _type.GetNestedTypes(32) do
    --     local isCompilerGenerated = false
    --     for att in subType.CustomAttributes do
    --         if att.AttributeType == CompilerGeneratedAttribute then
    --             isCompilerGenerated = true
    --             break
    --         end
    --     end
    --     if isCompilerGenerated then
    --         for m in subType.GetMethods(4 + 32) do
    --             if m.ReturnType.FullName == "Barotrauma.GUIButton" then
    --                 print(subType.FullName, m.Name)
    --                 LuaUserData.RegisterType(subType.FullName)
    --                 LuaUserData.AccessMethod(subType.FullName, m.Name)
    --                 Hook.Patch("TESTLOCAL", subType.FullName, m.Name, nil, "Before",
    --                 function(instance, ptable)
    --                     print(ptable["textTag"])
    --                 end)
    --             end
    --         end
    --     end
    -- end

    -- LuaUserData.RegisterType("Barotrauma.TabMenu+<>c__DisplayClass38_0")
    -- LuaUserData.AccessMethod("Barotrauma.TabMenu+<>c__DisplayClass38_0", "<CreateInfoFrame>g__createTabButton|0")

    -- local InfoFrameTab = LuaUserData.CreateEnum("Barotrauma.TabMenu+InfoFrameTab")
    -- local NestedClass = LuaUserData.CreateStatic("Barotrauma.TabMenu+<>c__DisplayClass38_0")

    -- local function doCapF()
    --     local instance = NestedClass()

    --     print(instance)
    --     print(InfoFrameTab.Crew)
    --     print(instance, "SS")
    --     instance["<CreateInfoFrame>g__createTabButton|0"](InfoFrameTab.Crew, "crew")
    -- end



    -- Hook.Patch("TESTLOCAL", "Barotrauma.TabMenu+<>c__DisplayClass38_0", "<CreateInfoFrame>g__createTabButton|0", nil, "Before",
    -- function(instance, ptable)
    --     ptable.PreventExecution = true

    --     Timer.NextFrame(doCapF)
    --     --Hook.RemovePatch("TESTLOCAL", "Barotrauma.TabMenu+<>c__DisplayClass38_0", "<CreateInfoFrame>g__createTabButton|0", nil, "Before")

    -- end)
end

--[[ local performanceCounter = PerformanceCounter.__new() ---@type Barotrauma.LuaCsPerformanceCounter
local create, resume, yield = coroutine.create, coroutine.resume, coroutine.yield
local print, random = print, math.random
local function f_co(i) yield(i)  return i end
performanceCounter.EnablePerformanceCounter = true
local function f(n)
    local collected_co = {}
    local m1, m2
    local i = 1
    local _

    m1 =  performanceCounter.get_MemoryUsage()
    while i < n do
        local co = create(f_co)

        collected_co[i] = co
        _, i = resume(co, i + 1)
    end
    m2 = performanceCounter.get_MemoryUsage()

    resume(collected_co[random(1,i - 1)])

    local s = ("Created/Ran %u Additional Coroutines\n\nBefore: %u MB\nAfter: %u MB\n%u - %u = %i MB"):format((i), (m1), (m2), (m1), (m2), (m2 - m1))
    print(s)
    print(("-"):rep(40))

    return collected_co[random(1,i - 1)]
end

for i=100,1000,100 do
    f(i)
end
performanceCounter.EnablePerformanceCounter = false ]]

return Debugtools