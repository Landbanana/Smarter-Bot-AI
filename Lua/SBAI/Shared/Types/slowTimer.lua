do
    local baseTimer = Timer.__new() ---@type Barotrauma.LuaCsTimer

    local ClassProperty = Types.Desc.ClassProperty

    ---@class SlowTimer: Object
    ---@field cls SlowTimer
    ---@field public baseUpdateRate integer # updates / second
    ---@field public getTime fun():(number)
    ---@field public updateRate integer # updates / second
    ---@field public nextFrame fun(f:fun())
    ---@field package baseTimer Barotrauma.LuaCsTimer
    Types.SlowTimer = Types.new("SlowTimer", "Object", {
        baseTimer = baseTimer;
        baseUpdateRate = Types.Desc.Constant(60);
        nextFrame = baseTimer.NextFrame;
        updateRate = 5;
    })

end

local SlowTimer = Types.SlowTimer

SlowTimer.getTime = os.clock

do
    local select = select
    local unpack = table.unpack
    local Wait = SlowTimer.baseTimer.Wait

    ---@generic P
    ---@param delay integer # seconds
    ---@param f fun(...:P...)
    ---@param ... P
    function SlowTimer.wait(delay, f, ...)
        local n = select("#", ...)

        delay = delay*1000

        if n > 0 then
            local _f = f
            local args = {...}

            function f()
                return _f(unpack(args, 1,n))
            end
        end
        return Wait(f --[=[@as fun()]=], delay)
    end
end

do
    local getTime = SlowTimer.getTime
    local wait = SlowTimer.wait

    ---@param predicate? fun():(true|false|nil)
    ---@param timeout? number|5
    ---@param timestep? integer|1 # seconds
    ---@param f fun()
    ---@param fail fun()
    function SlowTimer.poll(predicate, timeout, timestep, fail, f)
        timeout = (timeout or 5) + getTime()
        timestep = timestep or 1
        local function poller()
            if timeout > getTime() then
                local v = predicate()

                if v == nil then
                    return wait(timestep, poller)
                elseif v then
                    return f()
                else
                    return fail()
                end
            end
        end
        return poller()
    end
end

do
    local updateRate = SlowTimer.updateRate

    onGlobalLoad("Config",
    ---@param Config Config
    function(Config)
        updateRate = Config.data:get("General.GamePerformance.updateRate") ---@as integer
        SlowTimer.updateRate = updateRate
    end)

    function SlowTimer.f_co(yield)
        ::start::
        yield(true)
        for _=1,updateRate do
            yield()
        end
        goto start
    end

    local Update = SlowTimer.baseTimer.Update
    local co = coroutine.wrap(SlowTimer.f_co)

    co(coroutine.yield)

    function SlowTimer.think()
        if co() then
            return Update()
        end
    end
end







Hook.Add("Types.SlowTimer", "think", SlowTimer.think)

return Types.SlowTimer