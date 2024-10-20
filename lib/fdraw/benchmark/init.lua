local fdraw = require("fdraw")
local draws = require"fdraw.benchmark.draws"
local computer = require("computer")
local term = require("term")
local doMemory = false

local res = {fdraw.gpu.getResolution()}

local function clear()
    fdraw.gpu.setBackground(0)
    fdraw.gpu.setForeground(0xffffff)
    fdraw.gpu.fill(1,1, 160, 50, " ")
end

local function freeMemory()
    local result = 0
    for i = 1, 20 do
    ---@diagnostic disable-next-line: undefined-field
      result = math.max(result, computer.freeMemory())
      os.sleep(0)
    end
    return result
end

---@type Benchmark[]
local benchs = {}
local preBenchmark = {}
local function newBench(name, allocator, ...)
    local function benchmark(self)
        for _, draw in pairs(self.draws) do
            if preBenchmark[allocator] then preBenchmark[allocator]() end --Do pre benchmark

            local start_mem
            if doMemory then start_mem = freeMemory() end
            local start = os.time()

            if not self.allocator then draw() else self.allocator(draw) end

            table.insert(self.results.cycles, os.time() - start)
            if doMemory then table.insert(self.results.memory, (start_mem - freeMemory()) / 1024) end
            if not doMemory then freeMemory() end
        end
    end
    ---@class Benchmark
    local instance = {mark_name = name, allocator = allocator, draws = {...}, results = {cycles = {}, memory = {}}, benchmark = benchmark}
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

--#############################################################################################
--################################### Plot definitions ########################################
--#############################################################################################

local analysed = {cycles = {}, memory = {}}
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
    for _, v in pairs(list) do table.insert(s_results, string.format("%.2f", v)) end
    return table.unpack(s_results)
end

---@param bench Benchmark
local function printResult(bench, indexer)
    local isTheBestOne = true
    for i, result in pairs(bench.results[indexer]) do
        if math.abs(analysed[indexer][i].best - result) > 0.01 then isTheBestOne = false end
        if not isTheBestOne then break end
    end
    local colors = {isTheBestOne and 0xff00 or 0xffffff}
    for i, data in pairs(analysed[indexer]) do
        table.insert(colors, rgbGradient(data.best, data.worst, bench.results[indexer][i]))
    end
    raw_print_colored(colors, bench.mark_name, converst_results(bench.results[indexer]))
end

local function analyze()
    local keys = {"cycles"}
    if doMemory then table.insert(keys, "memory") end
    for _, indexer in pairs(keys) do
        for i=1, #benchs[1].results[indexer] do
            local this = {best = math.huge, worst = -math.huge, best_name = "", worst_name = ""}
            analysed[indexer][i] = this
            for _, bench in pairs(benchs) do
                local result = bench.results[indexer][i]
                if result < this.best then this.best = result this.best_name = bench.mark_name end --get best
                if result > this.worst then this.worst = result this.worst_name = bench.mark_name end --get worst
                if #bench.mark_name > spacer then spacer = #bench.mark_name + 5 end -- max lenght
            end
        end
    end
end

local function plot(indexer, unity)
    local header = {}
    for _, _ in pairs(analysed[indexer]) do table.insert(header, unity) end
    fdraw.gpu.setForeground(0xffffff)
    raw_print("Name", table.unpack(header))

    for _, bench in pairs(benchs) do
        printResult(bench, indexer)
    end
    raw_print()

    fdraw.gpu.setForeground(0x55ff55)
    local best_to_print = {}
    for draw_i, data in pairs(analysed[indexer]) do best_to_print[draw_i] = data.best end
    raw_print("Best", converst_results(best_to_print))

    fdraw.gpu.setForeground(0xff5555)
    local worst_to_print = {}
    for draw_i, data in pairs(analysed[indexer]) do worst_to_print[draw_i] = data.worst end
    raw_print("Worst", converst_results(worst_to_print))

    term.setCursor(1, line)
end
local function plotData()
    fdraw.gpu.setForeground(0xffffff)
    raw_print(draws.names())
    raw_print("Cycles Benchmark")
    plot("cycles", "Cycles")
    raw_print()
    if doMemory then
        fdraw.gpu.setForeground(0xffffff)
        raw_print("Memory Benchmark")
        plot("memory", "KB")
    end
end
--#############################################################################################
--####################################### Plot benchmark ######################################
--#############################################################################################
analyze()
plotData()

--#############################################################################################
--####################################### Clear requires ######################################
--#############################################################################################
require("package").loaded["fdraw"] = nil
require("package").loaded["fdraw.benchmark"] = nil
require("package").loaded["fdraw.benchmark.draws"] = nil

return