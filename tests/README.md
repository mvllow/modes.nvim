# Running Tests

To run tests, refer to the `Makefile` in the root directory of this project. Once there, run `make test` to begin tests.

```sh
make test
```

If tests need to be ran repeatedly then using `make clean & make test` is required.

# Creating Tests

All tests should be within the `tests/` directory and have `spec` as the last part of the filename, so for example: `my_test_spec.lua`. It will then be automatically added to the tests.

This even works recursively in subdirectories within the `tests/` directory so long as the files are suffixed `spec` like above.

A very small example test:

```lua
describe('small test', function()
	describe('compare text', function()
		it('it should return true that the the text is the same', function()
			local text = 'some text'

			assert.are.equal(text, 'some text')
		end)
	end)
end)
```

Output from `make test`:

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

# Adding Dependencies

In the `Makefile` dependencies can be added in the `install_dependencies` section. For instance, if there is a new plugin dependency that needs to be added we can clone it into the dependencies directory.

For example, if [nui.nvim](https://github.com/MunifTanjim/nui.nvim) became a dependency we can add it like so:

```
.PHONY: install_dependencies
install_dependencies:
	...
	git clone --depth=1 https://github.com/MunifTanjim/nui.nvim.git ${DEPENDENCIES_VENDOR}/start/nui.nvim
```

To verify if the dependency gets installed properly, run `make install_dependencies` which will show git cloning the repositories under `install_dependencies`
