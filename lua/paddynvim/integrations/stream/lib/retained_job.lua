local D = require('paddynvim.util.debug')
local retained = require('paddynvim.util.retained')
local array    = require('paddynvim.util.array')

local M = {}

M.job_manager = retained.RetainedManager:new()

local Job = {}
Job.__index = Job
M.Job = Job

function Job:new(opts)
    local id = M.job_manager:get_unique_id()
    local instance = setmetatable({
        id = id,
        handle = nil,
        data = "",
        err = "",
        cmd = opts.cmd,
        args = opts.args,
        on_data  = opts.on_data or function() end,
        on_done  = opts.on_done or function() end,
        stdin = nil,
        stdout = nil,
        stderr = nil,
    }, self)
    local retained = M.job_manager:register_or_get_retained(id, instance)

    retained.on_data = instance.on_data
    retained.on_done = instance.on_done

    return retained
end

function Job:retained_equals(other)
    if self.cmd ~= other.cmd then
        return false
    end
    if type(self.args) == 'table' and type(other.args) == 'table' then
        return array.array_equals(self.args, other.args)
    else
        return self.args == other.args
    end
end

function Job:start()
    if self.handle then
        return
    end
    D.log("trace", "Starting job " .. self.id .. " with cmd " .. self.cmd)

    self.stdin = vim.loop.new_pipe(false)
    self.stdout = vim.loop.new_pipe(false)
    self.stderr = vim.loop.new_pipe(false)

    self.handle = vim.loop.spawn(self.cmd, {
        args = self.args,
        stdio = {self.stdin, self.stdout, self.stderr},
    }, function ()
        self:dispose()
    end)

    self.stdout:read_start(function(err, data)
        assert(not err, err)
        if data ~= nil then
            self.data = self.data .. data
        end
    end)

    self.stderr:read_start(function(err, data)
        assert(not err, err)
        assert(not data, data)
    end)
end

function Job:dispose()
    if not self.handle then
        return
    end
    D.log("trace", "Disposing of job " .. self.id .. " with cmd " .. self.cmd)
    local safe_close = function (handle)
        if not handle then
            return
        elseif not handle:is_closing() then
            handle:close()
        end
    end
    self.stdin:read_stop()
    self.stdout:read_stop()
    self.stderr:read_stop()
    safe_close(self.stdin)
    safe_close(self.stdout)
    safe_close(self.stderr)
    safe_close(self.handle)
    self.on_done()
end

return M

