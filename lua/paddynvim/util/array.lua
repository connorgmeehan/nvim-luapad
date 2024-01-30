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


return M


