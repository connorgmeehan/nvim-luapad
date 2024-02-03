local M = {}

M.stdout = vim.loop.new_pipe(false)
M.stdout:open(1)

--- Writes to stdout
---@param data string
M.write = function (data)
  if #data == 0 then
    return
  end
  M.stdout:write(data)
end

M.get_win_size = function ()
    
end

return M
