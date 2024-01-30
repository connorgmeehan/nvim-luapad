local D = require('paddynvim.util.debug')
local array = require('paddynvim.util.array')

--- Shows the formatted content within a floating window.
---@class Preview
---@field C PaddyConfig The global config object
---@field buffer_id number The buffer number of the preview
---@field window_id number The window number of the preview
local Preview = {}
Preview.__index = Preview

--- Creates a new preview window
---@param config PaddyConfig
---@return Preview
function Preview:new(config)
    if config.debug then
        D.log("debug", "Opening new preview window.")
    end
    local buffer_id = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_option(buffer_id, "bufhidden", "wipe")
    vim.api.nvim_buf_set_option(buffer_id, "filetype", "lua")

    local fields = {
        C = config,
        buffer_id = buffer_id,
        window_id = vim.api.nvim_open_win(buffer_id, false, {
            relative = "win",
            col = 0,
            row = 0,
            width = 1,
            height = 1,
            style = "minimal",
            focusable = true,
        })
    }
    local obj = setmetatable(fields, self)

    print("Contructed object: ".. vim.inspect(obj))
    return obj
end

--- Updates the content within a preview window.
function Preview:set_content(content, height)
    if self.C.debug then
        D.log("debug", ("Setting content on preview window %s"):format(self.window_id))
        D.log("debug", ("%s"):format(vim.inspect(content)))
    end

    local buf = self.buffer_id
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)

    local config = self:build_window_config(height)
    vim.api.nvim_win_set_config(self.window_id, config)
    vim.api.nvim_win_set_option(self.window_id, "signcolumn", "no")
end

function Preview:set_content_from_table(content)
    if self.C.debug then
        D.log("debug", ("%s"):format(vim.inspect(content)))
    end
    local str_content = vim.split(table.concat(vim.tbl_flatten(content), "\n"), "\n")
    local height = array.array_length(content)

    self:set_content(str_content, height)
end

function Preview:build_window_config(height)
    local h = math.min(math.max(height,self.C.preview.min_height), self.C.preview.max_height)
    local width = tonumber(vim.api.nvim_win_get_width(0))
    local row_pos = tonumber(vim.api.nvim_win_get_height(0)) - h
    return {
        relative = "win",
        col = 0,
        row = row_pos,
        width = width,
        height = h,
        style = "minimal",
        focusable = true,
    }
end

--- Checks if the window is still valid 
---@return boolean
function Preview:is_valid()
    local window_valid = vim.api.nvim_win_is_valid(self.window_id)
    local buffer_valid = vim.api.nvim_buf_is_valid(self.buffer_id)
    return window_valid and buffer_valid
end

--- Closes the preview window
function Preview:close()
    if self.window_id and vim.api.nvim_win_is_valid(self.window_id) then
        vim.api.nvim_win_close(self.window_id, false)
    end
end

return Preview
