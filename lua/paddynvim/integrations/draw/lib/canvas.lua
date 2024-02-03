local ffi = require('ffi')
local D = require('paddynvim.util.debug')
local Context = require "paddynvim.integrations.draw.lib.context"
local retained_utils = require "paddynvim.util.retained"
local coordinates    = require "paddynvim.util.coordinates"
local kitty          = require "paddynvim.util.kitty"
local Image          = require "paddynvim.integrations.draw.lib.new_image"
---@class Canvas
---@field width number
---@field height number
---@field surface cairo_surface_t
---@field cairo cairo
---@field context Context

local Canvas = {}
Canvas._manager = retained_utils.RetainedManager:new()
Canvas.__index = Canvas

function Canvas:new(width, height)
    local id = Canvas._manager:get_unique_id()
    local buf = vim.api.nvim_get_current_buf()
    local draw_integration = _G.PaddyNvim.utils.get_integration(buf, "draw")
    if draw_integration == nil then
        error("PaddyNvim: Canvas can't get draw integration on buffer " .. vim.inspect(buf) .. ".")
    end
    ---@cast draw_integration DrawIntegration

    local instance = setmetatable({
        draw_integration = draw_integration,
        id = id,
        buffer_line = coordinates.get_eval_buffer_line(1),
        width = width,
        height = height,
        dirty = true, -- Requires transfer
        surface = nil,
        context = nil,
        image = nil, -- Contains the renderable image
    }, self)

    local retained = Canvas._manager:register_or_get_retained(id, instance)
    retained.buffer_line = instance.buffer_line

    return retained
end

function Canvas:retained_equals(other)
    D.log("trace", "[DrawIntegration]Canvas: Comparing retained self with other " .. vim.inspect({ w = self.width, h = self.height}) .. " " .. vim.inspect({ w = other.width, h = other.height}))
    return self.width == other.width and self.height == other.height
end

--- 
---@return 
function Canvas:get_context()
    if self.surface == nil then
        local cairo = self.draw_integration._state.cairo
        local surface = cairo.image_surface('argb32', self.width, self.height)
        self.surface = surface
    end
    if self.context == nil then
        self.context = Context:new(self)
    end
    return self.context
end

function Canvas:as_image()

end

--- Returns a cdata<char *>
---@return ffi.cdata<char *>
function Canvas:pixel_data()
    if self.surface == nil then
        return nil
    end
    local length = self.width * self.height * 4
    local raw_data = ffi.cast("char *", self.surface:data())
    return setmetatable(
        raw_data,
        {__len = function() return length end}
    )
end

--- Gets the PNG data of the canvas. 
---@return string|nil Byte string of the PNG
function Canvas:png_data()
    if self.surface == nil then
        return nil
    end
    local png = {}
    local write_handler = function(closure, data, length)
        local d = ffi.cast("unsigned char *", data)
        local str = ffi.string(d, length)
        table.insert(png, str)
        return 0
    end

    self.surface:save_png(write_handler, nil)
    return table.concat(png)
end

function Canvas:dispose()
    if self.context then
        self.context:dispose()
    end
    if self.image then
        self.image:dispose()
    end
    if self.surface then
        self.surface:free()
    end
end

function Canvas:on_post_update()
    D.log("trace", "[DrawIntegration] Canvas:post_update")
    if not self.context or not self.dirty then
        return
    end

    if not self.image then
        self.image = Image:from_canvas(self)
    else
        self.image:update_from_canvas(self)
    end

    self.image:transfer()
    self.image:draw()
end

return Canvas
