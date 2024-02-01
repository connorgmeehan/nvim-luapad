local uv = vim.loop

local M = {}

M.sep = (function()
  if jit then
    local os = string.lower(jit.os)
    if os ~= "windows" then
      return "/"
    else
      return "\\"
    end
  else
    return package.config:sub(1, 1)
  end
end)()

M.root = (function()
  if M.sep == "/" then
    return function()
      return "/"
    end
  else
    return function(base)
      base = base or vim.loop.cwd()
      return base:sub(1, 1) .. ":\\"
    end
  end
end)()

--- Creates a temporary unique path for the luapad file.
---@vararg string[]
---@return string
M.path = function(...)
  return table.concat({ ... }, M.sep)
end

--- Returns the filename of a path
---@param path string
---@return string|nil
M.file_name = function (path)
    return vim.fs.basename(path)
end

--- Returns the filename of a path
---@param path string
---@return string|nil
M.file_ext = function (path)
    return path:match("^.+(%..+)$")
end

--- Lists the files in a directory
---@param path string Path to directory
---@return string[]
M.list_files = function(path)
    return vim.split(vim.fn.glob(path .. "/*"), "\n", { trimempty = true })
end

M.exists = function (path)
    return uv.fs_stat(path)
end

--- Creates a directory
---@param path string
M.mkdir = function (path, opts)
  opts = opts or {}

  local mode = opts.mode or 448 -- 0700 -> decimal
  local exists_ok = opts.exists_ok

  local exists = M.exists(path)
  if not exists_ok and exists then
    error("FileExistsError:" .. path)
  end
  uv.fs_mkdir(path, mode)
end

M.data_path = M.path(vim.fn.stdpath('data'), 'paddynvim')

return M

