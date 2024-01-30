local M = require("paddynvim.main")
local PaddyNvim = {}

-- Toggle the plugin by calling the `enable`/`disable` methods respectively.
function PaddyNvim.toggle()
    -- when the config is not set to the global object, we set it
    if _G.PaddyNvim.config == nil then
        _G.PaddyNvim.config = require("paddynvim.config").options
    end

    _G.PaddyNvim.state = M.toggle()
end

-- starts PaddyNvim and set internal functions and state.
function PaddyNvim.enable()
    if _G.PaddyNvim.config == nil then
        _G.PaddyNvim.config = require("paddynvim.config").options
    end

    local state = M.enable()

    if state ~= nil then
        _G.PaddyNvim.state = state
    end

    return state
end

-- disables PaddyNvim and reset internal functions and state.
function PaddyNvim.disable()
    _G.PaddyNvim.state = M.disable()
end

-- setup PaddyNvim options and merge them with user provided ones.
function PaddyNvim.setup(opts)
    _G.PaddyNvim.config = require("paddynvim.config").setup(opts)
end

_G.PaddyNvim = PaddyNvim

return _G.PaddyNvim
