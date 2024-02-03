local D = require('paddynvim.util.debug')
local base64         = require('paddynvim.util.base64')
local kitty          = require "paddynvim.util.kitty"
--- Converts from human readable file format to kitty code.
---@enum 

---@class ImageOpts
---@field data number[]
---@field format 'png'
---@field width number
---@field height number

local Image = {}
Image.__index = Image


--- Creates an image from a canvas
---@param canvas Canvas
function Image:from_canvas(canvas)
    return self:new({
        id = canvas.id,
        x = 0,
        y = 0,
        cols = 20,
        rows = 20,
        data = canvas:png_data(),
        width = canvas.width,
        height = canvas.height,
        format = 'png',
    })
end
--
--- Creates a new image
---@param opts ImageOpts
function Image:new(opts)
    local instance = setmetatable(opts, self)
    instance:transfer()
    return instance
end

function Image:move_absolute(x, y)
    self.x = x
    self.y = y
end

function Image:update_from_canvas(canvas)
    self.data = canvas:png_data()
end
--- 
function Image:transfer()
    local data = base64.encode(self.data)
    kitty.transmit_png(self.id, data)
end

function Image:draw()
    kitty.display_png(self.id, self.x, self.y, self.cols, self.rows)
end

function Image:dispose()
    D.log("trace", "[DrawIntegration] image:dispose() on self")
    kitty.delete_png(self.id)
end

return Image
