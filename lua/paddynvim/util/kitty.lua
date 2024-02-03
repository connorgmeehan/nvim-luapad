---@module "paddynvim.util.kitty"
---@author edluffy
---@source https://github.com/edluffy/hologram.nvim/blob/main/lua/hologram/terminal.lua
---@license MIT

local D = require('paddynvim.util.debug')
local base64 = require('paddynvim.util.base64')

local M = {}

local stdout = vim.loop.new_tty(1, false)

local CTRL_KEYS = {
    -- General
    action = 'a',
    delete_action = 'd',
    quiet = 'q',

    -- Transmission
    format = 'f',
    transmission_type = 't',
    data_width = 's',
    data_height = 'v',
    data_size = 'S',
    data_offset = 'O',
    image_id = 'i',
    image_number = 'I',
    compressed = 'o',
    more = 'm',

    -- Display
    placement_id = 'p',
    x_offset = 'x',
    y_offset = 'y',
    width = 'w',
    height = 'h',
    cell_x_offset = 'X',
    cell_y_offset = 'Y',
    cols = 'c',
    rows = 'r',
    cursor_movement = 'C',
    z_index = 'z',

    -- TODO: Animation
}

--- 
---@param source 
M.transmit_png = function (image_id, source)
    M.send_graphics_command({
        format = 100, -- PNG
        transmission_type = 'd', -- Direct
        image_id = image_id,
        action = 't',
        quiet = 2,
    }, source)
end
--- 
---@param source 
M.display_png = function (image_id, x, y, cols, rows)
    M.move_cursor(x, y)
    M.send_graphics_command({
        action = 'p', -- Display Image by id
        image_id = image_id,
        cols = cols,
        rows = rows,
        quiet = 2,
        cursor_movement = 1,
        z_index = 1,
    })
    M.restore_cursor()
end

--- 
---@param source 
M.delete_png = function (image_id)
    M.send_graphics_command({
        action = 'd', -- Display Image by id
        image_id = image_id,
        quiet = 2,
    })
end

M.send_graphics_command = function (keys, payload)
    if payload and string.len(payload) > 4096 then keys.more = 1 else keys.more = 0 end
    local ctrl = ''
    for k, v in pairs(keys) do
        if v ~= nil then
            ctrl = ctrl..CTRL_KEYS[k]..'='..v..','
        end
    end
    ctrl = ctrl:sub(0, -2) -- chop trailing comma

    if payload then
        if keys.transmission_type ~= 'd' then
            payload = base64.encode(payload)
        end
        payload = M.get_chunked(payload)

        -- D.log("trace", "PaddyNvim: Sending to kitty...")
        for i=1,#payload do
            local str = '\x1b_G'..ctrl..';'..payload[i]..'\x1b\\'
            -- D.log("trace", "Chunk[" .. i .. "]: " .. str)
            M.write(str)
            if i == #payload-1 then ctrl = 'm=0' else ctrl = 'm=1' end
        end
    else
        local str = '\x1b_G'..ctrl..'\x1b\\'
        -- D.log("trace", "PaddyNvim: Sending to kitty...")
        -- D.log("trace", "Single: "..str)
        M.write(str)
    end
end

-- Split into chunks of max 4096 length
M.get_chunked = function(str)
    local chunks = {}
    for i = 1,#str,4096 do
        local chunk = str:sub(i, i + 4096 - 1):gsub('%s', '')
        if #chunk > 0 then
            table.insert(chunks, chunk)
        end
    end
    return chunks
end

M.move_cursor = function(row, col)
    M.write('\x1b[s')
    M.write('\x1b['..row..':'..col..'H')
end

M.restore_cursor = function()
    M.write('\x1b[u')
end
-- glob together writes to stdout
M.write = vim.schedule_wrap(function(data)
    stdout:write(data)
end)

return M
