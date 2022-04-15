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
	ignore_filetypes = { 'NvimTree', 'TelescopePrompt' },
}
local colors = {}
local blended_colors = {}
local default_colors = {}
local operator_started = false

M.reset = function()
	M.highlight('default')
	operator_started = false
end

---Update highlights
---@param scene 'copy'|'default'|'delete'|'insert'|'visual'
M.highlight = function(scene)
	if scene == 'default' then
		utils.set_hl('CursorLine', default_colors.cursor_line)
		if config.set_number then
			utils.set_hl('CursorLineNr', {
				bg = default_colors.cursor_line.bg,
				fg = default_colors.normal.fg,
			})
		end
		utils.set_hl('ModeMsg', default_colors.mode_msg)
	end

	if scene == 'insert' then
		utils.set_hl('CursorLine', { bg = blended_colors.insert })
		if config.set_number then
			utils.set_hl('CursorLineNr', { bg = blended_colors.insert })
		end
		utils.set_hl('ModeMsg', { fg = colors.insert.fg })
	end

	if scene == 'visual' then
		utils.set_hl('CursorLine', { bg = blended_colors.visual })
		if config.set_number then
			utils.set_hl('CursorLineNr', { bg = blended_colors.visual })
		end
		utils.set_hl('ModeMsg', { fg = colors.visual.fg })
	end

	if scene == 'copy' then
		utils.set_hl('CursorLine', { bg = blended_colors.copy })
		if config.set_number then
			utils.set_hl('CursorLineNr', { bg = blended_colors.copy })
		end
		utils.set_hl('ModeMsg', { fg = colors.copy.fg })
		utils.set_hl('ModesOperator', { link = 'ModesCopy' })
	end

	if scene == 'delete' then
		utils.set_hl('CursorLine', { bg = blended_colors.delete })
		if config.set_number then
			utils.set_hl('CursorLineNr', { bg = blended_colors.delete })
		end
		utils.set_hl('ModeMsg', { fg = colors.delete.fg })
		utils.set_hl('ModesOperator', { link = 'ModesDelete' })
	end
end

M.define = function()
	default_colors = {
		cursor_line = utils.get_hl('CursorLine'),
		normal = utils.get_hl('Normal'),
		mode_msg = utils.get_hl('ModeMsg'),
	}

	colors = {
		copy = config.colors.copy or utils.get_hl(
			'ModesCopy',
			{ bg = '#f5c359' }
		),
		delete = config.colors.delete or utils.get_hl(
			'ModesDelete',
			{ bg = '#c75c6a' }
		),

		insert = config.colors.insert or utils.get_hl(
			'ModesInsert',
			{ bg = '#78ccc5' }
		),

		visual = config.colors.visual or utils.get_hl(
			'ModesVisual',
			{ bg = '#9745be' }
		),
	}

	blended_colors = {
		copy = utils.blend(
			colors.copy.bg,
			default_colors.normal.bg,
			config.line_opacity.copy
		),

		delete = utils.blend(
			colors.delete.bg,
			default_colors.normal.bg,
			config.line_opacity.delete
		),

		insert = utils.blend(
			colors.insert.bg,
			default_colors.normal.bg,
			config.line_opacity.insert
		),

		visual = utils.blend(
			colors.visual.bg,
			default_colors.normal.bg,
			config.line_opacity.visual
		),
	}

	utils.set_hl(
		'ModesCopy',
		{ fg = default_colors.normal.fg, bg = colors.copy.bg }
	)
	utils.set_hl(
		'ModesDelete',
		{ fg = default_colors.normal.fg, bg = colors.delete.bg }
	)
	utils.set_hl(
		'ModesInsert',
		{ fg = default_colors.normal.fg, bg = colors.insert.bg }
	)
	utils.set_hl(
		'ModesVisual',
		{ fg = default_colors.normal.fg, bg = colors.visual.bg }
	)
	utils.set_hl('Visual', { bg = blended_colors.visual })
end

M.enable_managed_ui = function()
	if config.set_cursor then
		vim.opt.guicursor:append('v-sm:block-ModesVisual')
		vim.opt.guicursor:append('i-ci-ve:ver25-ModesInsert')
		vim.opt.guicursor:append('r-cr-o:hor20-ModesOperator')
	end

	if config.set_cursorline then
		vim.opt.cursorline = true
	end
end

M.disable_managed_ui = function()
	if config.set_cursor then
		vim.opt.guicursor:remove('v-sm:block-ModesVisual')
		vim.opt.guicursor:remove('i-ci-ve:ver25-ModesInsert')
		vim.opt.guicursor:remove('r-cr-o:hor20-ModesOperator')
	end

	if config.set_cursorline then
		vim.opt.cursorline = false
	end
end

M.setup = function(opts)
	opts = opts or default_config

	---Check deprecated options
	if opts.focus_only then
		print(
			'modes.nvim – `focus_only` has been removed and is now the default behaviour'
		)
	end

	config = vim.tbl_deep_extend('force', default_config, opts)

	if type(opts.line_opacity) == 'number' then
		local opacity = opts.line_opacity

		config.line_opacity = {
			copy = opacity,
			delete = opacity,
			insert = opacity,
			visual = opacity,
		}
	end

	M.define()
	vim.defer_fn(function()
		M.define()
	end, 15)

	vim.on_key(function(key)
		local ok, current_mode = pcall(vim.fn.mode)
		if not ok then
			M.reset()
		end

		if current_mode == 'i' then
			if key == utils.replace_termcodes('<esc>') then
				M.reset()
			end
		end

		if current_mode == 'n' then
			if key == utils.replace_termcodes('<esc>') then
				M.reset()
			end

			if key == 'y' and not operator_started then
				M.highlight('copy')
				operator_started = true
			end

			if key == 'd' and not operator_started then
				M.highlight('delete')
				operator_started = true
			end

			if (key == 'v' or key == 'V') and not operator_started then
				M.highlight('visual')
			end
		end

		if current_mode == 'v' then
			if key == utils.replace_termcodes('<esc>') then
				M.reset()
			end
		end

		if current_mode == 'V' then
			if key == utils.replace_termcodes('<esc>') then
				M.reset()
			end
		end
	end)

	vim.api.nvim_create_autocmd('ColorScheme', {
		pattern = '*',
		callback = M.define,
	})

	vim.api.nvim_create_autocmd('InsertEnter', {
		pattern = '*',
		callback = function()
			M.highlight('insert')
		end,
	})

	vim.api.nvim_create_autocmd(
		{ 'CmdlineLeave', 'InsertLeave', 'TextYankPost', 'WinLeave' },
		{
			pattern = '*',
			callback = M.reset,
		}
	)

	M.enable_managed_ui()

	vim.api.nvim_create_autocmd('WinEnter', {
		pattern = '*',
		callback = M.enable_managed_ui,
	})

	vim.api.nvim_create_autocmd('WinLeave', {
		pattern = '*',
		callback = M.disable_managed_ui,
	})

	vim.api.nvim_create_autocmd('FileType', {
		pattern = config.ignore_filetypes,
		callback = M.disable_managed_ui,
	})
end

return M
