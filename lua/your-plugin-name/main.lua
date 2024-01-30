local D = require("paddynvim.util.debug")

-- internal methods
local PaddyNvim = {}

-- state
local S = {
    -- Boolean determining if the plugin is enabled or not.
    enabled = false,
}

---Toggle the plugin by calling the `enable`/`disable` methods respectively.
---@private
function PaddyNvim.toggle()
    if S.enabled then
        return PaddyNvim.disable()
    end

    return PaddyNvim.enable()
end

---Initializes the plugin.
---@private
function PaddyNvim.enable()
    if S.enabled then
        return S
    end

    S.enabled = true

    return S
end

---Disables the plugin and reset the internal state.
---@private
function PaddyNvim.disable()
    if not S.enabled then
        return S
    end

    -- reset the state
    S = {
        enabled = false,
    }

    return S
end

return PaddyNvim
