local ffi = require('ffi')
local D = require('paddynvim.util.debug')
local Context = require "paddynvim.integrations.draw.lib.context"
local retained_utils = require "paddynvim.util.retained"
local coordinates    = require "paddynvim.util.coordinates"
local kitty          = require "paddynvim.util.kitty"
local Image          = require "paddynvim.integrations.draw.lib.new_image"
---@class Canvas
---@field id number
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
    D.log("trace", "[DrawIntegration] Canvas:dispose")
    if self.context then
        self.context:dispose()
    end
    if self.surface then
        self.surface:free()
    end
    if self.image then
        self.image:dispose()
    end
end

function Canvas:display(x, y, cell_w, cell_h)
    if not self.context then
        return
    end
    local changed = self.context:flush()
    D.log("trace", "[DrawIntegration] Canvas:display -> Has changes? %s", changed)

    if self.image == nil then
        changed = true
        D.log("trace", "[DrawIntegration] Canvas:display -> Creating image")
        self.image = Image:from_canvas(self)
    elseif changed then
        D.log("trace", "[DrawIntegration] Canvas:display -> Updating image")
        self.image:update_from_canvas(self)
    end

    self.image.x = x
    self.image.y = y
    self.image.cols = cell_w
    self.image.rows = cell_h
    self.needs_transfer = changed
end

function Canvas:on_post_update()
    D.log("trace", "[DrawIntegration] Canvas:post_update")
    if not self.context or not self.image then
        return
    end

    if self.needs_transfer then
        D.log("trace", "[DrawIntegration] Canvas:post_update -> Transfering image")
        self.needs_transfer = false
        self.image:transfer()
    end
    D.log("trace", "[DrawIntegration] Canvas:post_update -> Drawing image")
    self.image:draw()
end

function Canvas:on_detach()
    self:dispose()
end

return Canvas
