local fdraw = require("fdraw").setVersion(2)
local draws = require("fdraw.benchmark.draws")
local computer = require("computer")
local draw_func = {draws.draw0, draws.draw1, draws.draw2, draws.draw3, draws.draw4}

local result = {}

---Bind gcalls
local gcall = 0
local gpu = require("component").gpu
for index, value in pairs(gpu) do
    gpu[index] = function(...) gcall = gcall + 1 return value(...) end
end

-------------------------------------------------------------------------------------------------
------------------------------------------Benchmark set------------------------------------------
-------------------------------------------------------------------------------------------------
local function fdraw_func(result_idx, set, fore, back)
    for i, func in pairs(draw_func) do
        local i_gcall = gcall
        local i_time = computer.uptime()

        func(set, fore, back)

        local delta_time = computer.uptime() - i_time
        local delta_gcall = gcall - i_gcall

        result[result_idx].gcall[i] = delta_gcall
        result[result_idx].time[i] = delta_time
    end
end

-------------------------------------------------------------------------------------------------
------------------------------------------Default Draw-------------------------------------------
-------------------------------------------------------------------------------------------------
table.insert(result, {name = "Raw", gcall = {}, time = {}})
fdraw_func(1, gpu.set, gpu.setForeground, gpu.setBackground)
-------------------------------------------------------------------------------------------------
------------------------------------------Fdraw Draw---------------------------------------------
-------------------------------------------------------------------------------------------------

local function alloc_and_bench(draw)
    local res = {fdraw.gpu.getResolution()}

    fdraw.setVersion(fdraw.version.release)
    table.insert(result, {name = "Release", gcall = {}, time = {}})
    local idx0 = fdraw.new(res[1], res[2])
    fdraw.select(idx0)
    fdraw.draw(draw, fdraw.set, fdraw.setf, fdraw.setb)
    fdraw.flush()
    fdraw.display()
    fdraw.free(idx0)
end

fdraw.setVersion(fdraw.version.debug)
table.insert(result, {name = "debug", gcall = {}, time = {}})
for i, draw in pairs(draws) do
    local i_gcall = gcall
    local i_time = computer.uptime()

    alloc_and_bench(draw)

    local delta_time = computer.uptime() - i_time
    local delta_gcall = gcall - i_gcall

    result[2].gcall[i] = delta_gcall
    result[2].time[i] = delta_time
end

fdraw.setVersion(fdraw.version.release)
table.insert(result, {name = "release", gcall = {}, time = {}})
for i, draw in pairs(draws) do
    local i_gcall = gcall
    local i_time = computer.uptime()

    alloc_and_bench(draw)

    local delta_time = computer.uptime() - i_time
    local delta_gcall = gcall - i_gcall

    result[3].gcall[i] = delta_gcall
    result[3].time[i] = delta_time
end

-------------------------------------------------------------------------------------------------
------------------------------------------Print result-------------------------------------------
-------------------------------------------------------------------------------------------------

for _, res in pairs(result) do
    local gcalls_string = ""
    for _, _gcall in pairs(res.gcall) do
        gcalls_string = gcalls_string .. _gcall .. "\9"
    end
    print(res.name, gcalls_string)
end