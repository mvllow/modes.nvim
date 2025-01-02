.PHONY: docs
docs:
	@echo "Generating documentation..."
	@nvim --headless --noplugin -u ./scripts/minimal-init.lua -c "luafile scripts/minidoc.lua" -c "qa!"
