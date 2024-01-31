local fs = require('paddynvim.util.fs')
local Evaluator = require('paddynvim.lib.evaluator')
local PaddyInstance = require('paddynvim.lib')
local D = require("paddynvim.util.debug")

-- main module file
---@class PaddyNvim
---@field config PaddyConfig
---@field _state PaddyState
local M = {}

--- Your plugin configuration with its default values.
---
--- Default values:
---@class PaddyConfig
---@eval return MiniDoc.afterlines_to_code(MiniDoc.current.eval_section)
local default_config = {
    -- Prints useful logs about what event are triggered, and reasons actions are executed.
    debug = false,

    ---@type function Callback function called after creating new luapad instance.
    on_init = nil,
    ---@type table The default context tbl in which luapad buffer is evaluated. Its properties will be available in buffer as "global" variables.
    context = nil,

    ---@type table Options related to preview windows
    preview = {
        ---@type boolean     Show floating output window on cursor hold. It's a good idea to set low update time. For example: `let &updatetime = 300` You can jump to it by `^w` `w`.
        enabled = true,
        ---@type number minimum height of the preview window.
        min_height = 10,
        ---@type number maximum height of the preview window.
        max_height = 30,
    },

    ---@type PaddyIntegration[] List of integrations to attach to the Paddy buffer.
    integrations = { Evaluator },

    ---@type number Luapad uses count hook method to prevent infinite loops occurring during code execution. Setting count_limit too high will make Luapad laggy, setting it too low, may cause premature code termination.
    count_limit = 2 * 1e5,
    ---@type boolean Show virtual text with error message (except syntax or timeout. errors).
    error_indicator = true,
    ---@type string Highlight group used to coloring luapad print output.
    print_highlight = "Comment",
    ---@type string Highlight group used to coloring luapad error indicator.
    error_highlight = "ErrorMsg",
    ---@type boolean Evaluate all luapad buffers when the cursor moves.
    eval_on_move = false,
    ---@type boolean Evaluate buffer content when it changes.
    eval_on_change = true,
    ---@type 'split'|'vsplit' The orientation of the split created by `Luapad` command. Can be `vertical` or `horizontal`.
    split_orientation = "vsplit",
    ---@type boolean The Luapad buffer by default is wiped out after closing/loosing a window. If you're used to switching buffers, and you want to keep Luapad instance alive in the background, set it to false.
    wipe = true,
}

---@type PaddyConfig
M.config = default_config

--- Default state of the app
---@class PaddyState
---@field instances table<number,PaddyInstance> Array of buffers where the evaluator is currently attached to.
local default_state = {
    instances = {},
    gcounter = 0,
}

--- Sets the config
---@param config PaddyConfig?
M.set_config = function(config)
    M.config = vim.tbl_deep_extend("force", M.config, config or {})
end
---@param config PaddyConfig?
M.setup = function(config)
    M.set_config(config)
    M._state = default_state
end

M.paddy = function()
    local Evaluator = require('paddynvim.lib.evaluator')

    local C = M.config
    local S = M._state

    local split_orientation = "vsplit"
    if C.split_orientation == "horizontal" then
        split_orientation = "split"
    end

    S.gcounter = S.gcounter + 1
    local file_path = fs.path('tmp', 'Luapad_' .. S.gcounter .. '.lua')
    vim.api.nvim_command("botright " .. split_orientation .. " " .. file_path)

    local buf = vim.api.nvim_get_current_buf()

    D.log("trace", "Creating new buffer with id: " .. string.format(buf))
    PaddyInstance:new(M, buf):start()

    vim.api.nvim_buf_set_option(buf, "swapfile", false)
    vim.api.nvim_buf_set_option(buf, "filetype", "lua")
    vim.api.nvim_buf_set_option(buf, "bufhidden", C.wipe and "wipe" or "hide")
    vim.api.nvim_command("au QuitPre <buffer> set nomodified")

    if C.wipe then
        -- Always try to keep file as modified so it can't be accidentally switched
        vim.api.nvim_buf_set_option(buf, "modified", true)
        vim.api.nvim_command(
            [[au BufWritePost <buffer> lua vim.schedule(function() vim.api.nvim_buf_set_option(0, 'modified', true) end)]]
        )
    end
end

_G.PaddyNvim = M

return M
