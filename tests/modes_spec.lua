local modes = require('modes')
local settings = require('tests.settings')

describe('modes.lua tests:', function()
	describe('Setup Tests:', function()
		it('Checks if setup fails with defaults and colors defined', function()
			vim.api.nvim_set_hl(0, 'Normal', { fg = '#000000', bg = '#000000' })
			vim.api.nvim_set_hl(0, 'Visual', { fg = '#000000', bg = '#000000' })
			vim.api.nvim_set_hl(0, 'CursorLine', { fg = '#000000', bg = '#000000' })
			vim.api.nvim_set_hl(0, 'CursorLineNr', { fg = '#000000', bg = '#000000' })
			vim.api.nvim_set_hl(0, 'ModeMsg', { fg = '#000000', bg = '#000000' })
			assert.has_no.errors(modes.setup)
		end)
		it('Checks if setup fails with defaults and highlight groups set to NONE', function()
			vim.api.nvim_set_hl(0, 'Normal', { fg = 'NONE', bg = 'NONE' })
			vim.api.nvim_set_hl(0, 'Visual', { fg = 'NONE', bg = 'NONE' })
			vim.api.nvim_set_hl(0, 'CursorLine', { fg = 'NONE', bg = 'NONE' })
			vim.api.nvim_set_hl(0, 'CursorLineNr', { fg = 'NONE', bg = 'NONE' })
			vim.api.nvim_set_hl(0, 'ModeMsg', { fg = 'NONE', bg = 'NONE' })
			assert.has_no.errors(modes.setup)
		end)
		it('Checks if setup fails with user provided settings', function()
			assert.has_no.errors(modes.setup, settings.settings)
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
end)
