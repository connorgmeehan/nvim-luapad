
---@class Context
---@field canvas Canvas
---@field stroke_color string
---@field stroke_width number
--
---@field command_index number
---@field commands any[]

local Context = {}
Context.__index = Context

--- 
---@param canvas Canvas
---@return Context
function Context:new(canvas)
    local instance = setmetatable({
        surface = canvas.surface,
        ctx = canvas.cairo,
        stroke_color = '#000',
        stroke_width = 1,

        command_index = 1,
        commands = {}
    }, self)

    return instance
end

function Context:push_command(...)
    self.commands[self.command_index] = {...}
    self.command_index = self.command_index + 1
end

function Context:stroke_color(color)
    self:push_command("stroke_color", color)
end

function Context:line(x1, y1, x2, y2)
    self:push_command("line", x1, y1, x2, y2)
end

function Context:flush()
    local cairo = require('paddynvim.integrations.draw.cairo.cairo')('')
    cairo.image_surface('argb32', self.width, self.height)
end

return Context
