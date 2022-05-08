# Testing

> Refer to the project's `Makefile` for all available options

## Running Tests

To run tests, refer to the `Makefile` in the root directory of this project. Once there, run `make test` to begin tests.


```sh
make test
```

If there are issues with dependencies then a clean operation can be ran:


```sh
make clean
```

## Creating Tests

Add new test files to `tests/`, ensuring the filename ends with `spec`. E.g.  `my_test_spec.lua`. This new file will automatically be added to the tests.

Example test:

```lua
describe('small test', function()
	describe('compare text', function()
		it('should return true that the the text is the same', function()
			local text = 'some text'

			assert.are.equal(text, 'some text')
		end)
	end)
end)
```

Example output from `make test`:

```
git clone --depth=1 https://github.com/nvim-lua/plenary.nvim.git dependencies/pack/vendor/start/plenary.nvim
Cloning into 'dependencies/pack/vendor/start/plenary.nvim'...
remote: Enumerating objects: 170, done.
remote: Counting objects: 100% (170/170), done.
remote: Compressing objects: 100% (151/151), done.
remote: Total 170 (delta 6), reused 129 (delta 4), pack-reused 0
Receiving objects: 100% (170/170), 146.36 KiB | 269.00 KiB/s, done.
Resolving deltas: 100% (6/6), done.
git clone --depth=1 https://github.com/mvllow/modes.nvim.git dependencies/pack/vendor/start/modes.nvim
Cloning into 'dependencies/pack/vendor/start/modes.nvim'...
remote: Enumerating objects: 9, done.
remote: Counting objects: 100% (9/9), done.
remote: Compressing objects: 100% (8/8), done.
remote: Total 9 (delta 0), reused 6 (delta 0), pack-reused 0
Receiving objects: 100% (9/9), done.
nvim --headless --noplugin -u tests/minimal.vim -c "call Test()"
Starting...Scheduling: ./tests/init_spec.lua

========================================
Testing:        .../tests/init_spec.lua
Success ||      small test compare text it should return true that the the text is the same

Success:        1
Failed :        0
Errors :        0
========================================

[Process exited 0]
```

## Adding Dependencies

In the `Makefile`, new dependencies can be added under `install_dependencies`:

```
.PHONY: install_dependencies
install_dependencies:
	...
	git clone --depth=1 https://github.com/MunifTanjim/nui.nvim.git ${DEPENDENCIES_VENDOR}/start/nui.nvim
```
To verify all dependencies get installed, run `make install_dependencies`.
