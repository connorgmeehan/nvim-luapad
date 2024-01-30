local PaddyNvim = {}

--- Your plugin configuration with its default values.
---
--- Default values:
---@eval return MiniDoc.afterlines_to_code(MiniDoc.current.eval_section)
PaddyNvim.options = {
    -- Prints useful logs about what event are triggered, and reasons actions are executed.
    debug = false,
}

--- Define your paddynvim setup.
---
---@param options table Module config table. See |PaddyNvim.options|.
---
---@usage `require("paddynvim").setup()` (add `{}` with your |PaddyNvim.options| table)
function PaddyNvim.setup(options)
    options = options or {}

    PaddyNvim.options = vim.tbl_deep_extend("keep", options, PaddyNvim.options)

    return PaddyNvim.options
end

return PaddyNvim
