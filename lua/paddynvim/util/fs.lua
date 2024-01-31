local M = {}

--- Creates a temporary unique path for the luapad file.
---@vararg string[]
---@return string
M.path = function(...)
  return vim.api.nvim_eval('tempname()') .. '_Luapad.lua'
end


return M

