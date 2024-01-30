local paddy = require 'paddynvim'
local C = paddy.config
local S = paddy._state

local M = {}

M.on_cursor_hold = function(buf)
  if C.preview.enabled then S.instances[buf]:preview() end
end

M.on_luapad_cursor_moved = function(buf)
  S.instances[buf]:close_preview()
end

M.on_cursor_moved = function()
  if C.eval_on_move then
    for _, v in pairs(S.instances) do v:eval() end
  end
end

return M
