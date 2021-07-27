local utils = {}

function utils.define_augroups(definitions)
	for group_name, definition in pairs(definitions) do
		vim.cmd("augroup " .. group_name)
		vim.cmd("autocmd!")

		for _, def in pairs(definition) do
			local command = table.concat(vim.tbl_flatten({ "autocmd", def }), " ")
			vim.cmd(command)
		end

		vim.cmd("augroup END")
	end
end

return utils
