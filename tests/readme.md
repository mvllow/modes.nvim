# Testing

Tests use [mini.test](https://github.com/echasnovski/mini.test). Each case runs
in a fresh child Neovim over RPC, so global state (highlights, autocmds) stays
isolated between cases.

## Running Tests

To run tests, refer to the `Makefile` in the root directory of this project. Once there, run `make test` to begin tests.

If dependencies get into a bad state, wipe them and let the next run refetch:

```sh
make clean
```

To run a single case interactively, load the init and put the cursor on the
case:

```vim
:luafile scripts/minimal-init.lua
:lua require('mini.test').setup()
:lua MiniTest.run_at_location()
```

## Creating Tests

Add new files to `tests/`, named `test_*.lua` — the runner collects
`tests/**/test_*.lua` automatically.

Tests use the native `MiniTest.new_set()` style. A set is a table; assign cases
as functions and `return` the set:

```lua
local new_set = MiniTest.new_set
local expect = MiniTest.expect

local child = MiniTest.new_child_neovim()

local T = new_set({
	hooks = {
		pre_case = function()
			child.restart({ '-u', 'scripts/minimal-init.lua' })
		end,
		post_once = function()
			child.stop()
		end,
	},
})

T['example'] = new_set()

T['example']['setup does not error'] = function()
	expect.no_error(function()
		child.lua([[require('modes').setup()]])
	end)
end

return T
```

Drive the child with `child.type_keys(...)` for real input and read state back
through `child.api` / `child.lua_get`. See `test_modes.lua` and
`test_ui.lua` for worked examples.

## Adding Dependencies

In the `Makefile`, new dependencies can be added under `install_dependencies`:

```
.PHONY: install_dependencies
install_dependencies:
	...
	git clone --depth=1 https://github.com/MunifTanjim/nui.nvim.git ${DEPENDENCIES_DIR}/nui.nvim
```

To verify all dependencies get installed, run `make install_dependencies`.
