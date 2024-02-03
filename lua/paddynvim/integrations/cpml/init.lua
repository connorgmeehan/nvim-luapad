local D = require('paddynvim.util.debug')
--- Integration for the cpml lib.
--- Adds linear algebra and vector math primitives.
---
--- Source https://github.com/excessive/cpml Vendored under MIT License.
--- Modified to play nicer with Lua-LS
---
---@class CpmlIntegration
local CpmlIntegration = {}
CpmlIntegration.__index = CpmlIntegration

CpmlIntegration.meta = {
    name = "cpml",
    constructor = function ()
        return CpmlIntegration:new()
    end,
    header = {
        "local cpml = require('paddynvim.integrations.cpml.lib')",
        "local vec2 = cpml.vec2",
        "local p = vec2.new(10, 5)",
        "print(p)"
    }
}

function CpmlIntegration:new()
    D.log("trace", "CpmlIntegration: new()")
    local fields = {
        extra_context = {}
    }
    local instance = setmetatable(fields, CpmlIntegration)
    return instance
end

return CpmlIntegration

