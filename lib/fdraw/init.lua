---@class Fdraw
local init = {
    version = {release=1, debug=2},
}
---@return FdrawRelease | FdrawDebug
function init.setVersion(version)
    assert(version, "Version can't be null!")

    local package = require("package")

    if version == 1 then --release
        package.loaded["fdraw.version.debug"] = nil
        setmetatable(init, {__index = require("fdraw.version.release")})
    elseif version == 2 then --debug
        package.loaded["fdraw.version.release"] = nil
        setmetatable(init, {__index = require("fdraw.version.debug")})
    else
        error("Version " .. version .. " not finded!", 1)
    end

    init.bind()
    return init
end

return init