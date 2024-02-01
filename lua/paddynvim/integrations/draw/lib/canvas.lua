local Context = require "paddynvim.integrations.draw.lib.context"
---@class Canvas
---@field width number
---@field height number
---@field surface cairo_surface_t
---@field cairo cairo
---@field ctx Context

local cairo = nil

local Canvas = {}
Canvas.__index = Canvas

function Canvas:new(width, height, cairo_path)
    local instance = setmetatable({
        cairo = require('paddynvim.integrations.draw.cairo.cairo')(cairo_path),
        width = width,
        height = height,
        surface = nil,
        ctx = nil,
    }, self)

    return instance
end

function Canvas:get_context()
    if self.cairo == nil then
    end
    if self.surface == nil then
        local surface = cairo.image_surface('argb32', self.width, self.height)
        self.surface = surface
    end
    if self.ctx == nil then
        self.ctx = Context:new(self)
    end
    return self.ctx
end

return Canvas
