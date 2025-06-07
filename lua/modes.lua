local utils = require('modes.utils')

local M = {}
local config = {}
local default_config = {
	colors = {},
	line_opacity = {
		copy = 0.15,
		delete = 0.15,
		insert = 0.15,
		visual = 0.15,
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
	insert = {
		CursorLine = 'ModesInsertCursorLine',
		CursorLineNr = 'ModesInsertCursorLineNr',
		CursorLineSign = 'ModesInsertCursorLineSign',
		CursorLineFold = 'ModesInsertCursorLineFold',
	},
	delete = {
		CursorLine = 'ModesDeleteCursorLine',
		CursorLineNr = 'ModesDeleteCursorLineNr',
		CursorLineSign = 'ModesDeleteCursorLineSign',
		CursorLineFold = 'ModesDeleteCursorLineFold',
	},
	visual = {
		CursorLine = 'ModesVisualCursorLine',
		CursorLineNr = 'ModesVisualCursorLineNr',
		CursorLineSign = 'ModesVisualCursorLineSign',
		CursorLineFold = 'ModesVisualCursorLineFold',
		Visual = 'ModesVisualVisual',
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

M.reset = function()
	M.highlight('default')
	vim.cmd.redraw()
end

---Update highlights
---@param scene 'default'|'insert'|'visual'|'copy'|'delete'|
M.highlight = function(scene)
	if in_ignored_buffer() then
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

	if not config.set_number then
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
		if scene == 'visual' then
			utils.set_hl('ModeMsg', { link = 'ModesVisualModeMsg' })
		elseif scene == 'insert' then
			utils.set_hl('ModeMsg', { link = 'ModesInsertModeMsg' })
		else
			utils.set_hl('ModeMsg', { link = 'ModesDefaultModeMsg' })
		end
	end

	if config.set_cursor then
		if scene == 'delete' then
			utils.set_hl('ModesOperator', { link = 'ModesDelete' })
		elseif scene == 'copy' then
			utils.set_hl('ModesOperator', { link = 'ModesCopy' })
		elseif scene == 'visual' then
			utils.set_hl('ModesOperator', { link = 'ModesVisual' })
		elseif scene == 'insert' then
			utils.set_hl('ModesOperator', { link = 'ModesInsert' })
		else
			utils.set_hl('ModesOperator', { link = 'ModesDefault' })
		end
	end
end

M.define = function()
	colors = {
		bg = config.colors.bg or utils.get_bg('Normal', 'Normal'),
		copy = config.colors.copy or utils.get_bg('ModesCopy', '#f5c359'),
		delete = config.colors.delete or utils.get_bg('ModesDelete', '#c75c6a'),
		insert = config.colors.insert or utils.get_bg('ModesInsert', '#78ccc5'),
		visual = config.colors.visual or utils.get_bg('ModesVisual', '#9745be'),
	}
	blended_colors = {
		copy = utils.blend(colors.copy, colors.bg, config.line_opacity.copy),
		delete = utils.blend(
			colors.delete,
			colors.bg,
			config.line_opacity.delete
		),
		insert = utils.blend(
			colors.insert,
			colors.bg,
			config.line_opacity.insert
		),
		visual = utils.blend(
			colors.visual,
			colors.bg,
			config.line_opacity.visual
		),
	}

	---Create highlight groups
	if colors.copy ~= '' then
		vim.cmd('hi ModesCopy guibg=' .. colors.copy)
	end
	if colors.delete ~= '' then
		vim.cmd('hi ModesDelete guibg=' .. colors.delete)
	end
	if colors.insert ~= '' then
		vim.cmd('hi ModesInsert guibg=' .. colors.insert)
	end
	if colors.visual ~= '' then
		vim.cmd('hi ModesVisual guibg=' .. colors.visual)
	end

	local default_operator = utils.get_bg('Cursor', '#524f67')
	utils.set_hl('ModesDefault', { bg = default_operator })
	utils.set_hl('ModesOperator', { link = 'ModesDefault' })

	local default_cursorline = utils.get_bg('CursorLine', '#26233a')
	if config.set_number then
		vim.cmd('hi CursorLineNr guibg=' .. default_cursorline)
	end
	if config.set_signcolumn then
		vim.cmd('hi CursorLineSign guibg=' .. default_cursorline)
	end

	for _, mode in ipairs({ 'Copy', 'Delete', 'Insert', 'Visual' }) do
		local mode_fg = colors[mode:lower()]
		if mode_fg ~= '' then
			local mode_bg = (mode:lower() == 'visual') and 'NONE' or blended_colors[mode:lower()]
			utils.set_hl(('Modes%sCursorLine'):format(mode), { bg = mode_bg })
			utils.set_hl(('Modes%sCursorLineNr'):format(mode), { fg = mode_fg, bg = mode_bg })
			utils.set_hl(('Modes%sCursorLineSign'):format(mode), { bg = mode_bg })
			utils.set_hl(('Modes%sCursorLineFold'):format(mode), { bg = mode_bg })
		end
	end

	local default_mode_msg = utils.get_fg('ModeMsg', '#908caa')
	utils.set_hl('ModesDefaultModeMsg', { fg = default_mode_msg })

	if colors.insert ~= '' then
		utils.set_hl('ModesInsertModeMsg', { fg = colors.insert })
	end
	if colors.visual ~= '' then
		utils.set_hl('ModesVisualModeMsg', { fg = colors.visual })
		utils.set_hl('ModesVisualVisual', { bg = blended_colors.visual })
	end
end

M.enable_managed_ui = vim.schedule_wrap(function()
	if in_ignored_buffer() then
		if config.set_cursorline then
			vim.o.cursorline = false
		end
	else
		if config.set_cursorline then
			vim.o.cursorline = true
		end

		if config.set_cursor then
			vim.opt.guicursor:append('v-sm:ModesVisual')
			vim.opt.guicursor:append('i-ve:ModesInsert')
			vim.opt.guicursor:append('r-o:ModesOperator')
		end

		-- restore insert highlight
		local mode = vim.api.nvim_get_mode().mode
		if mode:match('^i') or mode:match('^R') then
			M.highlight('insert')
		end
	end
end)

M.disable_managed_ui = function()
	if config.set_cursorline then
		vim.o.cursorline = false
	end

	if config.set_cursor then
		vim.opt.guicursor:remove('v-sm:ModesVisual')
		vim.opt.guicursor:remove('i-ve:ModesInsert')
		vim.opt.guicursor:remove('r-o:ModesOperator')

		-- ensure cursor reset (see https://github.com/neovim/neovim/issues/21018)
		local cursor = vim.o.guicursor
		vim.o.guicursor = 'a:'
		vim.cmd.redrawstatus()
		vim.o.guicursor = cursor
	end

	M.reset()
end

M.setup = function(opts)
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
			insert = config.line_opacity,
			visual = config.line_opacity,
		}
	end

	M.define()

	---Reset normal highlight
	vim.api.nvim_create_autocmd('ModeChanged', {
		pattern = '*:n,*:ni*',
		callback = M.reset,
	})

	---Set operator highlights
	vim.api.nvim_create_autocmd('ModeChanged', {
		pattern = '*:no*',
		callback = function()
			if vim.v.operator == 'y' then
				M.highlight('copy')
			elseif vim.v.operator == 'd' then
				M.highlight('delete')
			end
		end,
	})

	---Set highlights when colorscheme changes
	vim.api.nvim_create_autocmd('ColorScheme', {
		pattern = '*',
		callback = M.define,
	})

	---Set insert highlight
	vim.api.nvim_create_autocmd('InsertEnter', {
		pattern = '*',
		callback = function()
			M.highlight('insert')
		end,
	})

	---Set visual highlight
	vim.api.nvim_create_autocmd('ModeChanged', {
		pattern = '*:[vV\x16]*,*:[sS\x13]',
		callback = function()
			M.highlight('visual')
		end,
	})

	---Enable managed UI for current window
	vim.api.nvim_create_autocmd({ 'WinEnter', 'FocusGained' }, {
		pattern = '*',
		callback = M.enable_managed_ui,
	})

	---Disable managed UI
	vim.api.nvim_create_autocmd({ 'WinLeave', 'FocusLost' }, {
		pattern = '*',
		callback = M.disable_managed_ui,
	})
end

return M
