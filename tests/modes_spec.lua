local modes = require('modes')
local modes_utils = require('modes.utils')

describe('modes.lua tests:', function()
	describe('Setup Tests:', function()
		it('Checks if setup fails with defaults and colors defined', function()
			vim.api.nvim_set_hl(0, 'Normal', { fg = '#000000', bg = '#000000' })
			vim.api.nvim_set_hl(0, 'Visual', { fg = '#000000', bg = '#000000' })
			vim.api.nvim_set_hl(
				0,
				'CursorLine',
				{ fg = '#000000', bg = '#000000' }
			)
			vim.api.nvim_set_hl(
				0,
				'CursorLineNr',
				{ fg = '#000000', bg = '#000000' }
			)
			vim.api.nvim_set_hl(
				0,
				'ModeMsg',
				{ fg = '#000000', bg = '#000000' }
			)
			assert.has_no.errors(modes.setup)
		end)
		it(
			'Checks if setup fails with defaults and highlight groups set to NONE',
			function()
				vim.api.nvim_set_hl(0, 'Normal', { fg = 'NONE', bg = 'NONE' })
				vim.api.nvim_set_hl(0, 'Visual', { fg = 'NONE', bg = 'NONE' })
				vim.api.nvim_set_hl(
					0,
					'CursorLine',
					{ fg = 'NONE', bg = 'NONE' }
				)
				vim.api.nvim_set_hl(
					0,
					'CursorLineNr',
					{ fg = 'NONE', bg = 'NONE' }
				)
				vim.api.nvim_set_hl(0, 'ModeMsg', { fg = 'NONE', bg = 'NONE' })
				assert.has_no.errors(modes.setup)
			end
		)
		it('Checks if setup fails with user provided settings', function()
			assert.has_no.errors(modes.setup, {
				colors = {
					copy = '#f5c359',
					delete = '#c75c6a',
					insert = '#78ccc5',
					visual = '#9745be',
				},
				line_opacity = 0.15,
				set_cursor = true,
				set_cursorline = true,
				set_number = true,
				ignore_filetypes = { 'NvimTree', 'TelescopePrompt' },
			})
		end)
		it(
			'Checks if setup fails with only some user provided settings',
			function()
				assert.has_no.errors(modes.setup, {
					line_opacity = 0.16,
					set_number = false,
				})
			end
		)
	end)
	describe('Highlight tests:', function()
		before_each(function()
			vim.api.nvim_set_hl(0, 'Normal', { fg = '#000000', bg = '#000000' })
			vim.api.nvim_set_hl(0, 'Visual', { fg = '#000000', bg = '#000000' })
			vim.api.nvim_set_hl(
				0,
				'CursorLine',
				{ fg = '#000000', bg = '#000000' }
			)
			vim.api.nvim_set_hl(
				0,
				'CursorLineNr',
				{ fg = '#000000', bg = '#000000' }
			)
			vim.api.nvim_set_hl(
				0,
				'ModeMsg',
				{ fg = '#000000', bg = '#000000' }
			)

			local bg_colors = {
				copy = '#000000',
				delete = '#000000',
				insert = '#000000',
			}

			modes.setup({
				colors = {
					bg_colors,
					visual = '#000000',
				},
			})
		end)
		it(
			'Ensures highlights are correct for insert, copy, & delete',
			function()
				for _, scene in pairs({ 'insert', 'copy', 'delete' }) do
					modes.highlight(scene)
					assert.truthy(modes_utils.get_bg(scene, scene) ~= '#000000')
				end

				modes.highlight('visual')
				print(modes_utils.get_fg('visual', 'visual'))
				print(vim.inspect(vim.api.nvim_get_hl_by_name("ModesVisual", true)))
				print(vim.inspect(modes_utils.get_fg('visual', 'visual')))
				assert.truthy(
					modes_utils.get_fg('visual', 'visual') ~= '#000000'
				)
				modes.highlight("normal")
				assert.truthy(
					modes_utils.get_bg("normal", "normal") ~= '#000000'
				)
			end
		)
	end)

	describe('Manged UI Tests:', function()
		before_each(function()
			vim.api.nvim_set_hl(0, 'Normal', { fg = '#000000', bg = '#000000' })
			vim.api.nvim_set_hl(0, 'Visual', { fg = '#000000', bg = '#000000' })
			vim.api.nvim_set_hl(
				0,
				'CursorLine',
				{ fg = '#000000', bg = '#000000' }
			)
			vim.api.nvim_set_hl(
				0,
				'CursorLineNr',
				{ fg = '#000000', bg = '#000000' }
			)
			vim.api.nvim_set_hl(
				0,
				'ModeMsg',
				{ fg = '#000000', bg = '#000000' }
			)

			local bg_colors = {
				copy = '#000000',
				delete = '#000000',
				insert = '#000000',
			}

			modes.setup({
				colors = {
					bg_colors,
					visual = '#000000',
				},
				set_cursorline = true,
			})
		end)
		it('Ensures enable_managed_ui appends values correctly', function()
			local check_values = {
				'ModesVisual',
				'ModesInsert',
				'ModesOperator',
			}
			for _, value in ipairs(check_values) do
				assert.is.truthy(string.find(vim.opt.guicursor._value, value))
			end

			assert.is.True(vim.opt.cursorline._value)
		end)

		it('Ensures disable_managed_ui removes values correctly', function()
			modes.disable_managed_ui()
			local check_values = {
				'ModesVisual',
				'ModesInsert',
				'ModesOperator',
			}
			for _, value in ipairs(check_values) do
				assert.is.falsy(string.find(vim.opt.guicursor._value, value))
			end

			assert.is.False(vim.opt.cursorline._value)
		end)
	end)

	it('Ensures highlight groups are created by define', function()
		local groups = {
			'ModesCopy',
			'ModesDelete',
			'ModesInsert',
			'ModesVisual',
		}

		for _, group in ipairs(groups) do
			-- If hlID receives 0 then the group doesn't exist
			assert.is.True(vim.fn.hlID(group) > 0)
		end
	end)
end)
