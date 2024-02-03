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
    self.elements[id] = element
    local is_same = false
    local prev = self.prev_elements[id]
    if prev then
        if prev.retained_equals then
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

function RetainedManager:pre_change()
    for _, v in ipairs(self.elements) do
        local mt = getmetatable(v)
        if mt.pre_update then
            v:pre_update()
        end
    end
    self.prev_elements = self.elements
    self.elements = {}
end

function RetainedManager:post_change()
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
        if mt.post_update then
            v:post_update()
        end
    end
end

return M
