if vim.g.modes_loaded then
	return
end

vim.g.modes_loaded = true

require("modes").setup()
