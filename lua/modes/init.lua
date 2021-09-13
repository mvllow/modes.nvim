local util = require('modes.util')
local cmd = vim.cmd
local opt = vim.opt
local fn = vim.fn

local modes = {}
local config = {}
local colors = {}
local dim_colors = {}
local init_colors = {}
local operator_started = false

function modes.reset()
	modes.set_highlights('init')
	operator_started = false
end

function modes.set_highlights(style)
	if style == 'init' then
		cmd('hi CursorLine guibg=' .. init_colors.cursor_line)
		cmd('hi CursorLineNr guifg=' .. init_colors.cursor_line_nr)
		cmd('hi ModeMsg guifg=' .. init_colors.mode_msg)
	end

	if style == 'copy' then
		cmd('hi CursorLine guibg=' .. dim_colors.copy)
		cmd('hi CursorLineNr guifg=' .. colors.copy)
		cmd('hi ModeMsg guifg=' .. colors.copy)
		cmd('hi ModesOperator guifg=NONE guibg=NONE')
		cmd('hi! link ModesOperator ModesCopy')
	end

	if style == 'delete' then
		cmd('hi CursorLine guibg=' .. dim_colors.delete)
		cmd('hi CursorLineNr guifg=' .. colors.delete)
		cmd('hi ModeMsg guifg=' .. colors.delete)
		cmd('hi ModesOperator guifg=NONE guibg=NONE')
		cmd('hi! link ModesOperator ModesDelete')
	end

	if style == 'insert' then
		cmd('hi CursorLine guibg=' .. dim_colors.insert)
		cmd('hi CursorLineNr guifg=' .. colors.insert)
		cmd('hi ModeMsg guifg=' .. colors.insert)
	end

	if style == 'visual' then
		cmd('hi CursorLine guibg=' .. dim_colors.visual)
		cmd('hi CursorLineNr guifg=' .. colors.visual)
		cmd('hi ModeMsg guifg=' .. colors.visual)
	end
end

function modes.set_colors()
	init_colors = {
		cursor_line = util.get_bg_from_hl('CursorLine', 'CursorLine'),
		cursor_line_nr = util.get_fg_from_hl('CursorLineNr', 'CursorLineNr'),
		mode_msg = util.get_fg_from_hl('ModeMsg', 'ModeMsg'),
		normal = util.get_bg_from_hl('Normal', 'Normal'),
	}
	colors = {
		copy = config.colors.copy or util.get_bg_from_hl('ModesCopy', '#f5c359'),
		delete = config.colors.delete or util.get_bg_from_hl(
			'ModesDelete',
			'#c75c6a'
		),
		insert = config.colors.insert or util.get_bg_from_hl(
			'ModesInsert',
			'#78ccc5'
		),
		visual = config.colors.visual or util.get_bg_from_hl(
			'ModesVisual',
			'#9745be'
		),
	}
	dim_colors = {
		copy = util.blend(colors.copy, init_colors.normal, config.line_opacity),
		delete = util.blend(
			colors.delete,
			init_colors.normal,
			config.line_opacity
		),
		insert = util.blend(
			colors.insert,
			init_colors.normal,
			config.line_opacity
		),
		visual = util.blend(
			colors.visual,
			init_colors.normal,
			config.line_opacity
		),
	}

	cmd('hi ModesCopy guibg=' .. colors.copy)
	cmd('hi ModesDelete guibg=' .. colors.delete)
	cmd('hi ModesInsert guibg=' .. colors.insert)
	cmd('hi ModesVisual guibg=' .. colors.visual)
end

---@class Colors
---@field copy string
---@field delete string
---@field insert string
---@field visual string

---@class Config
---@field colors Colors
---@field line_opacity number between 0 and 1

---@param opts Config
function modes.setup(opts)
	local default = require('modes.config').default

	-- Set opts with fallback to default.
	setmetatable(opts or {}, { __index = default })
	config = opts

	-- Hack to ensure theme colors get loaded properly
	modes.set_colors()
	vim.defer_fn(function()
		modes.set_colors()
	end, 15)

	-- Set common highlights
	cmd('hi Visual guibg=' .. dim_colors.visual)

	-- Set guicursor modes
	opt.guicursor:append('v-sm:block-ModesVisual')
	opt.guicursor:append('i-ci-ve:ver25-ModesInsert')
	opt.guicursor:append('r-cr-o:hor20-ModesOperator')

	local on_key = vim.on_key or vim.register_keystroke_callback
	on_key(function(key)
		local current_mode = fn.mode()

		-- Insert mode
		if current_mode == 'i' then
			if key == util.get_termcode('<esc>') then
				modes.reset()
			end
		end

		-- Normal mode
		if current_mode == 'n' then
			if key == util.get_termcode('<esc>') then
				modes.reset()
			end

			if key == 'y' then
				if operator_started then
					modes.reset()
				else
					modes.set_highlights('copy')
					operator_started = true
				end
			end

			if key == 'd' then
				if operator_started then
					modes.reset()
				else
					modes.set_highlights('delete')
					operator_started = true
				end
			end

			if (key == 'v' or key == 'V') and not operator_started then
				modes.set_highlights('visual')
			end
		end

		-- Visual mode
		if current_mode == 'v' then
			if key == util.get_termcode('<esc>') then
				modes.reset()
			end
		end

		-- Visual line mode
		if current_mode == 'V' then
			if key == util.get_termcode('<esc>') then
				modes.reset()
			end
		end
	end)

	local autocmds = {
		{ 'ColorScheme', '*', 'lua require("modes").set_colors()' },
		{
			'InsertEnter',
			'*',
			'lua require("modes").set_highlights("insert")',
		},
		{
			'CmdlineLeave,InsertLeave,TextYankPost,WinLeave',
			'*',
			'lua require("modes").reset()',
		},
	}

	if config.focus_only then
		autocmds['cl'] = { 'WinEnter', '*', 'set cursorline' }
		autocmds['nocl'] = { 'WinLeave', '*', 'set nocursorline' }
	end

	util.define_augroups({ _modes = autocmds })
end

return modes
