DEPENDENCIES_DIR:=dependencies
NVIM_HEADLESS:=nvim --headless --noplugin -u tests/minimal.vim

.PHONY: install_dependencies
install_dependencies:
	git clone --depth=1 https://github.com/nvim-lua/plenary.nvim ${DEPENDENCIES_DIR}/pack/vendor/start/plenary.nvim
	git clone --depth=1 https://github.com/mvllow/modes.nvim.git ${DEPENDENCIES_DIR}/pack/vendor/start/modes.nvim

.PHONY: clear_dependencies
clear_dependencies:
	rm -rf "${DEPENDENCIES_DIR}"

.PHONY: clean
clean: clear_dependencies

.PHONY: test
test: clean
	echo "$(shell pwd)"
	$(NVIM_HEADLESS) -c "call Test()"
