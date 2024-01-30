--- Integration for the paddymath lib.
--- Vendors a modified version of cpml to provide linear algebra/vector math 
--- primitives
---@class PaddyMath
local PaddyMath = {}
PaddyMath.__index = PaddyMath

PaddyMath.meta = {
    name = "PaddyMath",
    constructor = function ()
        return PaddyMath:new()
    end
}

function PaddyMath:new()
    local fields = {
        extra_context = {
            cpml = {
                bound2 = require('paddymath.cpml.bound2'),
                bound3 = require('paddymath.cpml.bound3'),
                bvh = require('paddymath.cpml.bvh'),
                color = require('paddymath.cpml.color'),
                constants = require('paddymath.cpml.constants'),
                intersect = require('paddymath.cpml.intersect'),
                mat4 = require('paddymath.cpml.mat4'),
                mesh = require('paddymath.cpml.mesh'),
                octree = require('paddymath.cpml.octree'),
                quat = require('paddymath.cpml.quat'),
                simplex = require('paddymath.cpml.simplex'),
                utils = require('paddymath.cpml.utils'),
                vec2 = require('paddymath.cpml.vec2'),
                vec3 = require('paddymath.cpml.vec3'),
            }
        }
    }
    local instance = setmetatable(fields, PaddyMath)
    return instance
end

return PaddyMath

