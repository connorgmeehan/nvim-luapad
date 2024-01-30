-- You can use this loaded variable to enable conditional parts of your plugin.
if _G.PaddyNvimLoaded then
    return
end

_G.PaddyNvimLoaded = true

vim.api.nvim_create_user_command("PaddyNvim", function()
    require("paddynvim").toggle()
end, {})
