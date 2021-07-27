# modes.nvim

> !! Currently in alpha. Things may break !!

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

![Jul-27-2021 13-19-12](https://user-images.githubusercontent.com/1474821/127207394-0cca49b9-1cb0-4869-9310-9f9a922d3da0.gif)

## Options

In the future, highlight groups will be customizable. More documentation coming soon!

## Known issues

- Some Which Key presets conflict with this plugin. For example, `d` and `y` operators will not apply highlights if `operators = true` because Which Key takes priority

**Workaround**

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

- Line highlights are applied to all buffers, not just the active one
