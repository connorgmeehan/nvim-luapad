local D = require('paddynvim.util.debug')
local Canvas = require('paddynvim.integrations.draw.lib.canvas')
--- Integration for drawing using Kitty graphics protocol and libcairo
---
--- Source https://github.com/romgrk/kui.nvim/tree/master Vendored under MIT License.
---
---@class DrawIntegration : PaddyIntegration
local DrawIntegration = {}
DrawIntegration.__index = DrawIntegration

DrawIntegration.meta = {
    name = "draw",
    constructor = function (config)
        return DrawIntegration:new(config)
    end
}


function DrawIntegration:new(c)
    D.log("trace", "DrawIntegration: new()")
    local config = c.draw_integration
    local cairo_path = config and config.cairo_path or nil

    local state = {
        cairo_path = cairo_path,
        cairo = nil,
        canvas_manager = Canvas._manager,
        canvases = {},
        images_length = 0,
        images = {},
    }

    local fields = {
        _state = state,
        extra_context = {
            draw = {
                import_cairo = function (dylib_path)
                    local not_imported = state.cairo == nil
                    local path_changed = dylib_path ~= state.cairo_path

                    if not_imported or path_changed then
                        local last_cairo = require('paddynvim.integrations.draw.cairo.cairo')(cairo_path)
                        state.cairo = last_cairo
                        state.cairo_path = cairo_path
                    end

                    return state.cairo
                end,
                Canvas = Canvas,
            }
        }
    }
    local instance = setmetatable(fields, DrawIntegration)
    return instance
end

function DrawIntegration:on_changed()
    self._state.canvas_manager:pre_change()
end

function DrawIntegration:on_change_finished()
    D.log("trace", "StreamIntegration:on_change_finished()")
    self._state.canvas_manager:post_change()
end

return DrawIntegration

