local internet = require("component").internet
if not internet then error("Internet card needed to download fdraw lib!") end

local function downloadfile(link, path)
    local e_file, err_msg_e_file = internet.request(link)
    if not e_file then error(err_msg_e_file) end

    local file, err_msg_file = io.open(path, "w")
    if not file then
        e_file.close()
        error(err_msg_file)
    end

    while true do
        local read = e_file.read(math.huge)
        if read then
            file:write(read)
        else
            break
        end
    end
    e_file.close()
    file:close()
end

local download_link = "https://raw.githubusercontent.com/Welbre/OC-FastDraw/refs/heads/master"
local file_list = {
    "/lib/fdraw/vram.lua","/lib/fdraw/test.lua", "/lib/fdraw/init.lua", "/lib/fdraw/geo.lua",
    "/lib/fdraw/versions/default.lua", "/lib/fdraw/versions/v1.lua", "/lib/fdraw/versions/v2.lua", "/lib/fdraw/versions/v3.lua",
    "/lib/fdraw/versions/v4.lua", "/lib/fdraw/versions/v5.lua", "/lib/fdraw/versions/v6.lua",
    "/lib/fdraw/benchmark/draws.lua", "/lib/fdraw/benchmark/init.lua"
}

require("term").clear()
require("component").gpu.setForeground(0xAAAAFF)
print("Downloading fdraw lib.")
require("component").gpu.setForeground(0x32324d)
os.execute("mkdir /lib/fdraw")
print("create /lib/fdraw")
os.execute("mkdir /lib/fdraw/versions")
print("create /lib/fdraw/versions")
os.execute("mkdir /lib/fdraw/benchmark")
print("create /lib/fdraw/benchmark")
for _, file in pairs(file_list) do
    downloadfile(download_link .. file, file)
    print(file .. "conclued!")
end