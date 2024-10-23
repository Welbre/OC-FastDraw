---@type V6
local fdraw = require("fdraw")
require("term").clear()

fdraw.setVersion(fdraw.versions.v6)

local tick = 0
local voltage = 25

local function new(x,y,w,h, color, title)
    return {x=x,y=y,w=w, h=h, index = fdraw.new(w, h), color = color, title = title}
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

local function draw_gen(_window)
    local c0 = _window.color
    local c1 = dark_color(c0, 0.75)
    fdraw.setb(c0)
    fdraw.setf(0xffffff)
    fdraw.fill(1, 2, _window.w, _window.h, " ") --Fill all screen
    fdraw.setb(c1)
    fdraw.fill(1, 1, _window.w, 1, " ")
    fdraw.flush()
    fdraw.set(1, 1, _window.title)
    fdraw.flush()
    fdraw.setb(0x88ff88)
    fdraw.set(1, 2, " ")
    fdraw.set(1, 3, " ")
    fdraw.set(1, 4, " ")
    fdraw.setb(c0)
    fdraw.set(2, 2, "Temperature Status")
    fdraw.set(2, 3, "Connection Status")
    fdraw.set(2, 4, "Fuel Status")
    fdraw.flush()
end

local function draw_options(_window)
    local x,y = 1, 1
    fdraw.setb(_window.color)
    fdraw.fill(1, 1, _window.w, _window.h, " ")
    fdraw.flush()
    fdraw.setf(0xffff33)
    fdraw.set(1+x, 1+y, string.format("Voltage: %.1fv / 32v", voltage - (tick / 16)))
    fdraw.setf(0x22ff22)
    fdraw.set(1+x, 2+y, "Current: 0A / 72A")
    fdraw.setf(0x22ff22)
    fdraw.set(1+x, 3+y, "Power: 0Kw / 2.3Kw")
    fdraw.setb(tick % 10 > 5 and 0xff0000 or _window.color)
    fdraw.setf(0xffffff)
    fdraw.set(1+x, 4+y, " ")
    fdraw.setb(0x88ff88)
    fdraw.set(1+x, 5+y, " ")
    fdraw.set(1+x, 6+y, " ")
    fdraw.setb(_window.color)
    fdraw.set(2+x, 4+y, "Relay load")
    fdraw.setf(tick % 10 < 5 and 0xff0000 or _window.color)
    fdraw.set(13+x, 4+y, "ofline")
    fdraw.setf(0xffffff)
    fdraw.set(2+x, 5+y, "Relay unload")
    fdraw.set(2+x, 6+y, "Relay unload backup")
    fdraw.flush()
    fdraw.setb(dark_color(_window.color, 0.75))
    fdraw.fill(1, 1, _window.w, 1, " ")
    fdraw.flush()
    fdraw.setf(0xff0000)
    fdraw.set(25, 1, "X")
    fdraw.setf(0xffff00)
    fdraw.set(23, 1, "-")
    fdraw.setf(0xffffff)
    fdraw.set(1, 1, _window.title)
    fdraw.flush()
end

local function draw_server(_window)
    local c0 = _window.color
    local c1 = dark_color(c0, 0.75)
    fdraw.setb(c0)
    fdraw.setf(0xffffff)
    fdraw.fill(1, 2, _window.w, _window.h, " ") --Fill all screen
    fdraw.setb(c1)
    fdraw.fill(1, 1, _window.w, 1, " ")
    fdraw.flush()
    fdraw.set(1, 1, _window.title)
    fdraw.flush()
    fdraw.setb(0x88ff88)
    fdraw.set(1, 2, " ")
    fdraw.set(1, 3, " ")
    fdraw.setb(tick % 10 > 5 and 0xffff88 or c0)
    fdraw.set(1, 4, " ")
    fdraw.setb(c0)
    fdraw.set(2, 2, "Connection Status")
    fdraw.set(2, 3, "Energy Status")
    fdraw.set(2, 4, "battery Status")
    fdraw.flush()
end

local function draw(window, draw_func)
    fdraw.select(window.index)
    fdraw.draw(draw_func, window)
    fdraw.display(window.x, window.y, 160, 50, 1, 1)
end

local window = new(2, 1, 50, 10, 0x9999ff, "Generator 1")
local window2 = new(60, 30, 50, 10, 0x9999ff, "Generator 2")
local window3 = new(100, 19, 50, 10, 0x9999ff, "Generator 3")
local window4 = new(3, 21, 30, 10, 0xbbbbbb, "Generator server")
local window5 = new(60, 5, 35, 10, 0x9999ff, "Generator backup")
local action = new(18, 24, 25, 8, dark_color(0xbbbbbb, 0.6), "battery Status")

local running = true
require("event").listen("key_down", function () running = false end)

while running do
    draw(window, draw_gen)
    draw(window2, draw_gen)
    draw(window3, draw_gen)
    draw(window4, draw_server)
    draw(window5, draw_gen)
    draw(action, draw_options)
    tick = tick + 1
    os.sleep(0.05)
end

fdraw.free(window.index)
fdraw.free(window2.index)
fdraw.free(window3.index)
fdraw.free(window4.index)
fdraw.free(window5.index)
fdraw.free(action.index)