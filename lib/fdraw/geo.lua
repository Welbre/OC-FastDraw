local geo = {}

function geo.interpolate_color(c0, c1, t)
    local function int_to_rgb(color)
        local r = (color >> 16) & 0xFF
        local g = (color >> 8) & 0xFF
        local b = color & 0xFF
        return r, g, b
    end

    local function rgb_to_int(r, g, b)
        return (r << 16) | (g << 8) | b
    end
    local r0, g0, b0 = int_to_rgb(c0)
    local r1, g1, b1 = int_to_rgb(c1)

    local r = math.floor(r0 + (r1 - r0) * t)
    local g = math.floor(g0 + (g1 - g0) * t)
    local b = math.floor(b0 + (b1 - b0) * t)

    return rgb_to_int(r, g, b)
end

function geo.draw_line(set, p0, p1)
    local x0, y0, x1, y1 = p0[1], p0[2], p1[1],p1[2]
    local dx = math.abs(x1 - x0)
    local dy = math.abs(y1 - y0)
    local sx, sy
    if x0 < x1 then sx = 1 else sx = -1 end
    if y0 < y1 then sy = 1 else sy = -1 end
    local err = dx - dy

    while true do
        set(x0, y0, " ")
        if x0 == x1 and y0 == y1 then break end
        local e2 = 2 * err
        if e2 > -dy then
            err = err - dy
            x0 = x0 + sx
        end
        if e2 < dx then
            err = err + dx
            y0 = y0 + sy
        end
    end
end

function geo.draw_color_line(set, color, p0, p1, c0, c1)
    local x0, y0, x1, y1 = p0[1], p0[2], p1[1], p1[2]
    local dx = math.abs(x1 - x0)
    local dy = math.abs(y1 - y0)
    local sx = x0 < x1 and 1 or -1
    local sy = y0 < y1 and 1 or -1
    local err = dx - dy
    local length = math.sqrt(dx * dx + dy * dy) -- total length of the line
    local step = 0 -- to track position along the line

    while true do
        local t = length == 0 and 0 or step / length -- interpolation factor between 0 and 1
        color(geo.interpolate_color(c0, c1, t))
        set(x0, y0, " ")

        if x0 == x1 and y0 == y1 then break end
        local e2 = 2 * err
        if e2 > -dy then
            err = err - dy
            x0 = x0 + sx
        end
        if e2 < dx then
            err = err + dx
            y0 = y0 + sy
        end

        step = step + 1
    end
end

function geo.draw_polygon(set, ...)
    local polygon = {...}

    for i = 1, #polygon do
        geo.draw_line(set, polygon[i], polygon[i + 1] or polygon[1])
    end

    local minY, maxY = math.huge, -math.huge
    for _, vertex in ipairs(polygon) do
        if vertex[2] < minY then minY = vertex[2] end
        if vertex[2] > maxY then maxY = vertex[2] end
    end

    for y = minY, maxY do
        local intersections = {}
        for i = 1, #polygon do
            local nextIndex = i % #polygon + 1
            local x0, y0 = polygon[i][1], polygon[i][2]
            local x1, y1 = polygon[nextIndex][1], polygon[nextIndex][2]
            if (y0 <= y and y1 > y) or (y1 <= y and y0 > y) then
                local x = (y - y0) * (x1 - x0) / (y1 - y0) + x0
                table.insert(intersections, x)
            end
        end
        table.sort(intersections)
        for i = 1, #intersections - 1, 2 do
            local startX = math.ceil(intersections[i])
            local endX = math.floor(intersections[i + 1])
            for x = startX, endX do
                set(x, y, " ")
            end
        end
    end
end

function geo.draw_color_polygon(set, color, polygon, colors)
    -- Draw edges with color interpolation
    for i = 1, #polygon do
        local p0 = polygon[i]
        local p1 = polygon[i + 1] or polygon[1]
        local c0 = colors[i]
        local c1 = colors[i + 1] or colors[1]
        geo.draw_color_line(set, color, p0, p1, c0, c1)
    end

    -- Scanline fill algorithm with color interpolation
    local minY, maxY = math.huge, -math.huge
    for _, vertex in ipairs(polygon) do
        if vertex[2] < minY then minY = vertex[2] end
        if vertex[2] > maxY then maxY = vertex[2] end
    end

    for y = minY, maxY do
        local intersections = {}
        local colorIntersections = {}

        -- Calculate intersections and interpolate colors for each edge
        for i = 1, #polygon do
            local nextIndex = i % #polygon + 1
            local x0, y0 = polygon[i][1], polygon[i][2]
            local x1, y1 = polygon[nextIndex][1], polygon[nextIndex][2]
            local c0 = colors[i]
            local c1 = colors[nextIndex]

            if (y0 <= y and y1 > y) or (y1 <= y and y0 > y) then
                local t = (y - y0) / (y1 - y0)
                local x = (y - y0) * (x1 - x0) / (y1 - y0) + x0
                local interpolatedColor = geo.interpolate_color(c0, c1, t)
                table.insert(intersections, x)
                table.insert(colorIntersections, interpolatedColor)
            end
        end

        -- Sort intersections and color pairs
        local n = #intersections
        for i = 1, n - 1 do
            for j = i + 1, n do
                if intersections[i] > intersections[j] then
                    intersections[i], intersections[j] = intersections[j], intersections[i]
                    colorIntersections[i], colorIntersections[j] = colorIntersections[j], colorIntersections[i]
                end
            end
        end

        -- Fill between pairs of intersections with interpolated colors
        for i = 1, #intersections - 1, 2 do
            local startX = math.ceil(intersections[i])
            local endX = math.floor(intersections[i + 1])
            local cStart = colorIntersections[i]
            local cEnd = colorIntersections[i + 1]

            for x = startX, endX do
                if endX ~= startX then
                    local t = (x - startX) / (endX - startX)
                    local fillColor = geo.interpolate_color(cStart, cEnd, t)
                    color(fillColor)
                    set(x, y, " ")
                end
            end
        end
    end
end

function geo.drawCircle(set, center, radius, angularStep)
    local cx, cy = center[1], center[2]

    local polygon = {}

    for theta = 0, 2 * math.pi, angularStep do
        table.insert(polygon, {math.floor(0.5 + cx + (math.cos(theta) * radius)),math.floor(0.5 + cy + (math.sin(theta) * radius * 0.63))})
    end

    geo.draw_polygon(set, table.unpack(polygon))
end

return geo