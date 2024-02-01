local Context = require "paddynvim.integrations.draw.lib.context"
---@class Canvas
---@field width number
---@field height number
---@field surface cairo_surface_t
---@field cairo cairo
---@field ctx Context

local Canvas = {}
Canvas.__index = Canvas

function Canvas:new(cairo, width, height)
    local instance = setmetatable({
        cairo = cairo,
        width = width,
        height = height,
        surface = nil,
        ctx = nil,
    }, self)

    return instance
end

function Canvas:get_context()
    if self.surface == nil then
        local surface = self.cairo.image_surface('argb32', self.width, self.height)
        self.surface = surface
    end
    if self.ctx == nil then
        self.ctx = Context:new(self)
    end
    return self.ctx
end

return Canvas
