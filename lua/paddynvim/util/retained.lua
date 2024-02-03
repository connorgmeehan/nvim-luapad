local D = require('paddynvim.util.debug')
---@module paddynvim.util.retained
---@author Connor Meehan
---@license MIT
--- Contains base class + manager for objects that are retained each frame.
---
--- When a retained object is constructed it checks with the retained manager
--- if a similar object already exists via the Retained:equals(other) method.
--- If there is a similar object the retained version is returned.
local M = {}

local RetainedManager = {}
RetainedManager.__index = RetainedManager
M.RetainedManager = RetainedManager

function RetainedManager:new()
    local instance = setmetatable({
        unique_id = 1,
        prev_elements = {},
        elements = {},
    }, self)
    return instance
end

--- Gets the existing retained object by id.
--- If the objects implement `retained_equals` it will compare them and only
--- return it if `retained_equals` is true.
---@generic T
---@param id number
---@param element T
---@return T|nil
function RetainedManager:register_or_get_retained(id, element)
    D.log("trace", "register_or_get_retained(id " .. id .. ", element: ...) with prev_elements: " .. vim.inspect(#self.prev_elements))
    self.elements[id] = element
    local is_same = false
    local prev = self.prev_elements[id]
    if prev then
        local mt = getmetatable(prev)
        if mt.retained_equals then
            if prev:retained_equals(element) then
                is_same = true
            end
        else
            is_same = true
        end
    end

    if is_same then
        self.elements[id] = prev
        return prev
    else
        return element
    end
end

function RetainedManager:get_unique_id()
    local id = self.unique_id
    self.unique_id = self.unique_id + 1
    return id
end
function RetainedManager:on_attach()
    for _, v in ipairs(self.elements) do
        local mt = getmetatable(v)
        if mt.on_detach then
            v:on_detach()
        end
    end
end

function RetainedManager:on_detach()
    for _, v in ipairs(self.elements) do
        local mt = getmetatable(v)
        if mt.on_detach then
            v:on_detach()
        end
    end
end

function RetainedManager:on_pre_update()
    self.prev_elements = self.elements
    self.elements = {}
    for _, v in ipairs(self.elements) do
        local mt = getmetatable(v)
        if mt.on_pre_update then
            v:on_pre_update()
        end
    end

    D.log("trace", "RetainedManager:on_pre_update() Updated elements prev: " .. #self.prev_elements .. "elements: " .. #self.elements)
end

function RetainedManager:on_update()
    for _, v in ipairs(self.elements) do
        local mt = getmetatable(v)
        if mt.on_update then
            v:on_update()
        end
    end
end

function RetainedManager:on_post_update()
    self.unique_id = 1
    local length = math.max(#self.elements, #self.prev_elements)
    for i = 1, length, 1 do
        local inst_current = self.elements[i]
        local inst_prev = self.prev_elements[i]
        if inst_current ~= inst_prev and inst_prev and inst_prev.dispose then
            inst_prev:dispose()
        end
    end
    for _, v in ipairs(self.elements) do
        local mt = getmetatable(v)
        if mt.on_post_update then
            v:on_post_update()
        end
    end

    D.log("trace", "RetainedManager:on_post_update() self.prev_elements " .. #self.prev_elements .. " self.elements " .. #self.elements)
end

function RetainedManager:on_focus()
    for _, v in ipairs(self.elements) do
        local mt = getmetatable(v)
        if mt.on_blur then
            v:on_blur()
        end
    end
end

function RetainedManager:on_blur()
    for _, v in ipairs(self.elements) do
        local mt = getmetatable(v)
        if mt.on_blur then
            v:on_blur()
        end
    end
end

return M
