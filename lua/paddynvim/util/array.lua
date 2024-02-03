local M = {}

M.array_equals = function (arr1, arr2)
    if #arr1 ~= #arr2 then
        return false
    end
    for i, v in ipairs(arr1) do
        if v ~= arr2[i] then
            return false
        end
    end
    return true
end
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

---@generic T
---@param table T[]
---@param predicate function(index:number,value:T):boolean
---@return T|nil
M.array_find = function(table, predicate)
    for index, value in ipairs(table) do
        if predicate(index, value) then
            return value
        end
    end
    return nil
end

M.array_some = function(table, predicate)
    return type(M.array_find(table, predicate)) ~= "nil"
end

M.array_contains = function (table, value)
    return M.array_some(table, function (_, value2)
        return value == value2
    end)
end

M.array_push = function(array, ...)
    for i, value in ipairs({...}) do
        local index = #array + i
        array[index] = value
    end
end


return M
