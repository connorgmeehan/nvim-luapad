local D = require("paddynvim.util.debug")
local array = require("paddynvim.util.array")
local vec2 = require('paddynvim.integrations.cpml.lib.vec2')
local bound2 = require('paddynvim.integrations.cpml.lib.bound2')

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
        parent_canvas = canvas,
        ctx = canvas.surface:context(),
        _should_fill = true,
        _fill_color = { 0.5, 0.5, 0.5, 1 },
        _should_stroke = true,
        _stroke_color = { 1, 1, 1, 1 },
        stroke_width = 1,

        prev_commands = {},
        commands = {},
    }, self)

    return instance
end

--- Helper method to push a command to the stack
---@vararg string|number[]
function Context:_push_command(...)
    local cmd = { ... }
    table.insert(self.commands, cmd)
end
--- Helper method to set the current color
---@param color table
function Context:_set_color(color)
    local r, g, b, a = unpack(color)
    if a == nil then
        self:_push_command("rgb", r, g, b)
    else
        self:_push_command("rgba", r, g, b, a)
    end
end

--- Helper method to finalize whatever;s in the current context
function Context:_stroke_or_draw_current()
    if self._should_fill then
        self:_set_color(self._fill_color)
        if self._should_stroke then
            self:_push_command("fill_preserve")
        else
            self:_push_command("fill")
        end
    end
    if self._should_stroke then
        self:_set_color(self._stroke_color)
        self:_push_command("stroke")
    end
end

function Context:background(r, g, b, a)
    local w = self.parent_canvas.width
    local h = self.parent_canvas.height
    self:_push_command("rectangle", 0, 0, w, h)
    self:_set_color({ r, g, b, a })
    self:_push_command("fill")
end

--[[
--  Context Translation / Saving / Restoring APIs
--]]
--- Saves the current transformation context
function Context:save()
    self:_push_command("save")
end
--- Restores the previous transformation context
function Context:restore()
    self:_push_command("restore")
end
--- Translates the context
---@param offset vec2|number
---@param y number?
function Context:translate(offset, y)
    if vec2.is_vec2(offset) then
        self:_push_command("translate", offset.x, offset.y)
    else
        self:_push_command("translate", offset, y)
    end
end
--- Rotates the context
---@param degs number
function Context:rotate(degs)
    self:_push_command("rotate", degs)
end
--- scales the context
---@param offset vec2|number
---@param y number?
function Context:scale(offset, y)
    if vec2.is_vec2(offset) then
        self:_push_command("scale", offset.x, offset.y)
    else
        self:_push_command("scale", offset, y)
    end
end

--- Sets the fill color
---@param r number
---@param g number
---@param b number
---@param a number
function Context:fill_color(r, g, b, a)
    self._fill_color = { r, g, b, a }
end

--- Sets the stroke color
---@param r number
---@param g number
---@param b number
---@param a number
function Context:stroke_color(r, g, b, a)
    self._stroke_color = { r, g, b, a }
end

--[[
--  Shape drawing apis
--]]

--- Draws a rectangle
---@param rect bound2|vec2|number
---@param size vec2|number?
---@param w number?
---@param h number?
function Context:rectangle(rect, size, w, h)
    if bound2.is_bound2(rect) then
        local s = rect:size()
        self:_push_command("rectangle", rect.min.x, rect.min.y, s.x, s.y)
    elseif vec2.is_vec2(rect) and size ~= nil then
        self:_push_command("rectangle", rect.x, rect.y, size.x, size.y)
    else
        self:_push_command("rectangle", rect, size, w, h)
    end
end
--- Draws a cirle
---@param position vec2
---@param radius number
function Context:circle(position, radius)
    self:_push_command("circle", position.x, position.y, radius)
    self:_set_color(self._fill_color)
    self:_push_command("fill_preserve")
end

--- Sets the line width
---@param w number
function Context:line_width(w)
    self._line_width = w
end

--[[
--  Path Drawing APIs
--]]

--- Starts a new path to draw a shape with the path build apis
function Context:start_path()
    self:_push_command("new_path")
end
--- Moves the path to a given point
---@param pos vec2
function Context:move_to(pos)
    self:_push_command("move_to", pos.x, pos.y)
end
--- Draws a line from current point to given point
---@param end_pos vec2
function Context:line_to(end_pos)
    self:_push_command("line_to", end_pos.x, end_pos.y)
end
--- Draws a quadratic curve from current point to endpoint with a single control node.
---@param ctrl1 vec2
---@param end_pos vec2
function Context:quad_to(ctrl1, end_pos)
    self:_push_command("quad_curve_to", ctrl1.x, ctrl1.y, end_pos.x, end_pos.y)
end
--- Draws a quadratic curve from current point to endpoint with a single control node.
---@param ctrl1 vec2
---@param ctrl2 vec2
---@param end_pos vec2
function Context:cubic_to(ctrl1, ctrl2, end_pos)
    self:_push_command("curve_to", ctrl1.x, ctrl1.y, ctrl2.x, ctrl2.y, end_pos.x, end_pos.y)
end
function Context:finish_path()
    self:_push_command("close_path")
    self:_push_command("line_width", self._line_width)
    self:_stroke_or_draw_current()
end

--- Draws a one off line from point A -> B
--- @param start_pos vec2
--- @param end_pos vec2
function Context:line(start_pos, end_pos)
    self:start_path()
    self:move_to(start_pos)
    self:line_to(end_pos)
    self:finish_path()
end

--- Draws a one off arrow from point A -> B
--- @param start_pos vec2
--- @param end_pos vec2
--- @param size number
function Context:arrow(start_pos, end_pos, size)
    size = size or 1
    self:start_path()
    self:move_to(start_pos)
    self:line_to(end_pos)
    local dir = (start_pos - end_pos):normalize()
    local arrow1 = dir:rotate(0.5)
    self:move_to(end_pos)
    self:line_to(end_pos + arrow1 * size)
    local arrow2 = dir:rotate(-0.5)
    self:move_to(end_pos)
    self:line_to(end_pos + arrow2 * size)
    self:finish_path()
end

--- 
---@param pos vec2
---@param text string
function Context:print_text(pos, text)
    self:move_to(pos)
    self:_push_command("show_text", text)
end
--- 
---@param size number
function Context:font_size(size)
    self:_push_command("font_size", size)
end

function Context:has_changes()
    if #self.commands ~= #self.prev_commands then
        return true
    else
        local has_changes = array.array_some(self.commands, function (i, command)
            return not array.array_equals(command, self.prev_commands[i])
        end)
        return has_changes
    end
end

function Context:flush()
    local has_changes = self:has_changes()
    if has_changes then
        D.log(
            "trace",
            ("Context:finish with %s commands - %s "):format(#self.commands, vim.inspect(self.commands))
        )
        local ok, err = pcall(function()
            for i = 1, #self.commands, 1 do
                local cmd = self.commands[i]
                local cmd_str = cmd[1]
                local args_length = #cmd - 1
                local args = { self.ctx }
                for j = 1, args_length, 1 do
                    table.insert(args, cmd[j + 1])
                end
                self.ctx[cmd_str](unpack(args))
            end
        end)
        D.log("trace", "Context:finish() Done!")
        if not ok then
            error("Error while drawing context: " .. vim.inspect(err))
        end
    end
    self.prev_commands = self.commands
    self.commands = {}
    return has_changes
end

function Context:dispose()
    D.log("trace", "Context:dispose() on self")
    self.ctx:free()
end

return Context
