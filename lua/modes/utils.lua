local M = {}

local function get_byte(value, offset)
	return bit.band(bit.rshift(value, offset), 0xFF)
end

local function get_color(color)
	color = vim.api.nvim_get_color_by_name(color)

	if color == -1 then
		color = vim.opt.background:get() == 'dark' and 000 or 255255255
	end

	return { get_byte(color, 16), get_byte(color, 8), get_byte(color, 0) }
end

---@param fg string foreground color
---@param bg string background color
---@param alpha number number between 0 and 1. 0 results in bg, 1 results in fg
M.blend = function(fg, bg, alpha)
	bg = get_color(bg)
	fg = get_color(fg)

	local blendChannel = function(i)
		local ret = (alpha * fg[i] + ((1 - alpha) * bg[i]))
		return math.floor(math.min(math.max(0, ret), 255) + 0.5)
	end

	return string.format(
		'#%02X%02X%02X',
		blendChannel(1),
		blendChannel(2),
		blendChannel(3)
	)
end

M.hl = function(group, color)
	local fg = color.fg and 'guifg=' .. color.fg or 'guifg=NONE'
	local bg = color.bg and 'guibg=' .. color.bg or 'guibg=NONE'

	local hl = 'hi ' .. group .. ' ' .. fg .. ' ' .. bg

	vim.cmd(hl)
	if color.link then
		vim.cmd('hi! link ' .. group .. ' ' .. color.link)
	end
end

M.get_fg_from_hl = function(hl_name, fallback)
	local id = vim.api.nvim_get_hl_id_by_name(hl_name)
	if not id then
		return fallback
	end

	local foreground = vim.fn.synIDattr(id, 'fg')
	if not foreground or foreground == '' then
		return fallback
	end

	return foreground
end

M.get_bg_from_hl = function(hl_name, fallback)
	local id = vim.api.nvim_get_hl_id_by_name(hl_name)
	if not id then
		return fallback
	end

	local background = vim.fn.synIDattr(id, 'bg')
	if not background or background == '' then
		return fallback
	end

	return background
end

M.get_termcode = function(key)
	return vim.api.nvim_replace_termcodes(key, true, true, true)
end

return M
