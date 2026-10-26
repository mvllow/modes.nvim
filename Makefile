DEPENDENCIES_DIR:=dependencies

.PHONY: install_dependencies
install_dependencies:
	test -r ${DEPENDENCIES_DIR}/mini.test || git clone --depth=1 https://github.com/echasnovski/mini.test.git ${DEPENDENCIES_DIR}/mini.test
	test -r ${DEPENDENCIES_DIR}/mini.doc || git clone --depth=1 https://github.com/echasnovski/mini.doc.git ${DEPENDENCIES_DIR}/mini.doc

.PHONY: test
test: install_dependencies
	nvim --headless --noplugin -u scripts/minimal-init.lua -c "lua require('mini.test').setup()" -c "lua MiniTest.run()"

.PHONY: docs
docs: install_dependencies
	@echo "Generating documentation..."
	@nvim --headless --noplugin -u scripts/minimal-init.lua -c "luafile scripts/minidoc.lua" -c "qa!"

.PHONY: clean
clean:
	@echo "Removing temporary directories..."
	@rm -rf "${DEPENDENCIES_DIR}"
