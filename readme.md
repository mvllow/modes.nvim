# modes.nvim

> Prismatic line decorations for the adventurous vim user

## Usage

```lua
{
	"mvllow/modes.nvim",
	tag = "v0.3.0",
}
```

![modes.nvim](https://user-images.githubusercontent.com/1474821/127896095-6da221cf-3327-4eed-82be-ce419bdf647c.gif)

## Options

> Setup is not required unless changing these values

```lua
require('modes').setup({
	colors = {
		bg      = "Normal",
		copy    = "#ecb441",
		delete  = "#ef4377",
		insert  = "#42c2de",
		replace = "#b6df71",
		visual  = "#bca3ff",
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

	-- Enable signcolumn highlights to match cursorline
	set_signcolumn = true,

	-- Disable modes highlights in specified filetypes
	ignore_filetypes = {}
})
```

## Themes

| Highlight group | Default value   |
| --------------- | --------------- |
| `ModesCopy`     | `guibg=#ecb441` |
| `ModesDelete`   | `guibg=#ef4377` |
| `ModesInsert`   | `guibg=#42c2de` |
| `ModesReplace`  | `guibg=#b6df71` |
| `ModesVisual`   | `guibg=#bca3ff` |

## Known issues

- [which-key.nvim](https://github.com/folke/which-key.nvim) takes priority for `d` and `y` operators, preventing Modes from effectively applying highlights.

_Workaround:_

```lua
-- Disable d and y triggers
require("which-key").setup({
        triggers_blacklist = {
                n = { "d", "y" }
        }
})
```

## Contributing

Pull requests are welcome and appreciated!

### Generating documentation

Inside of Neovim, with [mini.doc](https://github.com/echasnovski/mini.doc) in your runtimepath:

```lua
:luafile scripts/minidoc.lua
```
