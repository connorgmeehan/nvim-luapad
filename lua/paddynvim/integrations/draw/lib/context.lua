
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
        ctx = canvas.surface:context(),
        stroke_color = '#000',
        stroke_width = 1,

        command_index = 1,
        commands = {}
    }, self)

    return instance
end

--- 
---@vararg any
function Context:push_command(cmd)
    self.commands[self.command_index] = cmd
    self.command_index = self.command_index + 1
end

function Context:stroke(w, r, g, b, a)
    self:push_command({ "rgba", r, g, b, a })
    self:push_command({ "stroke_width", w})
    self:push_command({ "stroke" })
end

function Context:fill(r, g, b, a)
    self:push_command({ "rgba", r, g, b, a })
    self:push_command({ "fill" })
end

function Context:rectangle(x, y, w, h)
    self:push_command({ "rectangle", x, y, w, h })
end

function Context:stroke_color(color)
    self:push_command({ "stroke_color", color })
end

function Context:line(x1, y1, x2, y2)
    self:push_command({ "line", x1, y1, x2, y2 })
end

function Context:flush()
    for _, cmd in ipairs(self.commands) do
        local cmd_str, a1, a2, a3, a4, a5, a6, a7, a8 = table.unpack(cmd)
        self.ctx[cmd_str](self.ctx, a1, a2, a3, a4, a5, a6, a7, a8)
    end
end

function Context:dispose()
    -- self.ctx:free()
end

return Context
