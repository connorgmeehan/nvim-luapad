local M = {}

---@param table table
---@return number
M.array_length = function(table)
    local length = 0
    for _, _ in ipairs(table) do
        length = length + 1
    end
    return length
end

M.array_reduce = function (table, initial_value, predicate)
    local return_value = initial_value
    for _, value in ipairs(table) do
        return_value = predicate(return_value, value)
    end
    return return_value
end

--- 
---@generic T
---@generic R 
---@param table T[]
---@param predicate function(index:number,value:T):R
---@return R[]
M.array_map = function (table, predicate)
    local return_value = {}
    for index, value in ipairs(table) do
        return_value[index] = predicate(index, value)
    end
    return return_value
end

return M


