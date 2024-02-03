local D = require('paddynvim.util.debug')
local Canvas = require('paddynvim.integrations.draw.lib.canvas')
local array = require('paddynvim.util.array')
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
    end,
    header = {
        "local draw = require('paddynvim.integrations.draw.lib')",
        "draw.import_cairo('cairo' --[[ or sepecify directoy of libcairo.so/dylib]])",
        "local Canvas = draw.Canvas"
    }
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

function DrawIntegration:on_attach()
    local cpml_integration = array.array_find( _G.PaddyNvim.config.integrations, function (_, integration)
        return integration.meta.name == "cpml"
    end)
    if not cpml_integration then
        local message = [[
        Paddy: `draw` integration requires the `cpml` integration for math.
        Add the following to your config.

        local cpml = require('paddy.integration.cpml')
        local draw = require('paddy.integration.draw')
        require('paddy').setup({
            integrations = { cpml, draw }
        })
        ]]
        vim.notify(message, vim.log.levels.ERROR)
        error(message)
    end
end

function DrawIntegration:on_detach()
    self._state.canvas_manager:on_detach()
end

function DrawIntegration:on_pre_update()
    D.log("trace", "DrawIntegration:on_pre_update()")
    self._state.canvas_manager:on_pre_update()
end

function DrawIntegration:on_update()
    D.log("trace", "DrawIntegration:on_update()")
    self._state.canvas_manager:on_update()
end

function DrawIntegration:on_post_update()
    D.log("trace", "DrawIntegration:on_post_update()")
    self._state.canvas_manager:on_post_update()
end

return DrawIntegration

