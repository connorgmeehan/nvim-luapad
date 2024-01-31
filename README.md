<p align="center">
  <h1 align="center">PaddyNvim</h2>
</p>

<p align="center">
    > Next Generation of LuaPad
</p>

<!-- <div align="center"> -->
<!---->
<!-- > Videos don't work on GitHub mobile, so a GIF alternative can help users. -->
<!---->
<!-- _[GIF version of the showcase video for mobile users](SHOWCASE_GIF_LINK)_ -->
<!---->
<!-- </div> -->

## ⚡️ Features

> Write short sentences describing your plugin features

- FEATURE 1
- FEATURE ..
- FEATURE N

## 📋 Installation

<div align="center">
<table>
<thead>
<tr>
<th>Package manager</th>
<th>Snippet</th>
</tr>
</thead>
<tbody>
<tr>
<td>

[folke/lazy.nvim](https://github.com/folke/lazy.nvim)

</td>
<td>

```lua
-- stable version
require("lazy").setup({{"connorgmeehan/paddynvim"}})
-- dev version
require("lazy").setup({"connorgmeehan/paddynvim", branch = "dev"})
```

</td>
</tr>
</tbody>
</table>
</div>

## ☄ Getting started

> Install and setup the plugin, then run the `:Paddy` command.

## ⚙ Configuration

<details>
<summary>Click to unfold the full list of options with their default values</summary>

> **Note**: The options are also available in Neovim by calling `:h paddynvim.options`

```lua
require("paddynvim").setup({
    -- Prints useful logs about what event are triggered, and reasons actions are executed.
    debug = false,

    ---@type function Callback function called after creating new Paddy instance.
    on_init = nil,
    ---@type table The default context tbl in which luapad buffer is evaluated. Its properties will be available in buffer as "global" variables.
    context = nil,

    ---@type table Options related to preview windows
    preview = {
        ---@type boolean Show floating output window on cursor hold. It's a good idea to set low update time. For example: `let &updatetime = 300` You can jump to it by `^w` `w`.
        enabled = true,
        ---@type number minimum height of the preview window.
        min_height = 10,
        ---@type number maximum height of the preview window.
        max_height = 30,
    },

    ---@type PaddyIntegration[] List of integrations to attach to the Paddy buffer. The Evaluator is the default integration and is always active.
    integrations = { Evaluator },

    ---@type number Luapad uses count hook method to prevent infinite loops occurring during code execution. Setting count_limit too high will make Luapad laggy, setting it too low, may cause premature code termination.
    count_limit = 2 * 1e5,
    ---@type boolean Show virtual text with error message (except syntax or timeout. errors).
    error_indicator = true,
    ---@type string Highlight group used to coloring luapad print output.
    print_highlight = "Comment",
    ---@type string Highlight group used to coloring luapad error indicator.
    error_highlight = "ErrorMsg",
    ---@type boolean Evaluate all luapad buffers when the cursor moves.
    eval_on_move = false,
    ---@type boolean Evaluate buffer content when it changes.
    eval_on_change = true,
    ---@type 'split'|'vsplit' The orientation of the split created by `Luapad` command. Can be `vertical` or `horizontal`.
    split_orientation = "vsplit",
    ---@type boolean The Luapad buffer by default is wiped out after closing/loosing a window. If you're used to switching buffers, and you want to keep Luapad instance alive in the background, set it to false.
    wipe = true,
})
```

</details>

## 🧰 Commands

|   Command   |         Description                 |
|-------------|-------------------------------------|
|  `:Paddy`   |     Creates a new paddy buffer .    |

## ⚙ Integrations

PaddyNvim is extensible via integrations.

### CPML (Linear Algebra and Vector Math)

Vendored from the [cpml](https://github.com/excessive/cpml) math library, it will inject linear algebra and vector math primitives into the 
context of all your paddy pads.

#### Enabling 

```lua
local cpml = require('paddynvim.integrations.cpml')
require('paddynvim').setup({
    integrations = { cpml },
})
```

#### Using
```lua
--- In a paddy buffer.
local vec2 = cpml.vec2

local v1 = vec2.new(5, 10)
local v2 = vec2. new(10, 5)
print(v1 + v2) -- (+15.000,+15.000)
```

## ⌨ Contributing

PRs and issues are always welcome. Make sure to provide as much context as possible when opening one.

## 🗞 Wiki

You can find guides and showcase of the plugin on [the Wiki](https://github.com/YOUR_GITHUB_USERNAME/YOUR_REPOSITORY_NAME/wiki)

## 🎭 Motivations

> 

## Special thanks

The idea and basically all the sourcecode was ripped from [rafcamlet](https://github.com/rafcamlet/nvim-luapad).  I just updated some API
calls and added a vector math integration.
