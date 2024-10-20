---@class V4
local op = {flushs = {}}
local error_level = 0
local selected_buff, vir_tree = 0, {}
local fore, back = 1, 1
--A color map that convert a occ (Open-Computers-Color) to a rgb24(8bit per chaneel) equivalent.
--In the Open-Computers Mod the "0xc" and the "0xd" don't have difference, because the color are converted in a pallet
--The OOC color is a combination of 4 blue tones + black, 7 green + black, and 5 red + black
--more the 16 gray tones in a total of (4 + 1)*(7 + 1)*(5 + 1) + 16 = 256, that can be stored in one byte.
local OCC = {}
local red_variants, green_variants, blue_variants = {0, 51, 102, 153, 204, 255}, {0, 36, 73, 109, 146, 182, 219, 255}, {0, 64, 128, 192, 255}
local gray_variants = {0xf, 0x1E, 0x2D, 0x3C, 0x4D, 0x5A, 0x69, 0x78, 0x87, 0x96, 0xA5, 0xB4, 0xC3, 0xD2, 0xE1, 0xF0}
local set, setf, setb, get, getf, getb, new, free, cp, bitblt, fill, setBuff, getBuff, getRes

local function get_FOREBACK_pipeline(mem)
    local index = ((fore - 1) << 8) | (back - 1)
    local pipeline = mem[index]
    if not pipeline then pipeline = {} mem[index] = pipeline end
    return pipeline
end

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

function op.new(width, height)
    local index, ok = new(width, height)
    try(index, ok, error_level) --Checks if have enoght video memory
    vir_tree[index] = {}
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
    vir_tree[index] = nil
    op.unselect()
    return ok
end

function op.fill(x, y, width, height, char)
    local mem = vir_tree[selected_buff]
    local pixel_tree = get_FOREBACK_pipeline(mem)
    for i = x, width do
        for j = y, height do
            local len = #pixel_tree
            pixel_tree[len + 1] = i
            pixel_tree[len + 2] = j
            pixel_tree[len + 3] = char
        end
    end
end

function op.getRes()
    return getRes(selected_buff)
end


function op.display(x, y, width, height, x0, y0)
    bitblt(0, x or 1, y or 1, width, height, selected_buff, x0 or 1, y0 or 1)
end

local function rgb24_to_occ_index(rgb24)
    local r = (rgb24 >> 16) & 0xFF -- Red is the high 8 bits
    local g = (rgb24 >> 8) & 0xFF  -- Green is the middle 8 bits
    local b = rgb24 & 0xFF         -- Blue is the low 8 bits

    if (r == g) and (r == b) and (r > 0xf) and (r < 0xf0) then
        return math.floor(240 + r * ((256-241) / (0xf0 - 0xf)))
    else
        -- Otherwise, map to the nearest red, green, and blue variants
        local r_nearest = math.floor(r / 51 + 0.5) -- 255 / (red 5) -> 51
        local g_nearest = math.floor(g / 36 + 0.5)
        local b_nearest = math.floor(b / 64 + 0.5)
        return (b_nearest + g_nearest*5 + r_nearest * 40) + 1
    end
end

function op.setf(color)
    fore = rgb24_to_occ_index(color)
    assert(fore ~= 0, "Fore is 0!")
end

function op.setb(color)
    back = rgb24_to_occ_index(color)
    assert(back ~= 0, "back is 0!")
end

function op.getf()
    return OCC[fore]
end

function op.getb()
    return OCC[back]
end

function op.set(x, y, char)
    local pixel_tree = get_FOREBACK_pipeline(vir_tree[selected_buff])
    local len = #pixel_tree
    pixel_tree[len + 1] = x
    pixel_tree[len + 2] = y
    pixel_tree[len + 3] = char
end

function op.setAll(array)
    local pixel_tree = get_FOREBACK_pipeline(vir_tree[selected_buff])
    local len = #pixel_tree
    for _, pixel in pairs(array) do
        pixel_tree[len + 1] = pixel[1]
        pixel_tree[len + 2] = pixel[2]
        pixel_tree[len + 3] = pixel[3]
    end
end

function op.get(x, y) --Need to be implemented
    return nil
end

function op.log()
    local log = io.open("/log.txt", "w")
    assert(log, "Log in nill!")
    for FOREBACK, pipeline in pairs(vir_tree[selected_buff]) do
        local _fore,_back = (FOREBACK >> 8) + 1, (FOREBACK & 0xff) + 1
        log:write(string.format("[%d, %d] OCC(0x%x, 0x%x) -> ", _fore, _back, OCC[_fore], OCC[_back]))
        for k, v in pairs(pipeline) do
            log:write(v, #pipeline == k and "" or ", ")
        end
        log:write("\n")
    end
    for FOREBACK, pipeline in pairs(vir_tree[selected_buff]) do
        local _fore,_back = (FOREBACK >> 8) + 1, (FOREBACK & 0xff) + 1
        log:write(string.format("\9\9SET :: [%d, %d]\n", _fore, _back))
        for i=1, #pipeline, 3 do
            log:write(string.format("(%d, %d, %s) \n", pipeline[i], pipeline[i+1], pipeline[i+2]))
        end
    end
    log:close()
end

function op.flush()
    --op.log()
    local buffer = getBuff()
    setBuff(selected_buff)
    local _fore, _back = fore, back
    setf(OCC[_fore]) setb(OCC[_back])
    for FOREBACK, pipeline in pairs(vir_tree[selected_buff]) do
        local __fore, __back = ((FOREBACK & 0xFF00) >> 8) + 1, (FOREBACK & 0xFF) + 1
        if _fore ~= __fore then setf(OCC[__fore]) _fore = __fore end
        if _back ~= __back then setb(OCC[__back]) _back = __back end
        for i=1, #pipeline, 3 do
            set(pipeline[i], pipeline[i+1], pipeline[i+2])
        end
    end
    vir_tree[selected_buff] = {}
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