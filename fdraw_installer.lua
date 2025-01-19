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
    "/lib/fdraw/test.lua", "/lib/fdraw/init.lua", "/lib/fdraw/geo.lua",
    "/lib/fdraw/version/release.lua", "/lib/fdraw/version/debug.lua",
    "/lib/fdraw/benchmark/draws.lua", "/lib/fdraw/benchmark/init.lua"
}

local gpu = require"component".gpu

require("term").clear()
gpu.setForeground(0xAAAAFF)
if require"filesystem".exists("/lib/fdraw") then
    print("Fdraw detected, starting update!")

    os.execute("rm /lib/fdraw -r")
    gpu.setForeground(0x4e4e78)
    print("/lib/fdraw deleted!")
else
    print("Downloading fdraw lib.")
end

gpu.setForeground(0x4e4e78)

os.execute("mkdir /lib/fdraw")
print("create /lib/fdraw")
os.execute("mkdir /lib/fdraw/version")
print("create /lib/fdraw/version")
os.execute("mkdir /lib/fdraw/benchmark")
print("create /lib/fdraw/benchmark")
for _, file in pairs(file_list) do
    downloadfile(download_link .. file, file)
    print(file .. " conclued!")
end

require("component").gpu.setForeground(0xAAAAFF)
print("Fdraw installed with success!")
