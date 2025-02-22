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
--- Modes setup can be called with your `config` table to modify default
--- behaviour.
---
--- See |Modes.config| for `config` options and default values.

---@alias Scene 'copy'|'delete'|'insert'|'normal'|'replace'|'visual'

local Modes = {}
local H = {}

local winhighlight_cache = {}
local color_cache = {}

H.clear_color_cache = function()
	color_cache = {}
	winhighlight_cache = {}
end

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
	Modes.config = vim.tbl_deep_extend("force", vim.deepcopy(Modes.config), config or {})

	H.set_vim_options()
	H.set_initial_colors()
	H.detect_mode_changes()
end

--- Module config
---
--- Default values:
---@eval return MiniDoc.afterlines_to_code(MiniDoc.current.eval_section)
Modes.config = {
	copy = { enable = true, color = nil, opacity = 0.15 },
	delete = { enable = true, color = nil, opacity = 0.15 },
	insert = { enable = true, color = nil, opacity = 0.15 },
	replace = { enable = true, color = nil, opacity = 0.15 },
	visual = { enable = true, color = nil, opacity = 0.15 },
	ui = {
		cursor = true,
		cursorline = true,
		modemsg = true,
		number = true,
		signcolumn = true,
	},
	-- Unlisted buffers are ignored by default
	ignore_filetypes = {},
}
--minidoc_afterlines_end

Modes.enable = function(config)
	config = config or Modes.config

	if config.ui.cursor then
		vim.opt.guicursor:append("v-sm:ModesVisual")
		vim.opt.guicursor:append("i-ci-ve:ModesInsert")
		vim.opt.guicursor:append("r-cr-o:ModesOperator")
	end

	H.detect_mode_changes()
end

Modes.disable = function(config)
	config = config or Modes.config

	if config.ui.cursor then
		vim.opt.guicursor:remove("v-sm:ModesVisual")
		vim.opt.guicursor:remove("i-ci-ve:ModesInsert")
		vim.opt.guicursor:remove("r-cr-o:ModesOperator")
	end

	H.detect_mode_changes(false)
	H.clear_color_cache()
end

Modes.toggle = function()
	if H.is_enabled() then
		Modes.disable()
	else
		Modes.enable()
	end
end

Modes.reset = function()
	H.current_scene = nil
	H.apply_scene("normal")
end

H.set_vim_options = function()
	if Modes.config.ui.cursor then
		vim.opt.guicursor:append("v-sm:ModesVisual")
		vim.opt.guicursor:append("i-ci-ve:ModesInsert")
		vim.opt.guicursor:append("r-cr-o:ModesOperator")
	end

	if Modes.config.ui.cursorline then
		vim.o.cursorline = true
	end

	if Modes.config.ui.modemsg then
		vim.o.showmode = true
	end

	if Modes.config.ui.number then
		vim.o.number = true
	end
end

H.set_initial_colors = function()
	local fallback_bg = (vim.o.background == "dark" and "#000000" or "#FFFFFF")
	local bg = H.get_highlight_color("Normal", fallback_bg)
	if bg == "NONE" or bg == "" or bg == nil then
		bg = fallback_bg
	end

	local colors = {
		copy = Modes.config.copy.color or H.get_highlight_color("ModesCopy", "#ecb441"),
		delete = Modes.config.delete.color or H.get_highlight_color("ModesDelete", "#ef4377"),
		insert = Modes.config.insert.color or H.get_highlight_color("ModesInsert", "#42c2de"),
		replace = Modes.config.replace.color or H.get_highlight_color("ModesReplace", "#b6df71"),
		visual = Modes.config.visual.color or H.get_highlight_color("ModesVisual", "#bca3ff"),
	}
	local blended_colors = {
		copy = H.blend(colors.copy, bg, Modes.config.copy.opacity),
		delete = H.blend(colors.delete, bg, Modes.config.delete.opacity),
		insert = H.blend(colors.insert, bg, Modes.config.insert.opacity),
		replace = H.blend(colors.replace, bg, Modes.config.replace.opacity),
		visual = H.blend(colors.visual, bg, Modes.config.visual.opacity),
	}

	for _, mode in ipairs({ "Copy", "Delete", "Insert", "Replace", "Visual" }) do
		local scene = mode:lower()
		if Modes.config[scene].enable then
			local color = colors[scene]
			local blended_color = blended_colors[scene]

			H.set_highlight(("Modes%s"):format(mode), { bg = color })
			H.set_highlight(("Modes%sCursorLine"):format(mode), { bg = blended_color }, "CursorLine")
			H.set_highlight(("Modes%sCursorLineFold"):format(mode), { bg = blended_color }, "CursorLineFold")
			H.set_highlight(("Modes%sCursorLineNr"):format(mode), { fg = color, bg = blended_color }, "CursorLineNr")
			H.set_highlight(("Modes%sCursorLineSign"):format(mode), { bg = blended_color }, "CursorLineSign")
			H.set_highlight(("Modes%sModeMsg"):format(mode), { fg = color }, "ModeMsg")
		end
	end

	if Modes.config.replace.enable then
		H.set_highlight("ModesReplaceVisual", { bg = blended_colors.replace }, "Visual")
	end
	if Modes.config.visual.enable then
		H.set_highlight("ModesVisualVisual", { bg = blended_colors.visual }, "Visual")
	end
end

---@param scene Scene
---@private
H.apply_scene = function(scene)
	if scene == H.current_scene or H.in_ignored_buffer() then
		return
	end
	H.current_scene = scene

	if Modes.config.ui.cursor then
		if scene == "copy" then
			H.set_highlight("ModesOperator", { link = "ModesCopy" })
		elseif scene == "delete" then
			H.set_highlight("ModesOperator", { link = "ModesDelete" })
		elseif scene == "replace" then
			H.set_highlight("ModesOperator", { link = "ModesReplace" })
		else
			H.set_highlight("ModesOperator", {})
		end
	end

	if Modes.config.ui.modemsg then
		if scene == "insert" then
			H.set_highlight("ModeMsg", { link = "ModesInsertModeMsg" })
		elseif scene == "replace" then
			H.set_highlight("ModeMsg", { link = "ModesReplaceModeMsg" })
		elseif scene == "visual" then
			H.set_highlight("ModeMsg", { link = "ModesVisualModeMsg" })
		end
	end

	if winhighlight_cache[scene] then
		vim.api.nvim_set_option_value("winhighlight", winhighlight_cache[scene], { win = 0 })
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

	if not Modes.config.ui.number then
		winhl_map.CursorLineNr = nil
	end

	if not Modes.config.ui.signcolumn then
		winhl_map.CursorLineSign = nil
	end

	local new_value = {}
	for builtin, hl in pairs(winhl_map) do
		table.insert(new_value, ("%s:%s"):format(builtin, hl))
	end

	local result = table.concat(new_value, ",")
	winhighlight_cache[scene] = result

	vim.api.nvim_set_option_value("winhighlight", result, { win = 0 })
end

H.detect_mode_changes = function(enable)
	local group_name = "ModesEventListener"
	pcall(vim.api.nvim_del_augroup_by_name, group_name)

	local group = vim.api.nvim_create_augroup(group_name, { clear = true })

	if enable == false then
		vim.api.nvim_create_autocmd("BufLeave", {
			group = group,
			pattern = "*",
			callback = function()
				if not H.in_ignored_buffer() then
					H.detect_mode_changes()
				end
			end,
		})
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

		-- Reset on escape
		if key == "\x1b" then
			operator_mode_active = false
			replace_mode_active = false
			Modes.reset()
			H.current_scene = nil

			if interrupted_scene ~= nil then
				H.current_scene = interrupted_scene
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
				operator_mode_active = true
				return
			end

			if key == "d" then
				H.apply_scene("delete")
				operator_mode_active = true
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

	vim.api.nvim_create_autocmd("ColorScheme", {
		group = group,
		pattern = "*",
		callback = function()
			H.clear_color_cache()
			H.set_initial_colors()
		end,
	})

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

	vim.api.nvim_create_autocmd({ "CmdlineLeave", "InsertLeave", "WinLeave" }, {
		group = group,
		pattern = "*",
		callback = function()
			operator_mode_active = false
			Modes.reset()
		end,
	})

	vim.api.nvim_create_autocmd({ "BufEnter" }, {
		group = group,
		pattern = "*",
		callback = function()
			if not H.is_enabled() then
				return
			end

			if H.in_ignored_buffer() then
				Modes.disable()
			else
				Modes.enable()
			end
		end,
	})
end

H.normalize_color = function(color)
	local num_color = vim.api.nvim_get_color_by_name(color)
	if num_color == -1 then
		num_color = vim.o.background == "dark" and 0x000000 or 0xFFFFFF
	end

	return {
		bit.band(bit.rshift(num_color, 16), 0xFF),
		bit.band(bit.rshift(num_color, 8), 0xFF),
		bit.band(num_color, 0xFF),
	}
end

H.blend = function(fg, bg, alpha)
	local cache_key = fg .. bg .. tostring(alpha)
	if color_cache[cache_key] then
		return color_cache[cache_key]
	end

	local fg_color = H.normalize_color(fg)
	local bg_color = H.normalize_color(bg)

	local function blend_channel(i)
		return math.floor((alpha * fg_color[i] + (1 - alpha) * bg_color[i]) + 0.5)
	end

	local color = string.format("#%02X%02X%02X", blend_channel(1), blend_channel(2), blend_channel(3))
	color_cache[cache_key] = color
	return color
end

H.get_highlight_color = function(name, fallback, attr)
	local cache_key = name .. (attr or "bg")
	if color_cache[cache_key] then
		return color_cache[cache_key]
	end

	local color = vim.fn.synIDattr(vim.api.nvim_get_hl_id_by_name(name), attr or "bg")
	color = (color and color ~= "") and color or fallback
	color_cache[cache_key] = color
	return color
end

H.set_highlight = function(name, color, extended_name)
	if color.link ~= nil then
		vim.api.nvim_set_hl(0, name, { link = color.link, force = true })
		return
	end

	if extended_name then
		local extended_group = vim.api.nvim_get_hl(0, { name = extended_name })
		color = vim.tbl_deep_extend("force", extended_group, color)
	end

	vim.api.nvim_set_hl(0, name, color)
end

H.is_enabled = function()
	local enabled = false
	pcall(function()
		-- If this doesn't error, then the module is (hopefully) enabled
		vim.api.nvim_get_autocmds({ group = "ModesEventListener" })
		enabled = true
	end)
	return enabled
end

H.in_ignored_buffer = function()
	if vim.api.nvim_get_option_value("buftype", { buf = 0 }) ~= "" then
		return true
	end
	if not vim.api.nvim_get_option_value("buflisted", { buf = 0 }) then
		return true
	end
	return vim.tbl_contains(Modes.config.ignore_filetypes, vim.bo.filetype)
end

return Modes
