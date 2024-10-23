local fdraw = require "fdraw"
local res = {fdraw.gpu.getResolution()}
local geo = require"fdraw.geo"
local draws = {}

local function colorMap0(x, y, cx, cy, maxDistance) --chatGpt generated
    -- Calculate the distance from (x, y) to (cx, cy)
    local dx = x - cx
    local dy = y - cy
    local distance = math.sqrt(dx * dx + dy * dy)

    -- Normalize the distance between 0 and 1, where 0 is the center and maxDistance is farthest
    local normalizedDistance = math.min(1, distance / maxDistance)

    -- Interpolate between red (0xFF0000) and blue (0x0000FF)
    local r = math.floor(255 * (1 - normalizedDistance)) -- Red decreases as distance increases
    local g = 0                                          -- Green is constant at 0
    local b = math.floor(255 * normalizedDistance)       -- Blue increases as distance increases

    -- Combine r, g, b into a single hexadecimal value
    return (r << 16) | (g << 8) | b
end

local function createTemperatureMap(sx,sy, cx, cy, maxDistance)
    local map = {}
    for x=1, sx do
        map[x] = {}
        for y=1, sy do
            map[x][y] = colorMap0(x, y, cx, cy, maxDistance)
        end
    end

    return map
end

local function createRandMap(seed, isCharMode)
    math.randomseed(seed)
    local map = {}
    for x=1, res[1] do
        map[x] = {}
        for y=1, res[2] do
            map[x][y] = isCharMode and string.char(math.random(32, 126)) or math.random(0, 0xffffff)
        end
    end
    return map
end

local function createMap3()
    local map = {}
    local slope = 0xffffff / (res[1] * res[2])
    for x=1, res[1] do
        map[x] = {}
        for y=1, res[2] do
            map[x][y] = math.floor(slope * (((x - 1)*res[2]) + y -1))
        end
    end
    return map
end

local temperatureMap = createTemperatureMap(res[1], res[2], res[1] / 2, res[2] / 2, math.min(res[1] / 2, res[2] / 2) * 0.75)
local fore_map = createRandMap(0xff)
local back_map = createRandMap(-2)
local char_map = createRandMap(48622, true)
local map3 = createMap3()


function draws.raw_draw0()
    local rate = {0xff0000 / (res[1] * res[2]), 0xff00 / (res[1] * res[2]), 0xff / (res[1] * res[2])}
    local color = {0 ,0 , 0}
    fdraw.gpu.setForeground(0)
    for x=1, res[1] do
        fdraw.gpu.setBackground(color[1] | color[2] | color[3])
        color[1] = math.floor(color[1] + rate[1])
        color[2] = math.floor(color[2] + rate[2])
        color[2] = math.floor(color[2] + rate[2])
        for y=1, res[2] do
            fdraw.gpu.set(x, y, "x")
        end
    end
end

function draws.raw_draw1()
    fdraw.gpu.setForeground(0)
    for x=1, res[1] do
        for y=1, res[2] do
            fdraw.gpu.setBackground(temperatureMap[x][y])
            fdraw.gpu.set(x, y, "x")
        end
    end
end

function draws.raw_draw2()
    fdraw.gpu.setForeground(0)
    for x=1, res[1] do
        for y=1, res[2] do
            fdraw.gpu.setBackground(back_map[x][y])
            fdraw.gpu.setForeground(fore_map[x][y])
            fdraw.gpu.set(x, y, char_map[x][y])
        end
    end
end

function draws.raw_draw3()
    fdraw.gpu.setForeground(0)
    fdraw.gpu.setBackground(0xffcc00)
    geo.drawCircle(fdraw.gpu.set, {res[1] / 2, res[2] / 2}, 15, 3.1415926535 * 2 / 16)
    fdraw.gpu.setBackground(0xff0000)
    geo.drawCircle(fdraw.gpu.set, {res[1] / 4, res[2] / 2}, 25, 3.1415926535 * 2 / 16)
    for i = 1, 10 do
        geo.draw_color_line(fdraw.gpu.set, fdraw.gpu.setBackground, {1,i}, {160, i}, 0xff00, 0xff0000)
    end
end

function draws.raw_draw4()
    fdraw.gpu.setForeground(0)
    for x=1, res[1] do
        for y=1, res[2] do
            fdraw.gpu.setBackground(map3[x][y])
            fdraw.gpu.set(x, y, " ")
        end
    end
end

function draws.raw_draw5()
    fdraw.gpu.setForeground(0)
    geo.draw_color_polygon(fdraw.gpu.set, fdraw.gpu.setBackground, {{1,1},{160,1},{160,50},{1,50}}, {0xffffff, 0xff00, 0, 0})
end

function draws.draw0()
    local rate = {0xff0000 / (res[1] * res[2]), 0xff00 / (res[1] * res[2]), 0xff / (res[1] * res[2])}
    local color = {0 ,0 , 0}
    fdraw.setf(0)
    for x=1, res[1] do
        fdraw.setb(color[1] | color[2] | color[3])
        color[1] = math.floor(color[1] + rate[1])
        color[2] = math.floor(color[2] + rate[2])
        color[2] = math.floor(color[2] + rate[2])
        for y=1, res[2] do
            fdraw.set(x, y, "x")
        end
    end
end

function draws.draw1()
    fdraw.setf(0)
    for x=1, res[1] do
        for y=1, res[2] do
            fdraw.setb(temperatureMap[x][y])
            fdraw.set(x, y, "x")
        end
    end
end

function draws.draw2()
    fdraw.setf(0)
    for x=1, res[1] do
        for y=1, res[2] do
            fdraw.setb(back_map[x][y])
            fdraw.setf(fore_map[x][y])
            fdraw.set(x, y, char_map[x][y])
        end
    end
end

function draws.draw3()
    fdraw.setf(0)
    fdraw.setb(0xffcc00)
    geo.drawCircle(fdraw.set, {res[1] / 2, res[2] / 2}, 25, 3.1415926535 * 2 / 16)
    fdraw.setb(0xff0000)
    geo.drawCircle(fdraw.set, {res[1] / 4, res[2] / 2}, 25, 3.1415926535 * 2 / 16)
    for i = 1, 10 do
        geo.draw_color_line(fdraw.set, fdraw.setb, {1,i}, {160, i}, 0xff00, 0xff0000)
    end
end

function draws.draw4()
    fdraw.setf(0)
    for x=1, res[1] do
        for y=1, res[2] do
            fdraw.setb(map3[x][y])
            fdraw.set(x, y, " ")
        end
    end
end

function draws.draw5()
    fdraw.gpu.setForeground(0)
    geo.draw_color_polygon(fdraw.set, fdraw.setb, {{1,1},{160,1},{160,50},{1,50}}, {0xffffff, 0xff00, 0, 0})
end

draws.names = function ()
    return "", "BlueRuid", "SimpleMap", "Random", "Fill", "Colors", "GreenScale"
end

return draws