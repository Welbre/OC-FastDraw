---@class V2
local op = {flushs = {}, gcalls = 0}
local error_level = 0
local selected_buff, vir_vram = 0, {}
local fore, back = 1, 1
--A color map that convert a occ (Open-Computers-Color) to a rgb24(8bit per chaneel) equivalent.
--In the Open-Computers Mod the "0xc" and the "0xd" don't have difference, because the color are converted in a pallet
--The OOC color is a combination of 4 blue tones + black, 7 green + black, and 5 red + black
--more the 16 gray tones in a total of (4 + 1)*(7 + 1)*(5 + 1) + 16 = 256, that can be stored in one byte.
local OCC = {}
local red_variants, green_variants, blue_variants = {0, 51, 102, 153, 204, 255}, {0, 36, 73, 109, 146, 182, 219, 255}, {0, 64, 128, 192, 255}
local gray_variants = {0xf, 0x1E, 0x2D, 0x3C, 0x4D, 0x5A, 0x69, 0x78, 0x87, 0x96, 0xA5, 0xB4, 0xC3, 0xD2, 0xE1, 0xF0}
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

    set = function(...) op.gcalls = op.gcalls + 1 return gpu.set(...) end
    setf = function(...) op.gcalls = op.gcalls + 1 return gpu.setForeground(...) end
    setb = function(...) op.gcalls = op.gcalls + 1 return gpu.setBackground(...) end
    get = function(...) op.gcalls = op.gcalls + 1 return gpu.get(...) end
    getf = function(...) op.gcalls = op.gcalls + 1 return gpu.getForeground(...) end
    getb = function(...) op.gcalls = op.gcalls + 1 return gpu.getBackground(...) end
    new = function(...) op.gcalls = op.gcalls + 1 return gpu.allocateBuffer(...) end
    free = function(...) op.gcalls = op.gcalls + 1 return gpu.freeBuffer(...) end
    cp = function(...) op.gcalls = op.gcalls + 1 return gpu.copy(...) end
    bitblt = function(...) op.gcalls = op.gcalls + 1 return gpu.bitblt(...) end
    fill = function(...) op.gcalls = op.gcalls + 1 return gpu.fill(...) end
    setBuff = function(...) op.gcalls = op.gcalls + 1 return gpu.setActiveBuffer(...) end
    getBuff = function(...) op.gcalls = op.gcalls + 1 return gpu.getActiveBuffer(...) end
    getRes = function(...) op.gcalls = op.gcalls + 1 return gpu.getResolution(...) end

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
    vir_vram[index] = require("fdraw.vram").newArray(width, height, function() return {1, 1, string.char(0)} end)
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

local function rgb24_to_occ(rgb24)
    -- Helper function to find the nearest color variant
    local function find_nearest(value, variants)
        local nearest = variants[1]
        local min_diff = math.abs(value - nearest)
        for i = 2, #variants do
            local diff = math.abs(value - variants[i])
            if diff < min_diff then
                nearest = variants[i]
                min_diff = diff
            end
        end
        for index, color in pairs(variants) do
            if color == nearest then return index -1 end
        end
        return nil
    end
    local r = (rgb24 >> 16) & 0xFF -- Red is the high 8 bits
    local g = (rgb24 >> 8) & 0xFF  -- Green is the middle 8 bits
    local b = rgb24 & 0xFF         -- Blue is the low 8 bits

    if (r == g) and (r == b) and (r ~= 0) and (r ~= 0xff) then
        return find_nearest(r, gray_variants) + 1
    else
        -- Otherwise, map to the nearest red, green, and blue variants
        local r_nearest = find_nearest(r, red_variants)
        local g_nearest = find_nearest(g, green_variants)
        local b_nearest = find_nearest(b, blue_variants)
        return (b_nearest + g_nearest*5 + r_nearest * 40) + 1
    end
end

function op.setf(color)
    fore = rgb24_to_occ(color)
    assert(fore ~= 0, "Fore is 0!")
end

function op.setb(color)
    back = rgb24_to_occ(color)
    assert(back ~= 0, "back is 0!")
end

function op.getf()
    return OCC[fore]
end

function op.getb()
    return OCC[back]
end

function op.set(x, y, char)
    vir_vram[selected_buff][x][y] = {fore, back, char}
end

function op.get(x, y)
    return vir_vram[selected_buff][x][y]
end

function op.flush()
    local buffer = getBuff()
    setBuff(selected_buff)
    op.setf(0xffffff)
    op.setb(0)
    local _fore, _back = fore, back
    setf(OCC[_fore]) setb(OCC[_back])
    for x,xv in pairs(vir_vram[selected_buff]) do
        for y, pixel in pairs(xv) do
            local pf, pb = pixel[1], pixel[2]
            if _fore ~= pf then setf(OCC[pf]) _fore = pf end
            if _back ~= pb then setb(OCC[pb]) _back = pb end
            set(x, y, pixel[3])
        end
    end
    setBuff(buffer)
end

--########################################################################################################################
--#################################################    Generate Color Map   ##############################################
--########################################################################################################################
for r, red in pairs(red_variants) do -- 5 red + black
    for g, green in pairs(green_variants) do -- 7 green + black
        for b, blue in pairs(blue_variants) do -- 4 blue + black
            OCC[ (b - 1) + (g - 1) *5 + (r - 1)*40 + 1] = (red << 16) | (green << 8) | blue
        end
    end
end
for i, gray in pairs(gray_variants) do --16 Gray
    OCC[5 * 8 * 6 + i] = (gray << 16) | (gray << 8) | gray
end

return op