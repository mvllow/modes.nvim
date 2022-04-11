local M = {}

---Get normalised colour
---@param name string like 'pink' or '#fa8072'
---@return string[]
M.get_color = function(name)
	local color = vim.api.nvim_get_color_by_name(name)
	if color == -1 then
		color = vim.opt.background:get() == 'dark' and 000 or 255255255
	end

	return {
		bit.rshift(color, 16),
		bit.band((bit.rshift(color, 8)), 0xff),
		bit.band(color, 0xff),
	}
end

---Get visually transparent colour
---@param fg string like 'pink' or '#fa8072'
---@param bg string like 'pink' or '#fa8072'
---@param alpha integer number between 0 and 1
---@return string
M.blend = function(fg, bg, alpha)
	---@param i integer
	---@return integer
	local channel = function(i)
		local ret = (
			alpha * M.get_color(fg)[i] + ((1 - alpha) * M.get_color(bg)[i])
		)
		return math.floor(math.min(math.max(0, ret), 255) + 0.5)
	end

	return string.format('#%02x%02x%02x', channel(1), channel(2), channel(3))
end

---Replace terminal keycodes
---@param key string like '<esc>'
---@return string
M.replace_termcodes = function(key)
	return vim.api.nvim_replace_termcodes(key, true, true, true)
end

---@class Color
---@field bg string
---@field fg string
---@field link string

---Get highlight
---@param name string
---@param fallback Color
---@return Color
M.get_hl = function(name, fallback)
	local ok, hl = pcall(vim.api.nvim_get_hl_by_name, name, true)
	if not ok then
		return fallback or { bg = 'none', fg = 'none' }
	end

	return {
		bg = hl.background and ('#%06x'):format(hl.background) or 'none',
		fg = hl.foreground and ('#%06x'):format(hl.foreground) or 'none',
	}
end

---Set highlight
---@param name string
---@param color Color
M.set_hl = function(name, color)
	if color.link ~= nil then
		vim.cmd('hi ' .. name .. ' guibg=none guifg=none')
		vim.cmd('hi! link ' .. name .. ' ' .. color.link)
		return
	end

	local bg = color.bg or 'none'
	local fg = color.fg or 'none'

	vim.cmd('hi ' .. name .. ' guibg=' .. bg .. ' guifg=' .. fg)
end

return M
