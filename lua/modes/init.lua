local utils = require("modes.utils")
local cmd = vim.cmd
local opt = vim.opt
local fn = vim.fn

local M = {}
local colors = {}
local dim_colors = {}
local user_colors = {}
local initial_colors = {}
local line_opacity = 0.15
local operator_started = false

function M.set_highlights(style)
	if style == "reset" then
		cmd("hi CursorLine guibg=" .. initial_colors.CursorLine)
		cmd("hi CursorLineNr guifg=" .. initial_colors.CursorLineNr)
		cmd("hi ModeMsg guifg=" .. initial_colors.ModeMsg)
		operator_started = false
	end

	if style == "copy" then
		cmd("hi CursorLine guibg=" .. dim_colors.copy)
		cmd("hi CursorLineNr guifg=" .. colors.copy)
		cmd("hi ModeMsg guifg=" .. colors.copy)
		opt.guicursor:remove("r-cr-o:hor20-ModesDelete")
		opt.guicursor:append("r-cr-o:hor20-ModesCopy")
	end

	if style == "delete" then
		cmd("hi CursorLine guibg=" .. dim_colors.delete)
		cmd("hi CursorLineNr guifg=" .. colors.delete)
		cmd("hi ModeMsg guifg=" .. colors.delete)
		opt.guicursor:remove("r-cr-o:hor20-ModesCopy")
		opt.guicursor:append("r-cr-o:hor20-ModesDelete")
	end

	if style == "insert" then
		cmd("hi CursorLine guibg=" .. dim_colors.insert)
		cmd("hi CursorLineNr guifg=" .. colors.insert)
		cmd("hi ModeMsg guifg=" .. colors.insert)
	end

	if style == "visual" then
		cmd("hi CursorLine guibg=" .. dim_colors.visual)
		cmd("hi CursorLineNr guifg=" .. colors.visual)
		cmd("hi ModeMsg guifg=" .. colors.visual)
	end
end

function M.set_colors()
	colors = {
		copy = (user_colors and user_colors.copy) or utils.get_bg_from_hl("ModesCopy", "#f5c359"),
		delete = (user_colors and user_colors.delete) or utils.get_bg_from_hl("ModesDelete", "#c75c6a"),
		insert = (user_colors and user_colors.insert) or utils.get_bg_from_hl("ModesInsert", "#78ccc5"),
		visual = (user_colors and user_colors.visual) or utils.get_bg_from_hl("ModesVisual", "#9745be"),
	}
	dim_colors = {
		copy = utils.blend(colors.copy, utils.get_bg_from_hl("Normal", "Normal"), line_opacity),
		delete = utils.blend(colors.delete, utils.get_bg_from_hl("Normal", "Normal"), line_opacity),
		insert = utils.blend(colors.insert, utils.get_bg_from_hl("Normal", "Normal"), line_opacity),
		visual = utils.blend(colors.visual, utils.get_bg_from_hl("Normal", "Normal"), line_opacity),
	}

	cmd("hi ModesCopy guibg=" .. colors.copy)
	cmd("hi ModesDelete guibg=" .. colors.delete)
	cmd("hi ModesInsert guibg=" .. colors.insert)
	cmd("hi ModesVisual guibg=" .. colors.visual)
end

function M.setup(opts)
	user_colors = (opts and opts.colors)
	line_opacity = (opts and opts.line_opacity) or 0.15

	-- Hack to ensure theme colors get loaded properly
	M.set_colors()
	vim.defer_fn(function()
		M.set_colors()
	end, 15)

	initial_colors = {
		CursorLine = utils.get_bg_from_hl("CursorLine", "CursorLine"),
		CursorLineNr = utils.get_fg_from_hl("CursorLineNr", "CursorLineNr"),
		ModeMsg = utils.get_fg_from_hl("ModeMsg", "ModeMsg"),
	}

	-- Set common highlights
	cmd("hi Visual guibg=" .. dim_colors.visual)

	-- Set guicursor modes
	opt.guicursor:append("v-sm:block-ModesVisual")
	opt.guicursor:append("i-ci-ve:ver25-ModesInsert")
	opt.guicursor:append("r-cr-o:hor20-ModesDelete")

	vim.register_keystroke_callback(function(key)
		local current_mode = fn.mode()

		-- Insert mode
		if current_mode == "i" then
			if key == utils.get_termcode("<esc>") then
				M.set_highlights("reset")
			end
		end

		-- Normal mode
		if current_mode == "n" then
			if key == utils.get_termcode("<esc>") then
				M.set_highlights("reset")
			end

			if key == "y" then
				if operator_started then
					M.set_highlights("reset")
				else
					M.set_highlights("copy")
					operator_started = true
				end
			end

			if key == "d" then
				if operator_started then
					M.set_highlights("reset")
				else
					M.set_highlights("delete")
					operator_started = true
				end
			end

			if (key == "v" or key == "V") and not operator_started then
				M.set_highlights("visual")
			end
		end

		-- Visual mode
		if current_mode == "v" then
			if key == utils.get_termcode("<esc>") then
				M.set_highlights("reset")
			end
		end

		-- Visual line mode
		if current_mode == "V" then
			if key == utils.get_termcode("<esc>") then
				M.set_highlights("reset")
			end
		end
	end)

	utils.define_augroups({
		_modes = {
			{
				"InsertEnter",
				"*",
				'lua require("modes").set_highlights("insert")',
			},
			{
				"CmdlineLeave,InsertLeave,TextYankPost",
				"*",
				'lua require("modes").set_highlights("reset")',
			},
		},
	})
end

return M
