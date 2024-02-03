local fs = require('paddynvim.util.fs')
local array = require('paddynvim.util.array')
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

    fs.mkdir(fs.data_path, {
        exists_ok = true,
    })
end

M.commands = {
    --- Attach to current buffer
    attach = function ()
        local C = M.config

        local buf = vim.api.nvim_get_current_buf()
        D.log("trace", "Paddy: Attaching to buffer: " .. vim.inspect(buf))

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
    end,
    --- Detatch from current buffer
    detach = function ()
        local buf = vim.api.nvim_get_current_buf()
        D.log("trace", "Paddy: Detaching from buffer" .. vim.inspect(buf))
        local S = M._state
        if S.instances[buf] then
            S.instances[buf]:finish()
        end
    end,
    --- Creates a new paddy pad.
    ---@param file_name string|nil
    new = function (file_name)
        D.log("trace", "Paddy: New paddy at " .. vim.inspect(file_name))
        local C = M.config
        local S = M._state

        local split_orientation = "vsplit"
        if C.split_orientation == "horizontal" then
            split_orientation = "split"
        end

        S.gcounter = S.gcounter + 1
        local file_path = ''
        if type(file_name) == 'string' then
            file_path = fs.path(fs.data_path, file_name .. '.lua')
        else
            file_path = fs.path('tmp', "Paddy" .. S.gcounter .. '.lua')
        end

        vim.api.nvim_command("botright " .. split_orientation .. " " .. file_path)

        M.commands.attach()
    end,
    ---@param file_name string|nil
    open = function (file_name)
        D.log("trace", "Paddy: Opening paddy " .. vim.inspect(file_name))
        local C = M.config

        local split_orientation = "vsplit"
        if C.split_orientation == "horizontal" then
            split_orientation = "split"
        end

        local file_path = fs.path(fs.data_path, file_name .. '.lua')
        vim.api.nvim_command("botright " .. split_orientation .. " " .. file_path)

        M.commands.attach()
    end,

    inject_integrations = function (buffer_id)
        buffer_id = buffer_id or vim.api.nvim_get_current_buf()
        local total_lines = vim.api.nvim_buf_line_count(0)

        local offset = 0
        for i, integration in ipairs(_G.PaddyNvim.config.integrations) do
            local header = integration.meta.header
            if header then
                for i, line in ipairs(header) do
                    vim.api.nvim_buf_set_lines(0, offset, offset, false, {line})
                    offset = offset + 1
                end
            end
        end

        local did_inject = offset ~= 0
        if did_inject then
            vim.api.nvim_buf_set_lines(0, offset, offset, false, {"-- Welcome to Paddy :)"})
            vim.api.nvim_buf_set_lines(0, offset+1, offset+1, false, {""})
        end
    end,

    --- Command completion handler for 
    ---@param args string[]
    ---@return string
    _completion_open = function (args)
        local contents = fs.list_files(fs.data_path)
        ---@type string[]
        local options = array.array_map(contents, function (_, path)
            local name = fs.file_name(path)
            if name == nil then
                return nil
            end
            local ext = fs.file_ext(path)
            local result = name:sub(0, #name - #ext)
            return result
        end)
        return vim.tbl_filter(function (val)
            return vim.startswith(val, args[3])
        end, options)
    end
}
-- Command aliases
M.commands.load = M.commands.open
M.commands._completion_load = M.commands._completion_open

M.paddy = function(args)
    D.log("trace", "Paddy: Command called with args" .. vim.inspect(args))
    if args == nil then
        M.commands.new(nil)
    end

    local cmd_name = args[1]

    local handler = M.commands[cmd_name]
    if handler then
        handler(args[2], args[3], args[4])
    else
        M.commands.new(nil)
    end
end

M.utils = {
    --- Gets the integration for a given buffer. 
    ---@param buffer_id number
    ---@param integration_name string 
    ---@return PaddyIntegration|nil
    get_integration = function(buffer_id, integration_name)
        local instance = M._state.instances[buffer_id]
        if instance == nil then
            return nil
        end
        local integration =  array.array_find(instance.integrations, function (_, el)
            return el.meta.name == integration_name
        end)
        ---@cast integration PaddyIntegration|nil
        return integration
    end
}

_G.PaddyNvim = M

return M
