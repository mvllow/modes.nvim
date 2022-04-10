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
local function blend(fg, bg, alpha)
	bg = get_color(bg)
	fg = get_color(fg)

	local channel = function(i)
		local ret = (alpha * fg[i] + ((1 - alpha) * bg[i]))
		return math.floor(math.min(math.max(0, ret), 255) + 0.5)
	end

	return string.format('#%02X%02X%02X', channel(1), channel(2), channel(3))
end

local function get_termcode(key)
	return vim.api.nvim_replace_termcodes(key, true, true, true)
end

local get_hl = function(name, fallback)
	local ok, hl = pcall(vim.api.nvim_get_hl_by_name, name, true)
	if not ok then
		return fallback or { bg = 'none', fg = 'none' }
	end

	return {
		bg = hl.background and ('#%06x'):format(hl.background) or 'none',
		fg = hl.foreground and ('#%06x'):format(hl.foreground) or 'none',
	}
end

local set_hl = function(name, opts)
	if opts.link ~= nil then
		vim.cmd('hi ' .. name .. ' guibg=none guibg=none')
		vim.cmd('hi! link ' .. name .. ' ' .. opts.link)
		return
	end

	opts.bg = opts.bg or 'none'
	opts.fg = opts.fg or 'none'

	vim.cmd('hi ' .. name .. ' guibg=' .. opts.bg .. ' guifg=' .. opts.fg)
end

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
		set_hl('CursorLine', init_colors.cursor_line)
		set_hl('CursorLineNr', init_colors.cursor_line_nr)
		set_hl('ModeMsg', init_colors.mode_msg)
	end

	if style == 'copy' then
		set_hl('CursorLine', { bg = dim_colors.copy })
		set_hl('CursorLineNr', { bg = dim_colors.copy })
		set_hl('ModeMsg', colors.copy)
		set_hl('ModesOperator', { link = 'ModesCopy' })
	end

	if style == 'delete' then
		set_hl('CursorLine', { bg = dim_colors.delete })
		set_hl('CursorLineNr', { bg = dim_colors.delete })
		set_hl('ModeMsg', colors.delete)
		set_hl('ModesOperator', { link = 'ModesDelete' })
	end

	if style == 'insert' then
		set_hl('CursorLine', { bg = dim_colors.insert })
		set_hl('CursorLineNr', { bg = dim_colors.insert })
		set_hl('ModeMsg', colors.insert)
	end

	if style == 'visual' then
		set_hl('CursorLine', { bg = dim_colors.visual })
		set_hl('CursorLineNr', { bg = dim_colors.visual })
		set_hl('ModeMsg', colors.visual)
	end
end

function modes.set_colors()
	-- Set common highlights
	set_hl('Visual', { bg = dim_colors.visual })

	init_colors = {
		cursor_line = get_hl('CursorLine'),
		cursor_line_nr = get_hl('CursorLineNr'),
		mode_msg = get_hl('ModeMsg'),
		normal = get_hl('Normal'),
	}
	colors = {
		copy = config.colors.copy or get_hl('ModesCopy', { bg = '#f5c359' }),
		delete = config.colors.delete or get_hl(
			'ModesDelete',
			{ bg = '#c75c6a' }
		),
		insert = config.colors.insert or get_hl(
			'ModesInsert',
			{ bg = '#78ccc5' }
		),
		visual = config.colors.visual or get_hl(
			'ModesVisual',
			{ bg = '#9745be' }
		),
	}
	dim_colors = {
		copy = blend(
			colors.copy.bg,
			init_colors.normal.bg,
			config.line_opacity.copy
		),
		delete = blend(
			colors.delete.bg,
			init_colors.normal.bg,
			config.line_opacity.delete
		),
		insert = blend(
			colors.insert.bg,
			init_colors.normal.bg,
			config.line_opacity.insert
		),
		visual = blend(
			colors.visual.bg,
			init_colors.normal.bg,
			config.line_opacity.visual
		),
	}

	set_hl('ModesCopy', colors.copy)
	set_hl('ModesDelete', colors.delete)
	set_hl('ModesInsert', colors.insert)
	set_hl('ModesVisual', colors.visual)
end

---@class Colors
---@field copy string
---@field delete string
---@field insert string
---@field visual string

---@class Opacity
---@field copy number between 0 and 1
---@field delete number between 0 and 1
---@field insert number between 0 and 1
---@field visual number between 0 and 1

---@class Config
---@field colors Colors
---@field line_opacity Opacity
---@field set_cursor boolean

---@param opts Config
function modes.setup(opts)
	local default_config = {
		-- Colors intentionally set to {} to prioritise theme values
		colors = {},
		line_opacity = {
			copy = 0.15,
			delete = 0.15,
			insert = 0.15,
			visual = 0.15,
		},
		set_cursor = true,

		--- TODO: Document API changes
		--
		-- manage_cursorline (replaces `focus_only`)
		-- (new) Allow modes.nvim to enable cursorline for focused windows, and
		--       disable for unfocused windows
		manage_cursorline = {
			enable = true,
			-- TODO: User opts will replace this, not extend. We should encourage
			--       PR's to extend this list rather than each user defining their
			--       own. Maybe this should disable all highlights, not just
			--       cursorline?
			ignore_filetypes = { 'TelescopePrompt' },
		},
	}
	opts = opts or default_config

	-- Resolve configs in the following order:
	-- 1. User config
	-- 2. Theme highlights if present (eg. ModesCopy)
	-- 3. Default config
	config = vim.tbl_deep_extend('force', default_config, opts)

	-- Allow overriding line opacity per colour
	if type(config.line_opacity) == 'number' then
		config.line_opacity = {
			copy = config.line_opacity,
			delete = config.line_opacity,
			insert = config.line_opacity,
			visual = config.line_opacity,
		}
	end

	-- Hack to ensure theme colors get loaded properly
	modes.set_colors()
	vim.defer_fn(function()
		modes.set_colors()
	end, 15)

	-- Set guicursor modes
	if config.set_cursor then
		vim.opt.guicursor:append('v-sm:block-ModesVisual')
		vim.opt.guicursor:append('i-ci-ve:ver25-ModesInsert')
		vim.opt.guicursor:append('r-cr-o:hor20-ModesOperator')
	end

	local on_key = vim.on_key or vim.register_keystroke_callback
	on_key(function(key)
		local ok, current_mode = pcall(vim.fn.mode)
		if not ok then
			modes.reset()
		end

		-- Insert mode
		if current_mode == 'i' then
			if key == get_termcode('<esc>') then
				modes.reset()
			end
		end

		-- Normal mode
		if current_mode == 'n' then
			if key == get_termcode('<esc>') then
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
			if key == get_termcode('<esc>') then
				modes.reset()
			end
		end

		-- Visual line mode
		if current_mode == 'V' then
			if key == get_termcode('<esc>') then
				modes.reset()
			end
		end
	end)

	vim.api.nvim_create_autocmd('ColorScheme', {
		pattern = '*',
		callback = require('modes').set_colors,
	})
	vim.api.nvim_create_autocmd('InsertEnter', {
		pattern = '*',
		callback = function()
			require('modes').set_highlights('insert')
		end,
	})
	vim.api.nvim_create_autocmd(
		{ 'CmdlineLeave', 'InsertLeave', 'TextYankPost', 'WinLeave' },
		{
			pattern = '*',
			callback = require('modes').reset,
		}
	)

	if config.manage_cursorline then
		vim.api.nvim_create_autocmd('WinEnter', {
			pattern = '*',
			command = 'set cursorline',
		})

		vim.api.nvim_create_autocmd('WinLeave', {
			pattern = '*',
			command = 'set nocursorline',
		})

		vim.api.nvim_create_autocmd('FileType', {
			pattern = config.manage_cursorline.ignore_filetypes,
			command = 'set nocursorline',
		})
	end
end

return modes
