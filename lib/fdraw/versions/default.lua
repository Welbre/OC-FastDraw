
---@class Fdraw
local op = {flushs = {}, gcalls = 0}
local error_level = 0
local selected_buff, vir_vram = 0, {}
local fore, back = 0xffffff, 0

local set, setf, setb, get, getf, getb, new, free, cp, bitblt, fill, setBuff, getBuff, getRes

local function try(argument, message, level)
    if not argument then error(message, level + 2) end
end

function op.bind(addr)
    local gpu, ok
    if addr == nil then
        gpu, ok = require("component").getPrimary("gpu")
    else
        gpu, ok = require("component").proxy(addr)
    end
    try(gpu, ok, error_level) --Checks for error

    for i,v in pairs(gpu) do
        gpu[i] = function (...)
            op.gcalls = op.gcalls + 1
            return v(...)
        end
    end

    set = gpu.set
    setf = gpu.setForeground
    setb = gpu.setBackground
    get = gpu.get
    getf = gpu.getForeground
    getb = gpu.getBackground
    new = gpu.allocateBuffer
    free = gpu.freeBuffer
    cp = gpu.copy
    bitblt = gpu.bitblt
    fill = gpu.fill
    setBuff = gpu.setActiveBuffer
    getBuff = gpu.getActiveBuffer
    getRes = gpu.getResolution

    op.gpu = gpu
end

function op.getGcall()
    return op.gcalls
end

function op.setGcall(v)
    op.gcalls = v
end

function op.new(width, height)
    local index, ok = new(width, height)
    try(index, ok, error_level) --Checks if have enoght video memory
    vir_vram[index] = require("fdraw.vram").newArray(width, height)
    return index
end

function op.select(index)
    try(index , "Index is null", error_level)
    selected_buff = index
end

function op.draw(f, ...)
    local ok, fail = xpcall(f, function(err) return debug.traceback(err, 2) end, ...)
    if not ok then
        op.unselect() setb(0) setf(0xffffff)
        require("term").clear()
        error(fail)
    end
end

function op.unselect()
    selected_buff = 0
end

function op.free(index)
    try(index, "Index is null", error_level)

    local ok, error = free(index)
    try(ok,  error, error_level)
    vir_vram[index] = nil

    op.unselect()
    return ok
end

function op.setf(value)
    fore = value
end

function op.setb(value)
    back = value
end

function op.getf()
    return fore
end

function op.getb()
    return back
end

function op.set(x, y, char)
    vir_vram[selected_buff][x][y] = {fore, back, char}
end

function op.get(x, y)
    return vir_vram[selected_buff][x][y]
end

function op.fill(x, y, width, height, char)
    local mem = vir_vram[selected_buff]
    for i = x, width do
        for j = y, height do
            mem[i][j] = {fore, back, char}
        end
    end
end

function op.getRes()
    return #vir_vram[selected_buff], #vir_vram[selected_buff][1]
end


function op.display(x, y, width, height, x0, y0)
    bitblt(0, x or 1, y or 1, width, height, selected_buff, x0 or 1, y0 or 1)
end

function op.flush()
    op.flushs.flush1()
end

function op.flushs.flush0()
    local buffer = getBuff()
    setBuff(selected_buff)
    for x,xv in pairs(vir_vram[selected_buff]) do
        for y, pixel in pairs(xv) do
            setf(pixel[1])
            setb(pixel[2])
            set(x , y, pixel[3])
        end
    end
    setBuff(buffer)
end

function op.flushs.flush1()
    local buffer = getBuff()
    setBuff(selected_buff)
    local _fore, _back = fore, back
    setf(fore) setb(back)
    for x,xv in pairs(vir_vram[selected_buff]) do
        for y, pixel in pairs(xv) do
            local pf, pb = pixel[1], pixel[2]
            if _fore ~= pf then setf(pf) _fore = pf end
            if _back ~= pb then setb(pb) _back = pb end
            set(x, y, pixel[3])
        end
    end
    setBuff(buffer)
end

function op.flushs.flush11()
    local function rgb24_to_ocrgb(rgb24) --Converts a rgb24 to a openComputers rgb8 colorFormat
        local gray, r, g, b = 0, (rgb24 & 0xff0000) >> 16, (rgb24 & 0xff00) >> 8, (rgb24 & 0xff)
        if r == g and g == b and r ~= 0 and r ~= 0xff then gray = math.floor(r / 255 * 17 + 0.5) end
        r = math.floor(r / 255 * 5 + 0.5)
        g = math.floor(g / 255 * 7 + 0.5)
        b = math.floor(b / 255 * 4 + 0.5)

        return gray << 9 | r << 6 | g << 3 | b
    end

    local buffer = getBuff()
    setBuff(selected_buff)
    local _fore, _back = rgb24_to_ocrgb(fore), rgb24_to_ocrgb(back)
    setf(fore) setb(back)
    for x,xv in pairs(vir_vram[selected_buff]) do
        for y, pixel in pairs(xv) do
            local pf, pb = pixel[1], pixel[2]
            local ocrgbF, ocrgbB = rgb24_to_ocrgb(pf), rgb24_to_ocrgb(pb)
            if _fore ~= ocrgbF then setf(pf) _fore = ocrgbF end
            if _back ~= ocrgbB then setb(pb) _back = pb end
            set(x, y, pixel[3])
        end
    end
    setBuff(buffer)
end

function op.get_selected_buff()
    return selected_buff
end

return op