local utils = {}

local function get_byte(value, offset)
	return bit.band(bit.rshift(value, offset), 0xFF)
end

local function get_color(color)
	color = vim.api.nvim_get_color_by_name(color)

	if color == -1 then
		color = vim.opt.background:get() == "dark" and 000 or 255255255
	end

	return { get_byte(color, 16), get_byte(color, 8), get_byte(color, 0) }
end

---@param fg string foreground color
---@param bg string background color
---@param alpha number number between 0 and 1. 0 results in bg, 1 results in fg
function utils.blend(fg, bg, alpha)
	bg = get_color(bg)
	fg = get_color(fg)

	local blendChannel = function(i)
		local ret = (alpha * fg[i] + ((1 - alpha) * bg[i]))
		return math.floor(math.min(math.max(0, ret), 255) + 0.5)
	end

	return string.format("#%02X%02X%02X", blendChannel(1), blendChannel(2), blendChannel(3))
end

function utils.get_fg_from_hl(hl_name, fallback)
	local id = vim.api.nvim_get_hl_id_by_name(hl_name)
	if not id then
		return fallback
	end

	local foreground = vim.fn.synIDattr(id, "fg")
	if not foreground or foreground == "" then
		return fallback
	end

	return foreground
end

function utils.get_bg_from_hl(hl_name, fallback)
	local id = vim.api.nvim_get_hl_id_by_name(hl_name)
	if not id then
		return fallback
	end

	local background = vim.fn.synIDattr(id, "bg")
	if not background or background == "" then
		return fallback
	end

	return background
end

function utils.get_termcode(key)
	return vim.api.nvim_replace_termcodes(key, true, true, true)
end

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
