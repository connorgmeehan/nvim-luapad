--- Integration for drawing using Kitty graphics protocol and libcairo
---
--- Source https://github.com/romgrk/kui.nvim/tree/master Vendored under MIT License.
---
---@class DrawIntegration : PaddyIntegration
local DrawIntegration = {}
DrawIntegration.__index = DrawIntegration

DrawIntegration.meta = {
    name = "cpml",
    constructor = function (config)
        return DrawIntegration:new(config)
    end
}


function DrawIntegration:new(c)
    print(vim.inspect(c))
    local config = c.draw_integration
    local cairo_path = config and config.cairo_path or nil

    local fields = {
        extra_context = {
            cairo = function ()
                return require('paddynvim.integrations.draw.cairo.cairo')(cairo_path)
            end
        }
    }
    local instance = setmetatable(fields, DrawIntegration)
    return instance
end

return DrawIntegration

