local retained_utils = require "paddynvim.util.retained"
--- Converts from human readable file format to kitty code.
---@enum 
local KITTY_FORMATS = {
    png = 100
}
local format_to_kitty = function(format)
    return KITTY_FORMATS[format]
end

---@class ImageOpts
---@field data number[]
---@field format 'png'
---@field width number
---@field height number

local Image = {}
Image._manager = retained_utils.RetainedManager:new()
Image.__index = Image


--- Creates an image from a canvas
---@param canvas Canvas
function Image:from_canvas(canvas)
    return self:new({
        data = canvas:png_data(),
        width = canvas.width,
        height = canvas.height,
        format = 'png',
    })
end

--- Creates a new image
---@param opts ImageOpts
function Image:new(opts)
    local id = Image._manager:get_unique_id()

    local instance = setmetatable(opts, self)
    local retained = Image._manager:register_or_get_retained(id, instance)
    return retained
end

function Image:_transfer()
end

function Image:draw(x, y)

end
