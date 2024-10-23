---@class V6
local op = {flushs = {}}
local error_level = 0
local selected_buff, vir_tree = 0, {}
local fore, back, char = 240, 1, 0
--A color map that convert a occ (Open-Computers-Color) to a rgb24(8bit per chaneel) equivalent.
--In the Open-Computers Mod the "0xc" and the "0xd" don't have difference, because the color are converted in a pallet
--The OOC color is a combination of 4 blue tones + black, 7 green + black, and 5 red + black
--more the 16 gray tones in a total of (4 + 1)*(7 + 1)*(5 + 1) + 16 = 256, that can be stored in one byte.
local OCC = {}
local red_variants, green_variants, blue_variants = {0, 51, 102, 153, 204, 255}, {0, 36, 73, 109, 146, 182, 219, 255}, {0, 64, 128, 192, 255}
local gray_variants = {0xf, 0x1E, 0x2D, 0x3C, 0x4D, 0x5A, 0x69, 0x78, 0x87, 0x96, 0xA5, 0xB4, 0xC3, 0xD2, 0xE1, 0xF0}
local set, setf, setb, get, getf, getb, new, free, cp, bitblt, fill, setBuff, getBuff, getRes

local function get_CharForeBack_pipeline(mem)
    local index = (char << 16) | ((fore - 1) << 8) | (back - 1)
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

function op.fill(x, y, width, height, _char)
    char = string.byte(_char)
    local mem = vir_tree[selected_buff]
    local pixel_tree = get_CharForeBack_pipeline(mem)
    for i = x, width do
        for j = y, height do
            local len = #pixel_tree
            pixel_tree[len + 1] = i
            pixel_tree[len + 2] = j
        end
    end
end

function op.getRes()
    return getRes(selected_buff)
end


function op.display(x, y, width, height, x0, y0)
    bitblt(0, x or 1, y or 1, width, height, selected_buff, x0 or 1, y0 or 1)
end

local function color_distance(r, g, b, r1, g1, b1)
    return (0.2126*((r-r1)^2)) + (0.7152*((g-g1)^2)) + (0.0722*((b-b1)^2))
end

local function rgb24_to_occ_index(rgb24)
    --Fast calculation for saturates values, 0, 0xff, 0xff00, 0xff0000 0xffffff
    if rgb24 == 0 then return 1 elseif rgb24 == 0xff then return 5 elseif rgb24 == 0xff00 then return 36 elseif rgb24 == 0xff0000 then return 201 elseif rgb24 == 0xffffff then return 240 end
    local r = (rgb24 >> 16) & 0xFF -- Red is the high 8 bits
    local g = (rgb24 >> 8) & 0xFF  -- Green is the middle 8 bits
    local b = rgb24 & 0xFF         -- Blue is the low 8 bits

    -- Otherwise, map to the nearest red, green, and blue variants
    local r_nearest = math.floor((r * 0.019607843137) + 0.5)
    local g_nearest = math.floor((g * 0.027450980392) + 0.5)
    local b_nearest = math.floor((b * 0.015686274509) + 0.5)
    local colorIndex = (r_nearest * 40 + g_nearest*5 + b_nearest) + 1
    local rgb_nearest = OCC[colorIndex]
    local grayIndex = math.floor(((0.2116*r + 0.7152*g + 0.0722*b) / 15) + 0.5)

    if grayIndex >= 1 and grayIndex <=16 then
        local gray = gray_variants[grayIndex]
        if color_distance(r, g, b, (rgb_nearest >> 16), (rgb_nearest >> 8) & 0xFF, rgb_nearest & 0xFF) < color_distance(r, g, b, gray, gray, gray) then
            return colorIndex
        else
            return grayIndex + 240
        end
    else
        return colorIndex
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

function op.set(x, y, value)
    local cache = {}
    local mem = vir_tree[selected_buff]
    for i=1, #value do
        local pixel_tree = cache[i]
        if not cache[i] then
            char = string.byte(value, i)
            pixel_tree = get_CharForeBack_pipeline(mem)
            cache[i] = pixel_tree
        end

        local len = #pixel_tree
        pixel_tree[len + 1] = x
        pixel_tree[len + 2] = y
    end
end

function op.setAll(array)
    local buffer = vir_tree[selected_buff]
    local pixel_tree = get_CharForeBack_pipeline(buffer)
    local len = #pixel_tree
    for _, pixel in pairs(array) do
        if pixel[3] ~= char then
            char = pixel[3]
            pixel_tree = get_CharForeBack_pipeline(buffer)
            len = #pixel_tree
        end
        pixel_tree[len + 1] = pixel[1]
        pixel_tree[len + 2] = pixel[2]
    end
end

function op.get(x, y) --Need to be implemented
    return nil
end

local function try_fill(pipeline, i)
    local x, y = pipeline[i], pipeline[i+1]
    if not ((i + 3) <= #pipeline) then return nil, nil, nil, nil, i end -- check if reach the end of pipeline.
    local dirX, dirY = math.abs(pipeline[i+2] -x), math.abs(pipeline[i+3] -y)
    if math.sqrt(dirX ^ 2  + dirY ^ 2) > 1 then return nil, nil, nil, nil, i end --Check the next pixel in the pipeline.
    i = i + 2 -- if reaches this line then the next pixel have been checked, so increment the index to the next one.

    ::continue::
    while (i + 3) <= #pipeline do
        if math.abs(pipeline[i+2]-pipeline[i]) == dirX then --Check if the next one is in the same line that the frist one
            if math.abs(pipeline[i+3]-pipeline[i+1]) == dirY then
                i = i + 2 --if reaches here, the pixel is in the line
                goto continue
            end
        end
        break
    end
    local w, h = math.abs(pipeline[i] - x) + 1, math.abs(pipeline[i+1] - y) + 1
    if pipeline[i] < x then
        x = pipeline[i]
    end
    if pipeline[i+1] < y then
        y = pipeline[i+1]
    end
    return x, y, w, h, i
end

function op.flush()
    local buffer = getBuff()
    setBuff(selected_buff)
    local _fore, _back = fore, back
    setf(OCC[_fore]) setb(OCC[_back])
    for CHARFOREBACK, pipeline in pairs(vir_tree[selected_buff]) do
        local __char, __fore, __back = string.char((CHARFOREBACK & 0xff0000) >> 16) ,((CHARFOREBACK & 0xFF00) >> 8) + 1, (CHARFOREBACK & 0xFF) + 1
        if _fore ~= __fore then setf(OCC[__fore]) _fore = __fore end
        if _back ~= __back then setb(OCC[__back]) _back = __back end
        --Check if the image is too fragmentad, if true, skip the fill check, and only use the set function
        if #vir_tree[selected_buff] > 80 then
            for i=1, #pipeline, 2 do
                set(pipeline[i], pipeline[i+1], __char)
            end
        else
            local i = 1
            while i <= #pipeline do
                local x, y, w, h, _i = try_fill(pipeline, i)
                if x then
                    fill(x, y, w, h, __char)
                else
                    set(pipeline[i], pipeline[i+1], __char)
                end
                i = _i + 2
            end
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