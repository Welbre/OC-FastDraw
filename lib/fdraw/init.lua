local init = {
    versions = {default = 0, v2 = 1, v3 = 2, v4 = 3, v5 = 4}
}
local selected = nil

function init.setVersion(version)
    assert(version, "Version can't be null!")
    if selected == version then return end

    --Unload all
    local package = require("package")
    package.loaded["fdraw.versions.default"] = nil
    package.loaded["fdraw.versions.v2"] = nil
    package.loaded["fdraw.versions.v3"] = nil
    package.loaded["fdraw.versions.v4"] = nil
    package.loaded["fdraw.versions.v5"] = nil

    if version == 0 then
        setmetatable(init, {__index = require("fdraw.versions.default")})
    elseif version == 1 then
        setmetatable(init, {__index = require("fdraw.versions.v2")})
    elseif version == 2 then
        setmetatable(init, {__index = require("fdraw.versions.v3")})
    elseif version == 3 then
        setmetatable(init, {__index = require("fdraw.versions.v4")})
    elseif version == 4 then
        setmetatable(init, {__index = require("fdraw.versions.v5")})
    else
        error("Version " .. version .. " not finded!", 1)
    end
    selected = version

    init.bind()
end

init.setVersion(init.versions.default) --Start with the default version.

return init