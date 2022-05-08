local M = {}

--- Easier interface to send keys to nvim
---@param opts table
M.feed_keys = function(opts)
	vim.api.nvim_feedkeys(
		vim.api.nvim_replace_termcodes(
			opts.keys,
			true,
			false,
			opts.replace_keycodes or true
		),
		opts.mode or 'n',
		opts.escape_ks or true
	)
end

M.get_color = function (group, attr)
	return vim.fn.synIDattr(vim.fn.synIDtrans(vim.fn.hlID(group)), attr)
end

return M
