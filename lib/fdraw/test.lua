local fdraw = require("fdraw").setVersion(2)
local event = require("event")
local geo   = require("fdraw.geo")
fdraw.bind()
local res = {fdraw.gpu.getResolution()}

local function clear()
    fdraw.gpu.setBackground(0)
    fdraw.gpu.setForeground(0xffffff)
    fdraw.gpu.fill(1,1, 160, 50, " ")
end

clear()

local function f(color, set, back)
    geo.draw_color_polygon(set, back, {{1,1},{160, 1},{160,50},{1,50}}, {color, 0, 0, color})
end

local function g(color, set, back)
    geo.draw_color_polygon(set, back, {{1,1},{160, 1},{160,50},{1,50}}, {0xffffff, color, 0, 0})
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
local map = createMap3()
local function h(_, set, back)
    back(0)
    for x=1, res[1] do
        for y=1, res[2] do
            back(map[x][y])
            set(x, y, " ")
        end
    end
end
local function I(color, set, back)
    back(0xffcc00)
    geo.drawCircle(set, {res[1] / 2, res[2] / 2}, 25, 3.1415926535 * 2 / 16)
    back(0xff0000)
    geo.drawCircle(set, {res[1] / 4, res[2] / 2}, 25, 3.1415926535 * 2 / 16)
    for i = 1, 10 do
        geo.draw_color_line(set, back, {1,i}, {160, i}, 0xff00, 0xff0000)
    end
end


local func = f

local function DO(color)
    local reMove = false
    ::top::
    for i=0, 0 do
        fdraw.setVersion(fdraw.version.debug)
        local buffer_index = fdraw.new(res[1], res[2])
        fdraw.select(buffer_index)
        fdraw.draw(func, color, fdraw.set, fdraw.setb)
        fdraw.flush()
        fdraw.display()
        fdraw.free(buffer_index)

        if reMove then
            local id = event.listen("touch", function (a,b,c,d,e,f)
                local char, fore, back = fdraw.gpu.get(c,d)
                print(string.format("0x%x", back))
            end)
            event.pull("key_down")
            event.cancel(id)
        end

        fdraw.setVersion(fdraw.version.release)
        local buffer_index = fdraw.new(res[1], res[2])
        fdraw.select(buffer_index)
        fdraw.gpu.setActiveBuffer(buffer_index)
        fdraw.draw(func, color, fdraw.gpu.set, fdraw.gpu.setBackground)
        fdraw.gpu.setActiveBuffer(0)
        --fdraw.flush()
        fdraw.display()
        fdraw.free(buffer_index)

        local id = event.listen("touch", function (a,b,c,d,e,f)
            local char, fore, back = fdraw.gpu.get(c,d)
            print(string.format("0x%x", back))
        end)

        local _,_,char, code = event.pull("key_down")
        if code == require("keyboard").keys.left then
            event.cancel(id)
            reMove = true
            goto top
        end
        event.cancel(id)
        clear()
    end

    require("package").loaded["fdraw"] = nil
    require("package").loaded["fdraw.test"] = nil
end

local function try(fff, ...)
    local error_cal = function(err) return debug.traceback(err, 2) end
    local ok, err = xpcall(fff, error_cal, ...)
    if not ok then fdraw.gpu.setActiveBuffer(0) clear() require("term").clear() error(err, 0) end
end
--goto head
try(DO, 0xff0000)
try(DO, 0xff00)
try(DO, 0xff)
try(DO, 0xffffff)

func = g
try(DO, 0xff0000)
try(DO, 0xff00)
try(DO, 0xff)
try(DO, 0xffffff)

func = h
try(DO, 0xff0000)

::head::
func = I
try(DO, 0xff)

return