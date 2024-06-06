# modes.nvim

> Prismatic line decorations for the adventurous vim user

## Usage

```lua
use({
	'mvllow/modes.nvim',
	tag = 'v0.2.0',
	config = function()
		require('modes').setup()
	end
})
```

![modes.nvim](https://user-images.githubusercontent.com/1474821/127896095-6da221cf-3327-4eed-82be-ce419bdf647c.gif)

## Options

```lua
require('modes').setup({
	colors = {
		bg = "", -- Optional bg param, defaults to Normal hl group
		copy = "#f5c359",
		delete = "#c75c6a",
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

	-- Disable modes highlights in specified filetypes
	-- Please PR commonly ignored filetypes
	ignore_filetypes = { 'NvimTree', 'TelescopePrompt' }
})
```

## Themes

| Highlight group | Default value   |
| --------------- | --------------- |
| `ModesCopy`     | `guibg=#f5c359` |
| `ModesDelete`   | `guibg=#c75c6a` |
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
