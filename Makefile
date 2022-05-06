DEPENDENCIES_DIR:=dependencies
DEPENDENCIES_VENDOR:=${DEPENDENCIES_DIR}/pack/vendor
NVIM_HEADLESS:=nvim --headless --noplugin -u tests/minimal.vim

.PHONY: install_dependencies
install_dependencies:
	git clone --depth=1 https://github.com/nvim-lua/plenary.nvim.git ${DEPENDENCIES_VENDOR}/start/plenary.nvim
	git clone --depth=1 https://github.com/mvllow/modes.nvim.git ${DEPENDENCIES_VENDOR}/start/modes.nvim

.PHONY: clear_dependencies
clear_dependencies:
	rm -rf "${DEPENDENCIES_DIR}"

.PHONY: clean
clean: clear_dependencies

.PHONY: test
test: install_dependencies
	$(NVIM_HEADLESS) -c "call Test()"
