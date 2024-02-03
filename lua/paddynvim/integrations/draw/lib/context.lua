local D = require('paddynvim.util.debug')

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
        _fill_color = {0.5, 0.5, 0.5, 1},
        _should_stroke = true,
        _stroke_color = {1, 1, 1, 1},
        stroke_width = 1,

        commands = {}
    }, self)

    return instance
end

--- Helper method to push a command to the stack
---@vararg string|number[]
function Context:_push_command(...)
    local cmd = {...}
    D.log("trace", "[DrawIntegration]Context:push_command " .. cmd[1])
    table.insert(self.commands, cmd)
end
--- Helper method to set the current color
---@param color table
function Context:_set_color(color)
    local r,g,b,a = unpack(color)
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

function Context:background(r,g,b,a)
    local w = self.parent_canvas.width
    local h = self.parent_canvas.height
    self:_push_command("rectangle", 0, 0, w, h)
    self:_set_color({r, g, b, a})
    self:_push_command("fill")
end

function Context:fill_color(r, g, b, a)
    self._fill_color = {r, g, b, a}
end
function Context:stroke_color(r, g, b, a)
    self._stroke_color = {r, g, b, a}
end

function Context:fill_rect(x, y, w, h)
    self:_push_command("rectangle", y, x, w, h)
end
function Context:fill_circle(x, y, radius)
    self:_push_command("circle", y, x, radius)
    self:_set_color(self._fill_color)
    self:_push_command("fill_preserve")
end

function Context:line_width(w)
    self._line_width = w
end

function Context:start_path()
	self:_push_command("new_path")
end
function Context:move_to(x, y)
	self:_push_command("move_to", x, y)
end
function Context:line_to(x, y)
    self:_push_command("line_to", x, y)
end
function Context:quad_to(cx, cy, x, y)
    self:_push_command("quad_curve_to", cx, cy, x, y)
end
function Context:cubic_to(c1x, c1y, c2x, c2y, x, y)
    self:_push_command("curve_to", c1x, c1y, c2x, c2y, x, y)
end
function Context:finish_path()
    self:_push_command("close_path")
    self:_push_command("line_width", self._line_width)
    self:_stroke_or_draw_current()
end

function Context:finish()
    D.log("trace", ("[DrawIntegration]Context:finish with %s commands - %s " ):format(#self.commands, vim.inspect(self.commands)))
    local ok, err = pcall(function ()
        for i=1,#self.commands,1 do
            local cmd = self.commands[i]
            local cmd_str = cmd[1]
            local args_length = #cmd - 1
            local args = {self.ctx}
            for j=1,args_length,1 do
                table.insert(args, cmd[j+1])
            end
            self.ctx[cmd_str](unpack(args))
        end
    end)
    self.commands = {}
    D.log("trace", ("[DrawIntegration]Context:finish done!" ):format())
    if not ok then
        error("Error while drawing context: " .. vim.inspect(err))
    end
end

function Context:dispose()
    self.ctx:free()
end

return Context
