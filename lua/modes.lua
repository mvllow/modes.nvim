--- *modes.nvim* Prismatic line decorations for the adventurous vim user
--- *Modes*
---
--- MIT License Copyright (c) mvllow
---
--- ==============================================================================
---
--- Features:
---
--- - Highlight UI elements based on the current mode.
---
--- Manage module status:
---
--- - |Modes.enable()|
--- - |Modes.disable()|
--- - |Modes.toggle()|
---
--- # Setup ~
---
--- Modes does not require any setup but can be called with your `config` table
--- to modify default behaviour. This will create a global Lua table `Modes`
--- which you can use for scripting or manually (with `:lua Modes.*`)
---
--- See |Modes.config| for `config` options and default values.

---@alias Scene 'copy'|'delete'|'insert'|'normal'|'replace'|'visual'

local Modes = {}
local H = {}

H.winhighlight = {
	copy = {
		CursorLine = "ModesCopyCursorLine",
		CursorLineFold = "ModesCopyCursorLineFold",
		CursorLineNr = "ModesCopyCursorLineNr",
		CursorLineSign = "ModesCopyCursorLineSign",
	},
	delete = {
		CursorLine = "ModesDeleteCursorLine",
		CursorLineFold = "ModesDeleteCursorLineFold",
		CursorLineNr = "ModesDeleteCursorLineNr",
		CursorLineSign = "ModesDeleteCursorLineSign",
	},
	insert = {
		CursorLine = "ModesInsertCursorLine",
		CursorLineFold = "ModesInsertCursorLineFold",
		CursorLineNr = "ModesInsertCursorLineNr",
		CursorLineSign = "ModesInsertCursorLineSign",
	},
	normal = {
		CursorLine = "CursorLine",
		CursorLineFold = "CursorLineFold",
		CursorLineNr = "CursorLineNr",
		CursorLineSign = "CursorLineSign",
		Visual = "Visual",
	},
	replace = {
		CursorLine = "ModesReplaceCursorLine",
		CursorLineFold = "ModesReplaceCursorLineFold",
		CursorLineNr = "ModesReplaceCursorLineNr",
		CursorLineSign = "ModesReplaceCursorLineSign",
		Visual = "ModesReplaceVisual",
	},
	visual = {
		CursorLine = "ModesVisualCursorLine",
		CursorLineFold = "ModesVisualCursorLineFold",
		CursorLineNr = "ModesVisualCursorLineNr",
		CursorLineSign = "ModesVisualCursorLineSign",
		Visual = "ModesVisualVisual",
	},
}

--- Module setup
---
---@param config table|nil Module config table. See |Modes.config|.
---
---@usage `require('modes').setup({})` (replace `{}` with your `config` table)
Modes.setup = function(config)
	_G.Modes = Modes

	config = H.setup_config(config)

	H.apply_config(config)
	H.setup_colors()
	H.detect_mode_changes()
end

--- Module config
---
--- Default values:
---@eval return MiniDoc.afterlines_to_code(MiniDoc.current.eval_section)
Modes.config = {
	---@type table<string, string|nil>
	colors = {
		bg = nil,
		copy = nil,
		delete = nil,
		insert = nil,
		replace = nil,
		visual = nil,
	},
	-- Unlisted buffers are ignored by default
	ignore_filetypes = {},
	line_opacity = {
		copy = 0.15,
		delete = 0.15,
		insert = 0.15,
		replace = 0.15,
		visual = 0.15,
	},
	set_cursor = true,
	set_cursorline = true,
	set_modemsg = true,
	set_number = true,
	set_signcolumn = true,
}
--minidoc_afterlines_end

Modes.enable = function(config)
	config = config or Modes.config

	if config.set_cursor then
		vim.opt.guicursor:append("v-sm:ModesVisual")
		vim.opt.guicursor:append("i-ci-ve:ModesInsert")
		vim.opt.guicursor:append("r-cr-o:ModesOperator")
	end

	if config.set_cursorline then
		vim.opt.cursorline = true
	end

	H.detect_mode_changes()
end

Modes.disable = function(config)
	config = config or Modes.config

	if config.set_cursor then
		vim.opt.guicursor:remove("v-sm:ModesVisual")
		vim.opt.guicursor:remove("i-ci-ve:ModesInsert")
		vim.opt.guicursor:remove("r-cr-o:ModesOperator")
	end

	if config.set_cursorline then
		vim.opt.cursorline = false
	end

	H.detect_mode_changes(false)
end

Modes.toggle = function()
	local enabled = false
	pcall(function()
		-- If this doesn't error, then the module is (hopefully) enabled
		vim.api.nvim_get_autocmds({ group = "ModesEventListener" })
		enabled = true
	end)

	if enabled then
		Modes.disable()
	else
		Modes.enable()
	end
end

Modes.reset = function()
	H.apply_scene("normal")
end

-- Configuration

H.default_config = vim.deepcopy(Modes.config)

H.setup_config = function(config)
	config = vim.tbl_deep_extend("force", vim.deepcopy(H.default_config), config or {})

	if type(config.line_opacity) == "number" then
		config.line_opacity.copy = config.line_opacity
		config.line_opacity.delete = config.line_opacity
		config.line_opacity.insert = config.line_opacity
		config.line_opacity.replace = config.line_opacity
		config.line_opacity.visual = config.line_opacity
	end

	vim.validate({
		colors = { config.colors, "table" },
		ignore_filetypes = { config.ignore_filetypes, "table" },
		line_opacity = { config.line_opacity, "table" },
		set_cursor = { config.set_cursor, "boolean" },
		set_cursorline = { config.set_cursorline, "boolean" },
		set_modemsg = { config.set_modemsg, "boolean" },
		set_number = { config.set_number, "boolean" },
		set_signcolumn = { config.set_signcolumn, "boolean" },
	})

	return config
end

H.apply_config = function(config)
	Modes.config = config

	if config.set_cursor then
		vim.opt.guicursor:append("v-sm:ModesVisual")
		vim.opt.guicursor:append("i-ci-ve:ModesInsert")
		vim.opt.guicursor:append("r-cr-o:ModesOperator")
	end

	if config.set_cursorline then
		vim.opt.cursorline = true
	end

	if config.set_modemsg then
		vim.opt.showmode = true
		H.set_highlight("ModeMsg", { link = "ModesModeMsg" })
	end

	if config.set_number then
		vim.opt.number = true
		H.set_highlight("CursorLineNr", { link = "ModesCursorLineNr" })
	end

	if config.set_signcolumn then
		H.set_highlight("CursorLineSign", { link = "ModesCursorLineSign" })
	end
end

-- Implementation

H.setup_colors = function()
	local normal_bg = Modes.config.colors.bg or H.get_highlight_color("Normal", "NvimDarkGrey2")
	local colors = {
		copy = Modes.config.colors.copy or H.get_highlight_color("ModesCopy", "#ecb441"),
		delete = Modes.config.colors.delete or H.get_highlight_color("ModesDelete", "#ef4377"),
		insert = Modes.config.colors.insert or H.get_highlight_color("ModesInsert", "#42c2de"),
		replace = Modes.config.colors.replace or H.get_highlight_color("ModesReplace", "#b6df71"),
		visual = Modes.config.colors.visual or H.get_highlight_color("ModesVisual", "#bca3ff"),
	}
	local blended_colors = {
		copy = H.blend(colors.copy, normal_bg, Modes.config.line_opacity.copy),
		delete = H.blend(colors.delete, normal_bg, Modes.config.line_opacity.delete),
		insert = H.blend(colors.insert, normal_bg, Modes.config.line_opacity.insert),
		replace = H.blend(colors.replace, normal_bg, Modes.config.line_opacity.replace),
		visual = H.blend(colors.visual, normal_bg, Modes.config.line_opacity.visual),
	}

	for _, mode in ipairs({ "Copy", "Delete", "Insert", "Replace", "Visual" }) do
		local color = colors[mode:lower()]
		local blended_color = blended_colors[mode:lower()]

		H.set_highlight(("Modes%s"):format(mode), { bg = color })
		H.set_highlight(("Modes%sCursorLine"):format(mode), { bg = blended_color })
		H.set_highlight(("Modes%sCursorLineFold"):format(mode), { bg = blended_color })
		H.set_highlight(("Modes%sCursorLineNr"):format(mode), { fg = color, bg = blended_color, nocombine = false })
		H.set_highlight(("Modes%sCursorLineSign"):format(mode), { bg = blended_color })
	end

	H.set_highlight("ModesInsertModeMsg", { fg = colors.insert })
	H.set_highlight("ModesReplaceModeMsg", { fg = colors.replace })
	H.set_highlight("ModesReplaceVisual", { bg = blended_colors.replace })
	H.set_highlight("ModesVisualModeMsg", { fg = colors.visual })
	H.set_highlight("ModesVisualVisual", { bg = blended_colors.visual })
end

---@param scene Scene
---@private
H.apply_scene = function(scene)
	if H.in_ignored_buffer() then
		return
	end

	local winhl_map = {}
	local prev_value = vim.api.nvim_get_option_value("winhighlight", { win = 0 })

	if prev_value ~= "" then
		for _, winhl in ipairs(vim.split(prev_value, ",")) do
			local pair = vim.split(winhl, ":")
			winhl_map[pair[1]] = pair[2]
		end
	end

	for builtin, hl in pairs(H.winhighlight[scene]) do
		winhl_map[builtin] = hl
	end

	if not Modes.config.set_number then
		winhl_map.CursorLineNr = nil
	end

	if not Modes.config.set_signcolumn then
		winhl_map.CursorLineSign = nil
	end

	local new_value = {}
	for builtin, hl in pairs(winhl_map) do
		table.insert(new_value, ("%s:%s"):format(builtin, hl))
	end
	vim.api.nvim_set_option_value("winhighlight", table.concat(new_value, ","), { win = 0 })

	if Modes.config.set_cursor then
		if scene == "copy" then
			H.set_highlight("ModesOperator", { link = "ModesCopy" })
		elseif scene == "delete" then
			H.set_highlight("ModesOperator", { link = "ModesDelete" })
		elseif scene == "replace" then
			H.set_highlight("ModesOperator", { link = "ModesReplace" })
		else
			H.set_highlight("ModesOperator", { clear = true })
		end
	end

	if Modes.config.set_modemsg then
		if scene == "insert" then
			H.set_highlight("ModeMsg", { link = "ModesInsertModeMsg" })
		elseif scene == "replace" then
			H.set_highlight("ModeMsg", { link = "ModesReplaceModeMsg" })
		elseif scene == "visual" then
			H.set_highlight("ModeMsg", { link = "ModesVisualModeMsg" })
		end
	end
end

H.detect_mode_changes = function(enable)
	if enable ~= nil and enable == false then
		vim.api.nvim_del_augroup_by_name("ModesEventListener")
		return
	end

	---@type Scene|nil
	local interrupted_scene
	local operator_mode_active = false
	local replace_mode_active = false

	vim.on_key(function(key)
		local has_mode, current_mode = pcall(vim.fn.mode)
		if not has_mode then
			operator_mode_active = false
			Modes.reset()
			return
		end

		if replace_mode_active then
			replace_mode_active = false
			Modes.reset()
		end

		-- On escape
		if key == "\x1b" then
			Modes.reset()

			if interrupted_scene ~= nil then
				H.apply_scene(interrupted_scene)
				interrupted_scene = nil
			end

			return
		end

		if current_mode == "n" then
			if operator_mode_active then
				operator_mode_active = false
				Modes.reset()
				return
			end

			if key == "y" then
				H.apply_scene("copy")
				return
			end

			if key == "d" then
				H.apply_scene("delete")
				return
			end

			if key == "r" then
				replace_mode_active = true
				H.apply_scene("replace")
				return
			end
		end

		if current_mode == "v" or current_mode == "V" or current_mode == "\x16" then
			if key == "r" then
				replace_mode_active = true
				interrupted_scene = "visual"
				H.apply_scene("replace")
				return
			end
		end
	end)

	local group = vim.api.nvim_create_augroup("ModesEventListener", { clear = true })

	vim.api.nvim_create_autocmd("ColorScheme", {
		group = group,
		pattern = "*",
		callback = function()
			H.setup_colors()
		end,
	})

	-- Mode changes

	vim.api.nvim_create_autocmd("ModeChanged", {
		group = group,
		pattern = "*:no",
		callback = function()
			operator_mode_active = true
		end,
	})
	vim.api.nvim_create_autocmd("ModeChanged", {
		group = group,
		pattern = "no:*",
		callback = function()
			operator_mode_active = false
		end,
	})
	vim.api.nvim_create_autocmd("ModeChanged", {
		group = group,
		pattern = "*:i",
		callback = function()
			H.apply_scene("insert")
		end,
	})
	vim.api.nvim_create_autocmd("ModeChanged", {
		group = group,
		pattern = "*:R",
		callback = function()
			H.apply_scene("replace")
		end,
	})
	vim.api.nvim_create_autocmd("ModeChanged", {
		group = group,
		pattern = "*:[vV\x16]",
		callback = function()
			H.apply_scene("visual")
		end,
	})
	vim.api.nvim_create_autocmd("ModeChanged", {
		group = group,
		pattern = "*:n",
		callback = function()
			operator_mode_active = false
			Modes.reset()
		end,
	})

	vim.api.nvim_create_autocmd({ "CmdlineLeave", "InsertLeave", "TextYankPost", "WinLeave" }, {
		group = group,
		pattern = "*",
		callback = function()
			operator_mode_active = false
			Modes.reset()
		end,
	})
	vim.api.nvim_create_autocmd("BufEnter", {
		group = group,
		pattern = "*",
		callback = function()
			Modes.enable()
		end,
	})
	vim.api.nvim_create_autocmd("WinLeave", {
		group = group,
		pattern = "*",
		callback = function()
			Modes.disable()
		end,
	})
end

-- Utilities

H.normalize_color = function(name)
	local color = vim.api.nvim_get_color_by_name(name)
	if color == -1 then
		color = vim.o.background == "dark" and 0x000000 or 0xFFFFFF
	end

	return {
		bit.band(bit.rshift(color, 16), 0xFF),
		bit.band(bit.rshift(color, 8), 0xFF),
		bit.band(color, 0xFF),
	}
end

H.blend = function(fg, bg, alpha)
	local fg_color = H.normalize_color(fg)
	local bg_color = H.normalize_color(bg)

	local function blend_channel(i)
		return math.floor((alpha * fg_color[i] + (1 - alpha) * bg_color[i]) + 0.5)
	end

	return string.format("#%02X%02X%02X", blend_channel(1), blend_channel(2), blend_channel(3))
end

H.get_highlight_color = function(name, fallback, attr)
	local color = vim.fn.synIDattr(vim.api.nvim_get_hl_id_by_name(name), attr or "bg")
	return (color and color ~= "") and color or fallback
end

H.set_highlight = function(name, color)
	if color.link ~= nil then
		vim.api.nvim_set_hl(0, name, { link = color.link, force = true })
		return
	end

	vim.api.nvim_set_hl(0, name, { fg = color.fg, bg = color.bg, default = true })
end

H.in_ignored_buffer = function()
	return vim.api.nvim_get_option_value("buftype", { buf = 0 }) ~= ""
		or not vim.api.nvim_get_option_value("buflisted", { buf = 0 })
		or vim.tbl_contains(Modes.config.ignore_filetypes, vim.bo.filetype)
end

return Modes
