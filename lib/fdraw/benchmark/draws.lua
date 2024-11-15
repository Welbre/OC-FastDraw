local res = {require("component").gpu.getResolution()}
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

function draws.draw0(set, setf, setb)
    local rate = {0xff0000 / (res[1] * res[2]), 0xff00 / (res[1] * res[2]), 0xff / (res[1] * res[2])}
    local color = {0 ,0 , 0}
    setf(0)
    for x=1, res[1] do
        setb(color[1] | color[2] | color[3])
        color[1] = math.floor(color[1] + rate[1])
        color[2] = math.floor(color[2] + rate[2])
        color[2] = math.floor(color[2] + rate[2])
        for y=1, res[2] do
            set(x, y, "x")
        end
    end
end

function draws.draw1(set, setf, setb)
    setf(0)
    for x=1, res[1] do
        for y=1, res[2] do
            setb(temperatureMap[x][y])
            set(x, y, "x")
        end
    end
end

function draws.draw2(set, setf, setb)
    setf(0)
    for x=1, res[1] do
        for y=1, res[2] do
            setb(back_map[x][y])
            setf(fore_map[x][y])
            set(x, y, char_map[x][y])
        end
    end
end

function draws.draw3(set, setf, setb)
    setf(0)
    setb(0xffcc00)
    geo.drawCircle(set, {res[1] / 2, res[2] / 2}, 25, 3.1415926535 * 2 / 16)
    setb(0xff0000)
    geo.drawCircle(set, {res[1] / 4, res[2] / 2}, 25, 3.1415926535 * 2 / 16)
    for i = 1, 10 do
        geo.draw_color_line(set, setb, {1,i}, {160, i}, 0xff00, 0xff0000)
    end
end

function draws.draw4(set, setf, setb)
    setf(0)
    for x=1, res[1] do
        for y=1, res[2] do
            setb(map3[x][y])
            set(x, y, " ")
        end
    end
end

function draws.draw5(set, setf, setb)
    setf(0)
    geo.draw_color_polygon(set, setb, {{1,1},{160,1},{160,50},{1,50}}, {0xffffff, 0xff00, 0, 0})
end

draws.names = function ()
    return "", "BlueRuid", "SimpleMap", "Random", "Fill", "Colors", "GreenScale"
end

return draws