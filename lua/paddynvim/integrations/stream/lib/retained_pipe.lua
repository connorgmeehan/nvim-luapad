---@module 
---@author 
---@license 

local D = require('paddynvim.util.debug')
local retained_utils = require('paddynvim.util.retained')

local M = {}

M.pipe_manager = retained_utils.RetainedManager:new()


--- Pipe, retained between evaluations of the paddy buffer.
---@class Pipe
---@field id number Unique id for each pipe for this buffer
---@field pipe uv_pipe_t|nil
---
local Pipe = {}
Pipe.__index = Pipe
M.Pipe = Pipe

function Pipe:new()
    local id = M.pipe_manager:get_unique_id()
    local instance = setmetatable({
        id = id,
        data = "",
        err = "",
        pipe = nil,
    }, self)
    local retained = M.pipe_manager:register_or_get_retained(id, instance)

    return retained
end

function Pipe:write(data)
    if self.pipe then
        return
    end
    self.pipe = vim.loop.new_pipe(false)
    if not self.pipe:is_writable() then
        error("Pipe: not writable.")
    end
    self.pipe:write(data)

    self.pipe:read_start(function (err, chunk)
        D.log("trace", "Pipe: " .. self.id .. " received data with length of " .. #chunk)
        if err then
            self.err = self.err .. err
        end
        if data then
            self.data = self.data .. chunk
        else
            self:dispose()
        end
    end)
end

function Pipe:dispose()
    if not self.pipe then
        return
    end
    self.pipe:read_stop()
    if not self.pipe:is_closing() then
        self.pipe:close()
    end
    self.pipe = nil
end

return M
