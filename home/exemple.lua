---@type V5
local fdraw = require("fdraw")

--fdraw.setVersion(fdraw.versions.v5)

local function new(x,y,w,h, color)
    return {x=x,y=y,w=w, h=h, index = fdraw.new(w, h), color = color}
end

local function dark_color(color, factor)
    local r = (color & 0xff0000) >> 16
    local g = (color & 0xff00) >> 8
    local b = (color & 0xff)
    r = math.floor(r * factor)
    g = math.floor(g * factor)
    b = math.floor(b * factor)
    return (r << 16) | (g << 8) | b
end

local function draw_back(_window)
    local c0 = _window.color
    local c1 = dark_color(c0, 0.6)
    fdraw.setb(c0)
    fdraw.fill(1, 1, _window.w, _window.h, " ") --Fill all screen
    fdraw.setb(c1)
    for x=1, _window.w do fdraw.set(x, 1, " ") end
end

local function draw(window)
    fdraw.select(window.index)
    fdraw.draw(draw_back, window)
    fdraw.flush()
    fdraw.display(window.x, window.y, 160, 50, 1, 1)
end

local window = new(1, 1, 50, 10, 0xff)
local window2 = new(60, 30, 50, 10, 0xff00)
local window3 = new(100, 20, 50, 10, 0xff0000)
local window4 = new(1, 21, 30, 10, 0xaaaaff)
local window5 = new(60, 5, 35, 10, 0xdddd00)

draw(window)
draw(window2)
draw(window3)
draw(window4)
draw(window5)

fdraw.free(window.index)
fdraw.free(window2.index)
fdraw.free(window3.index)
fdraw.free(window4.index)
fdraw.free(window5.index)

require("event").pull("key_down")