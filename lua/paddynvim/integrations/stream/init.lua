local D = require('paddynvim.util.debug')
local job = require('paddynvim.integrations.stream.lib.retained_job')
local pipe = require('paddynvim.integrations.stream.lib.retained_pipe')
local kitty= require('paddynvim.util.kitty')
--- Integration for drawing using Kitty graphics protocol and libcairo
---
--- Source https://github.com/romgrk/kui.nvim/tree/master Vendored under MIT License.
---
---@class StreamIntegration : PaddyIntegration
local StreamIntegration = {}
StreamIntegration.__index = StreamIntegration

StreamIntegration.meta = {
    name = "draw",
    constructor = function (_)
        return StreamIntegration:new()
    end
}


function StreamIntegration:new()
    D.log("trace", "StreamIntegration: new()")
    local state = {
        job_manager = job.job_manager,
        pipe_manager = pipe.pipe_manager,
    }

    local fields = {
        _state = state,
        extra_context = {
            stream = {
                Job = job.Job,
                Pipe = pipe.Pipe,
                kitty = kitty,
            }
        }
    }
    local instance = setmetatable(fields, StreamIntegration)
    return instance
end

function StreamIntegration:on_pre_update()
    D.log("trace", "StreamIntegration:on_pre_update()")
    self._state.job_manager:on_pre_update()
    self._state.pipe_manager:on_pre_update()
end

function StreamIntegration:on_post_update()
    D.log("trace", "StreamIntegration:on_post_update()")
    self._state.job_manager:on_post_update()
    self._state.pipe_manager:on_post_update()
end

return StreamIntegration

