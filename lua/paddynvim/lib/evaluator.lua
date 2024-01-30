local Preview = require('paddynvim.lib.preview')
local array   = require('paddynvim.util.array')
local paddy = _G.PaddyNvim
local C = paddy.config
local S = paddy._state

local utils = require("paddynvim.lib.utils")

local ns = vim.api.nvim_create_namespace("paddy_namespace")

---@class EvaluatorProps
---@field buf number The buffer number

---@class Evaluator: EvaluatorProps
---@field active boolean
---@field output table
---@field helper table
Evaluator = {}
Evaluator.__index = Evaluator

local function single_line(arr)
    local result = {}
    for _, v in ipairs(arr) do
        local str = v:gsub("\n", ""):gsub(" +", " ")
        table.insert(result, str)
    end
    return table.concat(result, ", ")
end

---
---@param attrs EvaluatorProps
---@return Evaluator
function Evaluator:new(attrs)
    attrs = attrs or {}
    assert(attrs.buf, "You need to set buf for luapad")

    attrs.statusline = { status = "ok" }
    attrs.active = true
    attrs.output = {}
    attrs.helper = {
        buf = attrs.buf,
        config = paddy.set_config,
    }

    ---[[@as Evaluator]]
    local obj = setmetatable(attrs, Evaluator)
    S.instances[attrs.buf] = obj
    return obj
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
        self:set_virtual_text(line - 1, "  " .. table.concat(res, " | "), C.print_highlight)
    end
end

function Evaluator:tcall(fun)
    local count_limit = C.count_limit < 1000 and 1000 or C.count_limit

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

            if C.error_indicator and line then
                self:set_virtual_text(tonumber(line) - 1, "<-- " .. error_msg, C.error_highlight)
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
    local context = self.context or vim.deepcopy(C.context) or {}
    local luapad_print = function(...)
        self:print(...)
    end

    context.luapad = self
    context.p = luapad_print
    context.print = luapad_print
    context.luapad = self.helper

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
        self.preview_win = Preview:new()
    end

    self.preview_win:set_content_from_table(self.output[line])
end

function Evaluator:start()
    local on_change = vim.schedule_wrap(function()
        if not self.active then
            return true
        end
        if C.eval_on_change then
            self:eval()
        end
    end)

    local on_detach = vim.schedule_wrap(function()
        self:close_preview()
        S.instances[self.buf] = nil
    end)

    vim.api.nvim_buf_attach(0, false, {
        on_lines = on_change,
        on_changedtick = on_change,
        on_detach = on_detach,
    })

    vim.api.nvim_command("augroup END")

    local main_group = vim.api.nvim_create_augroup("LuapadAutogroup", {
        clear = true,
    })
    vim.api.nvim_create_autocmd("CursorMoved", {
        group = main_group,
        callback = function ()
            require('paddynvim.lib.handlers').on_cursor_moved()
        end
    })

    local self_group = vim.api.nvim_create_augroup(("LuapadAutogroupNr"):format(self.buf), {
        clear = true
    })
    vim.api.nvim_create_autocmd("CursorHold", {
        group = self_group,
        callback = function ()
            require('paddynvim.lib.handlers').on_cursor_hold(self.buf)
        end
    })
    vim.api.nvim_create_autocmd({"CursorMoved", "CursorMovedI"}, {
        group = self_group,
        buffer = self.buf,
        callback = function ()
            require('paddynvim.lib.handlers').on_luapad_cursor_moved(self.buf)
        end
    })

    if C.on_init then
        C.on_init()
    end
    self:eval()
end

function Evaluator:finish()
    self.active = false
    vim.api.nvim_command(("augroup LuapadAutogroupNr%s"):format(self.buf))
    vim.api.nvim_command("autocmd!")
    vim.api.nvim_command("augroup END")
    S.instances[self.buf] = nil

    if vim.api.nvim_buf_is_valid(self.buf) then
        vim.api.nvim_buf_clear_namespace(self.buf, ns, 0, -1)
    end
    self:close_preview()
end

return Evaluator
