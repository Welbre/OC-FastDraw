local fdraw = require("fdraw")
local draws = require("fdraw.benchmark.draws")
local term = require("term")
local computer = require("computer")

local res = {fdraw.gpu.getResolution()}

local function clear()
    fdraw.gpu.setBackground(0)
    fdraw.gpu.setForeground(0xffffff)
    fdraw.gpu.fill(1,1, res[1], res[2], " ")
end

---@type Benchmark[]
local benchs = {}
local function newBench(name, allocator, ...)
    ---@param self Benchmark
    local function benchmark(self)
        for _, draw in pairs(self.draws) do
            fdraw.setGcall(0)
            local inicial = computer.uptime()

            if not self.allocator then draw() else self.allocator(draw) end

            table.insert(self.results_gcall, fdraw.getGcall())
            table.insert(self.results_time, (computer.uptime() - inicial) * 1000)
        end
    end
    ---@class Benchmark
    local instance = {mark_name = name, allocator = allocator, draws = {...}, results_gcall = {}, results_time = {}, benchmark = benchmark}
    table.insert(benchs, instance)

    local ok, err = xpcall(benchmark, function(_err) return debug.traceback(_err,2) end, instance)
    if not ok then fdraw.gpu.setActiveBuffer(0) clear() term.clear() error(err, 0) end
end

local function asBufferDraw(flush_version)
    return function (draw_func)
        local index = fdraw.new(res[1], res[2])
        fdraw.select(index)
        fdraw.draw(draw_func) --draw operation
        flush_version() -- use a specific version of flush
        fdraw.display()
        fdraw.free(index)
    end
end

--#############################################################################################
--################################### Create all benchmarks ###################################
--#############################################################################################
fdraw.setVersion(fdraw.versions.default)
newBench("Raw", nil, draws.raw_draw0, draws.raw_draw1, draws.raw_draw2, draws.raw_draw3, draws.raw_draw4, draws.raw_draw5)
newBench("Default", asBufferDraw(fdraw.flushs.flush0), draws.draw0, draws.draw1, draws.draw2, draws.draw3, draws.draw4, draws.draw5)
newBench("DefaultV1", asBufferDraw(fdraw.flushs.flush1), draws.draw0, draws.draw1, draws.draw2, draws.draw3, draws.draw4, draws.draw5)
newBench("DefaultV1.1", asBufferDraw(fdraw.flushs.flush11), draws.draw0, draws.draw1, draws.draw2, draws.draw3, draws.draw4, draws.draw5)
fdraw.setVersion(fdraw.versions.v2)
newBench("V2", asBufferDraw(fdraw.flush), draws.draw0, draws.draw1, draws.draw2, draws.draw3, draws.draw4, draws.draw5)
fdraw.setVersion(fdraw.versions.v3)
newBench("V3", asBufferDraw(fdraw.flush), draws.draw0, draws.draw1, draws.draw2, draws.draw3, draws.draw4, draws.draw5)
fdraw.setVersion(fdraw.versions.v4)
newBench("V4", asBufferDraw(fdraw.flush), draws.draw0, draws.draw1, draws.draw2, draws.draw3, draws.draw4, draws.draw5)
fdraw.setVersion(fdraw.versions.v5)
newBench("V5", asBufferDraw(fdraw.flush), draws.draw0, draws.draw1, draws.draw2, draws.draw3, draws.draw4, draws.draw5)
fdraw.setVersion(fdraw.versions.v6)
newBench("V6", asBufferDraw(fdraw.flush), draws.draw0, draws.draw1, draws.draw2, draws.draw3, draws.draw4, draws.draw5)

--#############################################################################################
--################################### Plot definitions ########################################
--#############################################################################################

local gcall_analysed = {}
local time_analysed = {}
local line = 1
local spacer = 12
local back_line = {0xf0f0f, 0x1e1e1e}
local function raw_print(...)
    local args = {...}
    local c = 1
    fdraw.gpu.setBackground(line % 2 == 0 and back_line[1] or back_line[2]) fdraw.gpu.fill(1, line, res[1], 1, " ")
    for _,v in pairs((args)) do
        fdraw.gpu.set(c, line, v)
        c = c + spacer
    end
    line = line + 1
end
local function raw_print_colored(colors, ...)
    local args = {...}
    local acutal = fdraw.gpu.getForeground()
    local c = 1
    fdraw.gpu.setBackground(line % 2 == 0 and back_line[1] or back_line[2]) fdraw.gpu.fill(1, line, res[1], 1, " ")
    for i,v in pairs((args)) do
        fdraw.gpu.setForeground(colors[i])
        fdraw.gpu.set(c, line, v)
        c = c + spacer
    end
    line = line + 1
    fdraw.gpu.setForeground(acutal)
end

local function rgbGradient(minValue, maxValue, value)
    if (minValue == maxValue) then return 0x7f7f00 end
    -- Ensure the value is clamped between minValue and maxValue
    value = math.max(minValue, math.min(maxValue, value))

    -- Normalize the value to a range between 0 and 1
    local normalizedValue = (value - minValue) / (maxValue - minValue)

    -- Interpolate between red (0xFF0000) and green (0x00FF00)
    local r = math.floor(255 * (normalizedValue))  -- Red decreases as value increases
    local g = math.floor(255 * (1 - normalizedValue))       -- Green increases as value increases
    local b = 0                                        -- Blue remains 0 in this gradient

    -- Combine r, g, b into a single hexadecimal value
    return (r << 16) | (g << 8) | b
end

local function converst_results(list)
    local s_results = {}
    for _, v in pairs(list) do
        table.insert(s_results, math.floor(v) == v and string.format("%d", v) or string.format("%.2f", v))
    end
    return table.unpack(s_results)
end

---@param bench Benchmark
local function printGcallResult(bench)
    local isTheBestOne = true
    for i, result in pairs(bench.results_gcall) do
        if math.abs(gcall_analysed[i].best - result) > 0.01 then isTheBestOne = false end
        if not isTheBestOne then break end
    end
    local colors = {isTheBestOne and 0xff00 or 0xffffff}
    for i, data in pairs(gcall_analysed) do
        table.insert(colors, rgbGradient(data.best, data.worst, bench.results_gcall[i]))
    end
    raw_print_colored(colors, bench.mark_name, converst_results(bench.results_gcall))
end
---@param bench Benchmark
local function printTimeResult(bench)
    local isTheBestOne = true
    for i, result in pairs(bench.results_time) do
        if math.abs(time_analysed[i].best - result) > 0.01 then isTheBestOne = false end
        if not isTheBestOne then break end
    end
    local colors = {isTheBestOne and 0xff00 or 0xffffff}
    for i, data in pairs(time_analysed) do
        table.insert(colors, rgbGradient(data.best, data.worst, bench.results_time[i]))
    end
    raw_print_colored(colors, bench.mark_name, converst_results(bench.results_time))
end

local function analyze()
    for i=1, #benchs[1].results_gcall do --analyze gcall
        local this = {best = math.huge, worst = -math.huge, best_name = "", worst_name = ""}
        gcall_analysed[i] = this
        for _, bench in pairs(benchs) do
            local result = bench.results_gcall[i]
            if result < this.best then this.best = result this.best_name = bench.mark_name end --get best
            if result > this.worst then this.worst = result this.worst_name = bench.mark_name end --get worst
            if #bench.mark_name > spacer then spacer = #bench.mark_name + 5 end -- max lenght
        end
    end
    for i=1, #benchs[1].results_time do --analyze time
        local this = {best = math.huge, worst = -math.huge, best_name = "", worst_name = ""}
        time_analysed[i] = this
        for _, bench in pairs(benchs) do
            local result = bench.results_time[i]
            if result < this.best then this.best = result this.best_name = bench.mark_name end --get best
            if result > this.worst then this.worst = result this.worst_name = bench.mark_name end --get worst
            if #bench.mark_name > spacer then spacer = #bench.mark_name + 5 end -- max lenght
        end
    end
end

local function plot(unity, list, printer)
    local header = {}
    for _, _ in pairs(list) do table.insert(header, unity) end
    fdraw.gpu.setForeground(0xffffff)
    raw_print("Name", table.unpack(header))

    for _, bench in pairs(benchs) do
        printer(bench)
    end
    raw_print()

    fdraw.gpu.setForeground(0x55ff55)
    local best_to_print = {}
    for draw_i, data in pairs(list) do best_to_print[draw_i] = data.best end
    raw_print("Best", converst_results(best_to_print))

    fdraw.gpu.setForeground(0xff5555)
    local worst_to_print = {}
    for draw_i, data in pairs(list) do worst_to_print[draw_i] = data.worst end
    raw_print("Worst", converst_results(worst_to_print))

    term.setCursor(1, line)
end
local function plotData()
    fdraw.gpu.setForeground(0xffffff)
    raw_print(draws.names())
    raw_print("Gcalls Benchmark")
    plot("gcall", gcall_analysed, printGcallResult)
    raw_print()

    fdraw.gpu.setForeground(0xffffff)
    raw_print(draws.names())
    raw_print("Time Benchmark")
    plot("ms", time_analysed, printTimeResult)
    raw_print()
end
--#############################################################################################
--####################################### Plot benchmark ######################################
--#############################################################################################
analyze()
plotData()