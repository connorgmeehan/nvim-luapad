local M = {}

--- Parses the contents of an error.
---@param str string
---@return string
M.parse_error = function (str)
  return str:match("%[string.*%]:(%d*): (.*)")
end


return M
