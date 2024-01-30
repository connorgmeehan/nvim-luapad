local D = require("paddynvim.util.debug")
local array = require("paddynvim.util.array")

local Preview = require("paddynvim.lib.preview")

local utils = require("paddynvim.lib.utils")

local ns = vim.api.nvim_create_namespace("paddy_namespace")

--- Default integration for paddy nvim, simply evaluates the buffer and
--- displays the output in virtual text or in a floating window.
---@class Evaluator: PaddyIntegration
---@field C PaddyConfig
---@field buf number
---@field active boolean
---@field output table
---@field helper table
---@field context table
local Evaluator = {}
Evaluator.__index = Evaluator

local function single_line(arr)
    local result = {}
    for _, v in ipairs(arr) do
        local str = v:gsub("\n", ""):gsub(" +", " ")
        table.insert(result, str)
    end
    return table.concat(result, ", ")
end

Evaluator.meta = {
    name = "Evaluator",
    constructor = function(config, buffer_id)
        return Evaluator:new(config, buffer_id)
    end,
}

---@param config PaddyConfig
---@param buffer_id number
---@return Evaluator
function Evaluator:new(config, buffer_id)
    D.log("trace", "Evaluator:new(config: " .. vim.inspect(config) .. ", buffer_id: " .. vim.inspect(buffer_id) .. ")")
    assert(buffer_id, "You need to set buf for luapad")

    local attrs = {}
    attrs.C = config
    attrs.context = {}
    attrs.buf = buffer_id
    attrs.statusline = { status = "ok" }
    attrs.active = true
    attrs.output = {}
    attrs.helper = {
        buf = attrs.buf,
    }

    local instance = setmetatable(attrs, Evaluator)
    return instance
end

function Evaluator:set_virtual_text(line, str, color)
    vim.api.nvim_buf_set_extmark(
        self.buf,
        ns,
        line,
        0,
        { virt_text = { { tostring(str), color } } }
    )
end

function Evaluator:update_view()
    if not self.buf then
        return
    end
    if not vim.api.nvim_buf_is_valid(self.buf) then
        return
    end

    for line, arr in pairs(self.output) do
        local res = {}
        for _, v in ipairs(arr) do
            table.insert(res, single_line(v))
        end
        self:set_virtual_text(line - 1, "  " .. table.concat(res, " | "), self.C.print_highlight)
    end
end

function Evaluator:tcall(fun)
    local count_limit = self.C.count_limit < 1000 and 1000 or self.C.count_limit

    local success, result = pcall(function()
        debug.sethook(function()
            error("LuapadTimeoutError")
        end, "", count_limit)
        fun()
    end)

    if not success then
        if result == nil then
            self.statusline.status = "No response"
        elseif result:find("LuapadTimeoutError") then
            self.statusline.status = "timeout"
        else
            self.statusline.status = "error"
            local line, error_msg = utils.parse_error(result)
            self.statusline.msg = ("%s: %s"):format((line or ""), (error_msg or ""))

            if self.C.error_indicator and line then
                self:set_virtual_text(
                    tonumber(line) - 1,
                    "<-- " .. error_msg,
                    self.C.error_highlight
                )
            end
        end
    end

    debug.sethook()
end

function Evaluator:print(...)
    local size = select("#", ...)
    if size == 0 then
        return
    end

    local args = { ... }
    local str = {}

    for i = 1, size do
        table.insert(str, tostring(vim.inspect(args[i])))
    end

    local line = debug.traceback("", 3):match("^.-]:(%d-):")
    if not line then
        return
    end
    line = tonumber(line)

    if not self.output[line] then
        self.output[line] = {}
    end
    table.insert(self.output[line], str)
end

function Evaluator:eval()
    D.log("trace", "Evaluator:eval")

    local context = self.context
    local luapad_print = function(...)
        self:print(...)
    end

    context.luapad = self
    context.p = luapad_print
    context.print = luapad_print
    context._paddy_evaluator = self

    setmetatable(context, { __index = _G })

    self.statusline = { status = "ok" }

    vim.api.nvim_buf_clear_namespace(self.buf, ns, 0, -1)

    self.output = {}

    local code = vim.api.nvim_buf_get_lines(self.buf, 0, -1, {})
    local f, result = loadstring(table.concat(code, "\n"))

    if not f then
        local _, msg = utils.parse_error(result)
        self.statusline.status = "syntax"
        self.statusline.msg = msg
        return
    end

    setfenv(f, context)
    self:tcall(f)
    self:update_view()
end

function Evaluator:close_preview()
    vim.schedule(function()
        if self.preview_win then
            self.preview_win:close()
            self.preview_win = nil
        end
    end)
end

function Evaluator:preview()
    local line = vim.api.nvim_win_get_cursor(0)[1]

    if not self.output[line] then
        return
    end

    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
    vim.api.nvim_buf_set_option(buf, "filetype", "lua")

    if self.preview_win and not self.preview_win:is_valid() then
        self.preview_win:close()
        self.preview_win = nil
    end

    if not self.preview_win then
        self.preview_win = Preview:new(self.C)
    end

    self.preview_win:set_content_from_table(self.output[line])
end

function Evaluator:start()
    self:eval()
end

function Evaluator:finish()
    if vim.api.nvim_buf_is_valid(self.buf) then
        vim.api.nvim_buf_clear_namespace(self.buf, ns, 0, -1)
    end
    self:close_preview()
end

---
---@param paddy_instance PaddyInstance
function Evaluator:on_attach(paddy_instance)
    local context = self.context or vim.deepcopy(self.C.context) or {}
    D.log("trace", "Evaluator:on_attach -> default context " .. vim.inspect(context))
    local integration_context = array.array_reduce(
        paddy_instance.integrations,
        context,
        function(acc, el)
            if el.extra_context then
                return vim.tbl_extend("force", acc, el.extra_context)
            else
                return acc
            end
        end
    )
    self.context = integration_context
    D.log("trace", "Evaluator:on_attach -> Context " .. vim.inspect(self.context))
end

function Evaluator:on_detach()
    self:finish()
end

function Evaluator:on_changed()
    self:eval()
end

function Evaluator:on_cursor_hold(buffer_id)
    if self.C.preview.enabled and buffer_id == self.buf then
        self:preview()
    end
end

function Evaluator:on_paddy_cursor_moved()
    self:close_preview()
end

function Evaluator:on_cursor_moved()
    if self.C.eval_on_move then
        self:eval()
    end
end

return Evaluator
