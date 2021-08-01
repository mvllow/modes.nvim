local utils = {}

local function hexToRgb(hex_str)
	local hex = "[abcdef0-9][abcdef0-9]"
	local pat = "^#(" .. hex .. ")(" .. hex .. ")(" .. hex .. ")$"
	hex_str = string.lower(hex_str)

	assert(string.find(hex_str, pat) ~= nil, "hex_to_rgb: invalid hex_str: " .. tostring(hex_str))

	local r, g, b = string.match(hex_str, pat)
	return { tonumber(r, 16), tonumber(g, 16), tonumber(b, 16) }
end

---@param fg string foreground color
---@param bg string background color
---@param alpha number number between 0 and 1. 0 results in bg, 1 results in fg
function utils.blend(fg, bg, alpha)
	bg = hexToRgb(bg)
	fg = hexToRgb(fg)

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
