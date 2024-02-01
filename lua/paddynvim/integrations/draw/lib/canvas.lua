local Context = require "paddynvim.integrations.draw.lib.context"
---@class Canvas
---@field width number
---@field height number
---@field surface any
---@field ctx Context

local Canvas = {}
Canvas.__index = Canvas

function Canvas:new(width, height)
    local instance = setmetatable({
        width = width,
        height = height,
    }, self)

    return instance
end

function Canvas:get_context()
    if self.ctx == nil then
        self.ctx = Context:new(self)
    end
    return self.ctx
end

function Canvas:get_surface()
    if self.surface == nil then
        self.surface = require(modname)
    end
end

return Canvas
