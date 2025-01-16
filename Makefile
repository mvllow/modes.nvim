.PHONY: docs
docs:
	@echo "Generating documentation..."
	@nvim --headless --noplugin -u ./scripts/minimal-init.lua -c "luafile scripts/minidoc.lua" -c "qa!"

.PHONY: clean
clean:
	@echo "Removing temporary directories..."
	@rm -rf "/tmp/nvim/site/pack/test/start/mini.doc"
