---@module paddynvim.util.coordinates
---@author Connor G Meehan
---@license MIT
--- Contains logic for calculating buffer coordinates (line number, column) and 
--- terminal coordinates (absolute from 0, 0 at top left of terminal.)


local M = {}

M.get_eval_buffer_line = function(depth)
    local line = debug.traceback("", depth):match("^.-]:(%d-):")
    if not line then
        return
    end
    line = tonumber(line)
    return line
end

return M
