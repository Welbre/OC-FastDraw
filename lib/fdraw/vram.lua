local vram = {}

function vram.newArray(width, height, starter)
    local myArray = {}
    for i = 1, width do
        local internal = {}
        myArray[i] = internal
        for j=1, height do
            internal[j] = starter and starter() or {0, 0, string.char(0)} -- F, G, Char
        end
    end

    return myArray
end

function vram.newTree(width, height, starter)
    local myArray = {}
    for i = 1, width do
        local internal = {}
        myArray[i] = internal
        for j=1, height do
            internal[j] = starter and starter() or {0, 0, string.char(0)} -- F, G, Char
        end
    end

    return myArray
end

return vram