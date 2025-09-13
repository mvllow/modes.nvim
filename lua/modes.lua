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
--- # Setup ~
---
--- Modes setup can be called with your `config` table to modify default
--- behaviour.
---
--- See |Modes.config| for `config` options and default values.

---@alias Scene 'copy'|'delete'|'insert'|'normal'|'replace'|'visual'

local Modes = {}
local H = {}

local config = {}
local utils = require('modes.utils')

--- Module config
---
--- Default values:
---@eval return MiniDoc.afterlines_to_code(MiniDoc.current.eval_section)
local default_config = {
	colors = {},
	line_opacity = {
		copy = 0.15,
		delete = 0.15,
		change = 0.15,
		format = 0.15,
		insert = 0.15,
		replace = 0.15,
		select = 0.15,
		visual = 0.15,
		normal = 0.15,
	},
	set_cursor = true,
	set_cursorline = true,
	set_number = true,
	set_signcolumn = true,
	ignore = {
		'NvimTree',
		'lspinfo',
		'packer',
		'checkhealth',
		'help',
		'man',
		'TelescopePrompt',
		'TelescopeResults',
		'!minifiles',
	},
}
--minidoc_afterlines_end
--
local winhighlight = {
	default = {
		CursorLine = 'CursorLine',
		CursorLineNr = 'CursorLineNr',
		CursorLineSign = 'CursorLineSign',
		CursorLineFold = 'CursorLineFold',
		Visual = 'Visual',
	},
	copy = {
		CursorLine = 'ModesCopyCursorLine',
		CursorLineNr = 'ModesCopyCursorLineNr',
		CursorLineSign = 'ModesCopyCursorLineSign',
		CursorLineFold = 'ModesCopyCursorLineFold',
	},
	delete = {
		CursorLine = 'ModesDeleteCursorLine',
		CursorLineNr = 'ModesDeleteCursorLineNr',
		CursorLineSign = 'ModesDeleteCursorLineSign',
		CursorLineFold = 'ModesDeleteCursorLineFold',
	},
	change = {
		CursorLine = 'ModesChangeCursorLine',
		CursorLineNr = 'ModesChangeCursorLineNr',
		CursorLineSign = 'ModesChangeCursorLineSign',
		CursorLineFold = 'ModesChangeCursorLineFold',
	},
	format = {
		CursorLine = 'ModesFormatCursorLine',
		CursorLineNr = 'ModesFormatCursorLineNr',
		CursorLineSign = 'ModesFormatCursorLineSign',
		CursorLineFold = 'ModesFormatCursorLineFold',
	},
	insert = {
		CursorLine = 'ModesInsertCursorLine',
		CursorLineNr = 'ModesInsertCursorLineNr',
		CursorLineSign = 'ModesInsertCursorLineSign',
		CursorLineFold = 'ModesInsertCursorLineFold',
	},
	replace = {
		CursorLine = 'ModesReplaceCursorLine',
		CursorLineNr = 'ModesReplaceCursorLineNr',
		CursorLineSign = 'ModesReplaceCursorLineSign',
		CursorLineFold = 'ModesReplaceCursorLineFold',
		Visual = 'ModesReplaceVisual',
	},
	select = {
		CursorLine = 'ModesSelectCursorLine',
		CursorLineNr = 'ModesSelectCursorLineNr',
		CursorLineSign = 'ModesSelectCursorLineSign',
		CursorLineFold = 'ModesSelectCursorLineFold',
		Visual = 'ModesSelectVisual',
	},
	visual = {
		CursorLine = 'ModesVisualCursorLine',
		CursorLineNr = 'ModesVisualCursorLineNr',
		CursorLineSign = 'ModesVisualCursorLineSign',
		CursorLineFold = 'ModesVisualCursorLineFold',
		Visual = 'ModesVisualVisual',
	},
	normal = {
		CursorLine = 'ModesNormalCursorLine',
		CursorLineNr = 'ModesNormalCursorLineNr',
		CursorLineSign = 'ModesNormalCursorLineSign',
		CursorLineFold = 'ModesNormalCursorLineFold',
	},
}
local colors = {}
local blended_colors = {}
local in_ignored_buffer = function()
	if type(config.ignore) == 'function' then
		return config.ignore()
	end
	return not vim.tbl_contains(config.ignore, '!' .. vim.bo.filetype)
	    and (vim.api.nvim_get_option_value('buftype', { buf = 0 }) ~= '' -- not a normal buffer
		    or not vim.api.nvim_get_option_value('buflisted', { buf = 0 }) -- unlisted buffer
		    or vim.tbl_contains(config.ignore, vim.bo.filetype))
end

H.reset = function()
	H.highlight('default')
	vim.api.nvim_echo({}, false, {}) -- ensure mode-message highlight is updated
end

H.restore = function()
	local scene = H.get_scene()
	H.highlight(scene)
	vim.api.nvim_echo({}, false, {})
end

---@param scene 'default'|'copy'|'delete'|'change'|'format'|'insert'|'replace'|'select'|'visual'|'normal'
---@private
H.highlight = function(scene)
	if in_ignored_buffer() and scene ~= 'default' then
		return
	end

	local winhl_map = {}
	local prev_value = vim.api.nvim_get_option_value('winhighlight', { win = 0 })

	-- mapping the old value of 'winhighlight'
	if prev_value ~= '' then
		for _, winhl in ipairs(vim.split(prev_value, ',')) do
			local pair = vim.split(winhl, ':')
			winhl_map[pair[1]] = pair[2]
		end
	end

	-- overrides 'builtin':'hl' if the current scene has a mapping for it
	for builtin, hl in pairs(winhighlight[scene]) do
		winhl_map[builtin] = hl
	end

	if config.set_number then
		local detected_scene = H.get_scene()
		if scene == 'replace' and detected_scene == 'visual' then
			winhl_map.CursorLineNr = 'ModesVisualReplaceCursorLineNr'
		end
	else
		winhl_map.CursorLineNr = nil
	end

	if not config.set_signcolumn then
		winhl_map.CursorLineSign = nil
	end

	local new_value = {}
	for builtin, hl in pairs(winhl_map) do
		table.insert(new_value, ('%s:%s'):format(builtin, hl))
	end
	vim.api.nvim_set_option_value('winhighlight', table.concat(new_value, ','), { win = 0 })

	if vim.api.nvim_get_option_value('showmode', { scope = 'global' }) then
		if scene == 'insert' then
			utils.set_hl('ModeMsg', { link = 'ModesInsertModeMsg' })
		elseif scene == 'replace' then
			utils.set_hl('ModeMsg', { link = 'ModesReplaceModeMsg' })
		elseif scene == 'select' then
			utils.set_hl('ModeMsg', { link = 'ModesSelectModeMsg' })
		elseif scene == 'visual' then
			utils.set_hl('ModeMsg', { link = 'ModesVisualModeMsg' })
		else
			utils.set_hl('ModeMsg', { link = 'ModesDefaultModeMsg' })
		end
	end

	if config.set_cursor then
		if scene == 'default' then
			utils.set_hl('Cursor', { link = 'ModesDefaultCursor' })
		elseif scene == 'copy' then
			utils.set_hl('Cursor', { link = 'ModesCopyCursor' })
		elseif scene == 'delete' then
			utils.set_hl('Cursor', { link = 'ModesDeleteCursor' })
		elseif scene == 'change' then
			utils.set_hl('Cursor', { link = 'ModesChangeCursor' })
		elseif scene == 'format' then
			utils.set_hl('Cursor', { link = 'ModesFormatCursor' })
		elseif scene == 'insert' then
			utils.set_hl('Cursor', { link = 'ModesInsertCursor' })
		elseif scene == 'replace' then
			utils.set_hl('Cursor', { link = 'ModesReplaceCursor' })
		elseif scene == 'select' then
			utils.set_hl('Cursor', { link = 'ModesSelectCursor' })
		elseif scene == 'visual' then
			utils.set_hl('Cursor', { link = 'ModesVisualCursor' })
		elseif scene == 'normal' then
			utils.set_hl('Cursor', { link = 'ModesNormalCursor' })
		end
	end
end

H.get_scene = function()
	local mode = vim.api.nvim_get_mode().mode
	if mode:match('^i') then
		return 'insert'
	end
	if mode:match('^R') then
		return 'replace'
	end
	if mode:match('^[vV\x16]') then
		return 'visual'
	end
	if mode:match('^[sS\x13]') then
		return 'select'
	end
	if mode:match('^n') then
		return 'normal'
	end
	return 'default'
end

H.define = function()
	colors = {
		bg = config.colors.bg or utils.get_bg('Normal', 'Normal'),
		copy = config.colors.copy or utils.get_bg('ModesCopy', '#f5c359'),
		delete = config.colors.delete or utils.get_bg('ModesDelete', '#c75c6a'),
		format = config.colors.format or utils.get_bg('ModesFormat', '#c79585'),
		insert = config.colors.insert or utils.get_bg('ModesInsert', '#78ccc5'),
		replace = config.colors.replace or utils.get_bg('ModesReplace', '#245361'),
		visual = config.colors.visual or utils.get_bg('ModesVisual', '#9745be'),
	}
	colors.change = config.colors.change or colors.delete
	colors.select = config.colors.select or colors.visual
	colors.normal = config.colors.normal

	blended_colors = {
		copy = utils.blend(colors.copy, colors.bg, config.line_opacity.copy),
		delete = utils.blend(
			colors.delete,
			colors.bg,
			config.line_opacity.delete
		),
		change = utils.blend(
			colors.change,
			colors.bg,
			config.line_opacity.change
		),
		format = utils.blend(
			colors.format,
			colors.bg,
			config.line_opacity.format
		),
		insert = utils.blend(
			colors.insert,
			colors.bg,
			config.line_opacity.insert
		),
		replace = utils.blend(
			colors.replace,
			colors.bg,
			config.line_opacity.replace
		),
		select = utils.blend(
			colors.select,
			colors.bg,
			config.line_opacity.select
		),
		visual = utils.blend(
			colors.visual,
			colors.bg,
			config.line_opacity.visual
		),
		normal = colors.normal and utils.blend(
			colors.normal,
			colors.bg,
			config.line_opacity.normal
		) or nil,
	}



	---Create highlight groups
	if colors.copy ~= '' then
		vim.cmd('hi ModesCopy guibg=' .. colors.copy)
	end
	if colors.delete ~= '' then
		vim.cmd('hi ModesDelete guibg=' .. colors.delete)
	end
	if colors.change ~= '' then
		vim.cmd('hi ModesChange guibg=' .. colors.change)
	end
	if colors.format ~= '' then
		vim.cmd('hi ModesFormat guibg=' .. colors.format)
	end
	if colors.insert ~= '' then
		vim.cmd('hi ModesInsert guibg=' .. colors.insert)
	end
	if colors.replace ~= '' then
		vim.cmd('hi ModesReplace guibg=' .. colors.replace)
	end
	if colors.visual ~= '' then
		vim.cmd('hi ModesVisual guibg=' .. colors.visual)
	end
	if colors.normal and colors.normal ~= '' then
		vim.cmd('hi ModesNormal guibg=' .. colors.normal)
	end

	local default_cursor = utils.get_bg('Cursor', '#524f67')
	utils.set_hl('ModesDefaultCursor', { bg = default_cursor })

	local default_cursorline = utils.get_bg('CursorLine', '#26233a')
	if config.set_number then
		vim.cmd('hi CursorLineNr guibg=' .. default_cursorline)
	end
	if config.set_signcolumn then
		vim.cmd('hi CursorLineSign guibg=' .. default_cursorline)
	end

	local line_nr_gui = utils.get_gui('CursorLineNr', 'none')
	for _, mode in ipairs({ 'Copy', 'Delete', 'Change', 'Format', 'Insert', 'Replace', 'Select', 'Visual', 'Normal' }) do
		local mode_fg = colors[mode:lower()]
		if mode_fg ~= '' then
			local mode_bg = (mode:lower() == 'visual' or mode:lower() == 'select') and 'none' or
			    blended_colors[mode:lower()]
			utils.set_hl(('Modes%sCursorLine'):format(mode), { bg = mode_bg })
			utils.set_hl(('Modes%sCursorLineNr'):format(mode),
				{ fg = mode_fg, bg = mode_bg, gui = line_nr_gui })
			utils.set_hl(('Modes%sCursorLineSign'):format(mode), { bg = mode_bg })
			utils.set_hl(('Modes%sCursorLineFold'):format(mode), { bg = mode_bg })
			utils.set_hl(('Modes%sCursor'):format(mode), { bg = mode_fg })
		end
	end

	local default_mode_msg = utils.get_fg('ModeMsg', '#908caa')
	utils.set_hl('ModesDefaultModeMsg', { fg = default_mode_msg })

	if colors.insert ~= '' then
		utils.set_hl('ModesInsertModeMsg', { fg = colors.insert })
	end
	if colors.replace ~= '' then
		utils.set_hl('ModesReplaceModeMsg', { fg = colors.replace })
		utils.set_hl('ModesReplaceVisual', { bg = blended_colors.replace })
		utils.set_hl('ModesVisualReplaceCursorLineNr', { fg = colors.replace, gui = line_nr_gui })
	end
	if colors.select ~= '' then
		utils.set_hl('ModesSelectModeMsg', { fg = colors.select })
		utils.set_hl('ModesSelectVisual', { bg = blended_colors.select })
	end
	if colors.visual ~= '' then
		utils.set_hl('ModesVisualModeMsg', { fg = colors.visual })
		utils.set_hl('ModesVisualVisual', { bg = blended_colors.visual })
	end
end

H.enable_managed_ui = function()
	if in_ignored_buffer() then
		if config.set_cursorline then
			vim.o.cursorline = false
		end

		H.reset()
	else
		if config.set_cursorline then
			vim.o.cursorline = true
		end

		if config.set_cursor then
			vim.opt.guicursor:append('a:Cursor')
		end

		H.restore()
	end
end

H.disable_managed_ui = function()
	if config.set_cursorline then
		vim.o.cursorline = false
	end

	if config.set_cursor then
		vim.opt.guicursor:remove('a:Cursor')

		-- ensure cursor reset (see https://github.com/neovim/neovim/issues/21018)
		local cursor = vim.o.guicursor
		vim.o.guicursor = 'a:'
		vim.cmd.redrawstatus()
		vim.o.guicursor = cursor
	end
end

--- Module setup
---
---@param config table|nil Module config table. See |Modes.config|.
---
---@usage `require('modes').setup({})` (replace `{}` with your `config` table)
Modes.setup = function(opts)
	opts = vim.tbl_extend('keep', opts or {}, default_config)
	if opts.focus_only then
		vim.notify(
			'modes.nvim – `focus_only` has been removed and is now the default behaviour',
			vim.log.levels.INFO,
			{}
		)
	end
	if opts.ignore_filetypes then
		if not opts.ignore then
			opts.ignore = opts.ignore_filetypes
		end
		opts.ignore_filetypes = nil
		vim.notify(
			'modes.nvim - `ignore_filetypes` has been replaced by `ignore`',
			vim.log.levels.INFO,
			{}
		)
	end

	config = vim.tbl_deep_extend('force', default_config, opts)

	if type(config.line_opacity) == 'number' then
		config.line_opacity = {
			copy = config.line_opacity,
			delete = config.line_opacity,
			change = config.line_opacity,
			format = config.line_opacity,
			insert = config.line_opacity,
			replace = config.line_opacity,
			select = config.line_opacity,
			visual = config.line_opacity,
			normal = config.line_opacity,
		}
	end

	H.define()
	H.enable_managed_ui() -- ensure enabled initially

	---Reset normal highlight
	vim.api.nvim_create_autocmd('ModeChanged', {
		pattern = '*:n,*:ni*',
		callback = function()
			H.reset()
			if colors.normal then
				H.highlight('normal')
			end
		end,
	})

	---Set operator highlights
	vim.api.nvim_create_autocmd('ModeChanged', {
		pattern = '*:no*',
		callback = function()
			local operator = vim.v.operator
			if operator == 'y' then
				H.highlight('copy')
			elseif operator == 'd' then
				H.highlight('delete')
			elseif operator == 'c' then
				H.highlight('change')
			elseif operator:match('[=!><g]') then
				H.highlight('format')
			end
		end,
	})

	---Set character-replace highlight
	vim.on_key(function(key)
		if key ~= 'r' then
			return
		end

		local mode = vim.api.nvim_get_mode().mode
		if mode == 'n' or mode:match('^ni') or mode:match('^[vV\x16]') then
			-- hide transient mode message not normally seen
			if vim.o.showmode then
				vim.o.showmode = false
				vim.schedule(function()
					vim.o.showmode = true
				end)
			end

			H.highlight('replace')
			vim.cmd.redrawstatus() -- ensure showcmd area is updated
			vim.schedule(H.restore) -- restore after motion
		end
	end)

	---Set highlights when colorscheme changes
	vim.api.nvim_create_autocmd('ColorScheme', {
		pattern = '*',
		callback = H.define,
	})

	---Set insert highlight
	vim.api.nvim_create_autocmd('InsertEnter', {
		pattern = '*',
		callback = function()
			H.highlight('insert')
		end,
	})

	---Set replace highlight
	vim.api.nvim_create_autocmd('ModeChanged', {
		pattern = '*:R*',
		callback = function()
			H.highlight('replace')
		end,
	})

	---Set select highlight
	vim.api.nvim_create_autocmd('ModeChanged', {
		pattern = '*:[sS\x13]',
		callback = function()
			H.highlight('select')
		end,
	})

	---Set visual highlight
	vim.api.nvim_create_autocmd('ModeChanged', {
		pattern = '*:[vV\x16]',
		callback = function()
			H.highlight('visual')
		end,
	})

	---Enable managed UI for current window
	vim.api.nvim_create_autocmd('WinEnter', {
		pattern = '*',
		callback = function()
			vim.schedule(H.enable_managed_ui)
		end,
	})

	---Disable managed UI
	vim.api.nvim_create_autocmd('WinLeave', {
		pattern = '*',
		callback = H.disable_managed_ui,
	})
end

return Modes
