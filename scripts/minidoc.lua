local minidoc = require("mini.doc")

if _G.MiniDoc == nil then
	minidoc.setup()
end

local hooks = vim.deepcopy(minidoc.default_hooks)

hooks.write_pre = function(lines)
	-- Remove first two lines with `======` and `------` delimiters to comply
	-- with `:h local-additions` template
	table.remove(lines, 1)
	table.remove(lines, 1)
	return lines
end

minidoc.generate({ "lua/modes.lua" }, "doc/modes.txt", { hooks = hooks })
