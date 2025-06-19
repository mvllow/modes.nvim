# modes.nvim

> Prismatic line decorations for the adventurous vim user

## Usage

```lua
use({
	'mvllow/modes.nvim',
	tag = 'v0.2.1',
	config = function()
		require('modes').setup()
	end
})
```

![modes.nvim](https://user-images.githubusercontent.com/1474821/127896095-6da221cf-3327-4eed-82be-ce419bdf647c.gif)

## Requirements

- **Neovim 0.11** or later

## Options

```lua
require('modes').setup({
	colors = {
		bg = "", -- Optional bg param, defaults to Normal hl group
		copy = "#f5c359",
		delete = "#c75c6a",
		change = "#c75c6a", -- Optional param, defaults to delete
		insert = "#78ccc5",
		visual = "#9745be",
	},

	-- Set opacity for cursorline and number background
	line_opacity = 0.15,

	-- Enable cursor highlights
	set_cursor = true,

	-- Enable cursorline initially, and disable cursorline for inactive windows
	-- or ignored filetypes
	set_cursorline = true,

	-- Enable line number highlights to match cursorline
	set_number = true,

	-- Enable sign column highlights to match cursorline
	set_signcolumn = true,

	-- Disable modes highlights for specified filetypes
	-- or enable with prefix "!" if otherwise disabled (please PR common patterns)
	-- Can also be a function fun():boolean that disables modes highlights when true
	ignore = { 'NvimTree', 'TelescopePrompt', '!minifiles' }
})
```

## Themes

| Highlight group | Default value   |
| --------------- | --------------- |
| `ModesCopy`     | `guibg=#f5c359` |
| `ModesDelete`   | `guibg=#c75c6a` |
| `ModesChange`   | `ModesDelete`   |
| `ModesInsert`   | `guibg=#78ccc5` |
| `ModesVisual`   | `guibg=#9745be` |

## Known issues

- Some _Which Key_ presets conflict with this plugin. For example, `d` and `y` operators will not apply highlights if there are `d` and `y` prefixes hooked by _Which Key_ because _Which Key_ takes priority

_Workaround:_

```lua
require('which-key').setup({
        triggers_blacklist = {
                n = { "d", "y" }
        }
})
```
