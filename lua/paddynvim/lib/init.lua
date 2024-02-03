local array = require("paddynvim.util.array")
local D = require("paddynvim.util.debug")
local Evaluator = require("paddynvim.lib.evaluator")

---@class PaddyIntegrationMeta
---@field name string
---@field constructor function(config:Config,buffer_id:number):PaddyIntegration

--- Class for a paddy integration, Basically a bunch of functions representing the lifecycle of a paddy buffer.
---@class PaddyIntegration
---@field meta PaddyIntegrationMeta
---@field extra_context table? Add to the luapad context
---@field new function(config:Config,buffer_id:number): PaddyIntegration
--
---@field on_attach function(paddy:PaddyInstance,buffer_id:number)? Called when starting the integration
---@field on_detach function(buffer_id:number)? Called when stopping the integration
--
---@field on_pre_update function(buffer_id:number)? Called when the buffer changes
---@field on_update function(buffer_id:number)? Called when the buffer changes
---@field on_post_update function(buffer_id:number)? Called when the buffer changes
--
---@field on_focus function(buffer_id:number)? Called when the paddy buffer is focused
---@field on_blur function(buffer_id:number)? Called when the paddy buffer loses focus
--
---@field on_cursor_moved function(buffer_id:number)? Called anytime a cursor moves
---@field on_cursor_hold function(bufer_id: number)? Called anytime the CursorHold event triggers

--- The PaddyInstance class
---@class PaddyInstance
---@field P PaddyNvim
---@field active boolean Whether or not this instance is active
---@field buffer_id number The attached buffer
---@field integrations PaddyIntegration[]
---@field autocmd_group_ids number[]
local PaddyInstance = {}
PaddyInstance.__index = PaddyInstance

--- Creates a new paddy instance on a given buffer.
---@param plugin PaddyNvim The global table of the paddy plugin
---@param buffer_id number buffer to atttach to
function PaddyInstance:new(plugin, buffer_id)
    local integrations = array.array_map(plugin.config.integrations, function(_, integration)
        return integration.meta.constructor(plugin.config, buffer_id)
    end)

    local has_evaluator = array.array_some(integrations, function (_, int)
        return int.meta.name == "Evaluator"
    end)

    if not has_evaluator then
        array.array_push(integrations, Evaluator:new(plugin.config, buffer_id))
    end

    local fields = {
        P = plugin,
        active = true,
        buffer_id = buffer_id,
        integrations = integrations,
    }
    local instance = setmetatable(fields, PaddyInstance)
    plugin._state.instances[buffer_id] = instance

    return instance
end

--- Starts the PaddyInstance, binds all the events.
function PaddyInstance:start()
    local on_change = vim.schedule_wrap(function()
        if not self.active then
            return true
        end
        if self.P.config.eval_on_change then
            self:update()
        end
    end)

    local on_detach = vim.schedule_wrap(function()
        self:finish()
        self.P._state.instances[self.buffer_id] = nil
    end)

    vim.api.nvim_buf_attach(0, false, {
        on_lines = on_change,
        on_changedtick = on_change,
        on_detach = on_detach,
    })

    vim.api.nvim_command("augroup END")

    local self_group = vim.api.nvim_create_augroup(("LuapadAutogroupNr"):format(self.buffer_id), {
        clear = true,
    })
    vim.api.nvim_create_autocmd("BufEnter", {
        group = self_group,
        buffer = self.buffer_id,
        callback = function ()
            self:on_focus()
        end
    })
    vim.api.nvim_create_autocmd("BufLeave", {
        group = self_group,
        buffer = self.buffer_id,
        callback = function ()
            self:on_blur()
        end
    })
    vim.api.nvim_create_autocmd("CursorHold", {
        group = self_group,
        buffer = self.buffer_id,
        callback = function()
            self:on_cursor_hold()
        end,
    })
    vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
        group = self_group,
        buffer = self.buffer_id,
        callback = function()
            self:on_paddy_cursor_moved()
        end,
    })

    self.autocmd_group_ids = { self_group }

    for _, integration in ipairs(self.integrations) do
        D.log("trace", "Trying on attach for " .. integration.meta.name)
        local mt = getmetatable(integration)
        if mt and mt.__index and mt.__index.on_attach then
            integration:on_attach(self, self.buffer_id)
        end
    end

    if self.P.config.on_init then
        self.P.config.on_init()
    end
    self:update()
end

--- Stops the paddy instance, unbinds all the events.
function PaddyInstance:finish()
    self.P._state.instances[self.buffer_id] = nil
    self.active = false
    for _, id in ipairs(self.autocmd_group_ids) do
        vim.api.nvim_del_augroup_by_id(id)
    end
    for _, integration in ipairs(self.integrations) do
        local mt = getmetatable(integration)
        if mt and mt.__index and mt.__index.on_detach then
            integration.on_detach(self.buffer_id)
        end
    end
end

function PaddyInstance:on_cursor_moved()
    if not self.active then
        return
    end
    D.log("trace", "PaddyInstance:on_cursor_moved")
    for _, integration in ipairs(self.integrations) do
        local mt = getmetatable(integration)
        if mt and mt.__index and mt.__index.on_cursor_moved then
            integration:on_cursor_moved(self.buffer_id)
        end
    end
end

function PaddyInstance:update()
    if not self.active then
        return
    end
    D.log("trace", "PaddyInstance:update")
    for _, integration in ipairs(self.integrations) do
        local mt = getmetatable(integration)
        if mt and mt.on_pre_update then
            integration:on_pre_update(self.buffer_id)
        end
    end
    for _, integration in ipairs(self.integrations) do
        local mt = getmetatable(integration)
        D.log("trace", "PaddyInstance:update " .. integration.meta.name .. " = " .. vim.inspect(vim.tbl_keys(mt)))
        if mt and mt.on_update then
            integration:on_update(self.buffer_id)
        end
    end
    for _, integration in ipairs(self.integrations) do
        local mt = getmetatable(integration)
        if mt and mt.on_post_update then
            integration:on_post_update(self.buffer_id)
        end
    end
end

function PaddyInstance:on_cursor_hold()
    if not self.active then
        return
    end
    D.log("trace", "PaddyInstance:on_cursor_hold")
    for _, integration in ipairs(self.integrations) do
        local mt = getmetatable(integration)
        if mt and mt.__index and mt.__index.on_cursor_hold then
            integration:on_cursor_hold(self.buffer_id)
        end
    end
end

function PaddyInstance:on_paddy_cursor_moved()
    if not self.active then
        return
    end
    D.log("trace", "PaddyInstance:on_cursor_moved")
    for _, integration in ipairs(self.integrations) do
        local mt = getmetatable(integration)
        if mt and mt.__index and mt.__index.on_paddy_cursor_moved then
            integration:on_cursor_moved(self.buffer_id)
        end
    end
end

function PaddyInstance:on_focus()
    if not self.active then
        return
    end
    D.log("trace", "PaddyInstance:on_focus")
    for _, integration in ipairs(self.integrations) do
        local mt = getmetatable(integration)
        if mt and mt.__index and mt.__index.on_focus then
            integration:on_focus(self.buffer_id)
        end
    end
end

function PaddyInstance:on_blur()
    if not self.active then
        return
    end
    D.log("trace", "PaddyInstance:on_blur")
    for _, integration in ipairs(self.integrations) do
        local mt = getmetatable(integration)
        if mt and mt.__index and mt.__index.on_blur then
            integration:on_blur(self.buffer_id)
        end
    end
end

return PaddyInstance
