-- You can use this loaded variable to enable conditional parts of your plugin.
if _G.PaddyNvimLoaded then
    return
end

_G.PaddyNvimLoaded = true

vim.api.nvim_create_user_command("Paddy", function(opts)
    require("paddynvim").paddy(opts.fargs)
end, {
    nargs = "*",
    complete = function (_, line)
        local args = vim.split(line, "%s+")
        -- Base command completion handler
        if #args == 2 then
            local keys = vim.tbl_keys(_G.PaddyNvim.commands)
            return vim.tbl_filter(function (val)
                -- Filter out private fields (completion handlers)
                if val and val:startswith("_") then
                    return false
                end
                if args[2] then
                    return vim.startswith(val, args[2])
                end
                return false
            end, keys)
        end
        -- Command specific completion handler
        if #args == 3 then
            local cmd_name = args[2]
            local completion_key = "_completion_" .. cmd_name
            local completion_handler = _G.PaddyNvim.commands[completion_key]
            if completion_handler then
                return completion_handler(args)
            end
        end
    end
})
