# modes.nvim

> !! Currently in alpha. Many things are broken. Neovim will randomly crash. !!

Highlight UI elements based on current mode. Inspired by the recent addition of vim mode in Xcode-beta.

## Usage

```lua
use({
  'mvllow/modes.nvim',
  config = function()
    require('modes').setup()
  end
})
```

## Options

In the future, highlight groups will be customizable. More documentation coming soon!

## Known issues

Some Which Key presets conflict with this plugin.

Workaround:

```lua
require('which-key').setup({
  plugins = {
    presets = {
      -- Disable operators
      operators = false,
    },
  },
})
```
