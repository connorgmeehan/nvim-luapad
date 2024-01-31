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
    end
}

function CpmlIntegration:new()
    local fields = {
        extra_context = {
            cpml = {
                bound2 = require('paddynvim.integrations.cpml.lib.bound2'),
                bound3 = require('paddynvim.integrations.cpml.lib.bound3'),
                bvh = require('paddynvim.integrations.cpml.lib.bvh'),
                color = require('paddynvim.integrations.cpml.lib.color'),
                constants = require('paddynvim.integrations.cpml.lib.constants'),
                intersect = require('paddynvim.integrations.cpml.lib.intersect'),
                mat4 = require('paddynvim.integrations.cpml.lib.mat4'),
                mesh = require('paddynvim.integrations.cpml.lib.mesh'),
                octree = require('paddynvim.integrations.cpml.lib.octree'),
                quat = require('paddynvim.integrations.cpml.lib.quat'),
                simplex = require('paddynvim.integrations.cpml.lib.simplex'),
                utils = require('paddynvim.integrations.cpml.lib.utils'),
                vec2 = require('paddynvim.integrations.cpml.lib.vec2'),
                vec3 = require('paddynvim.integrations.cpml.lib.vec3'),
            }
        }
    }
    local instance = setmetatable(fields, CpmlIntegration)
    return instance
end

return CpmlIntegration

