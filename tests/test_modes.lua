local new_set = MiniTest.new_set
local expect = MiniTest.expect

local child = MiniTest.new_child_neovim()

local T = new_set({
	hooks = {
		pre_case = function()
			child.restart({ '-u', 'scripts/minimal-init.lua' })
		end,
		post_once = function()
			child.stop()
		end,
	},
})

T['setup'] = new_set()

T['setup']['no error with defaults and colors defined'] = function()
	expect.no_error(function()
		child.lua([[require('modes').setup()]])
	end)
end

T['setup']['no error with user provided settings'] = function()
	expect.no_error(function()
		child.lua([[require('modes').setup(...)]], {
			{
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
			},
		})
	end)
end

T['setup']['no error with only some user provided settings'] = function()
	expect.no_error(function()
		child.lua(
			[[require('modes').setup(...)]],
			{ { line_opacity = 0.16, set_number = false } }
		)
	end)
end

T['highlight'] = new_set()

T['highlight']['maps each mode to its color'] = function()
	child.lua([[require('modes').setup(...)]], {
		{
			line_opacity = 1,
			colors = {
				copy = '#f5c359',
				delete = '#c75c6a',
				change = '#9c5c6a',
				insert = '#78ccc5',
				visual = '#9745be',
			},
		},
	})

	local modes = {
		{ 'y', '#f5c359', 'ModesCopyCursorLine', 'ModesCopyCursorLine' },
		{ 'd', '#c75c6a', 'ModesDeleteCursorLine', 'ModesDeleteCursorLine' },
		{ 'c', '#9c5c6a', 'ModesChangeCursorLine', 'ModesChangeCursorLine' },
		{ 'i', '#78ccc5', 'ModesInsertCursorLine', 'ModesInsertCursorLine' },
		{ 'v', '#9745be', 'ModesVisualCursorLine', 'ModesVisualVisual' },
	}

	for _, m in ipairs(modes) do
		local key, color, remap, group = m[1], m[2], m[3], m[4]
		child.type_keys(key)

		local winhl =
			child.api.nvim_get_option_value('winhighlight', { win = 0 })
		expect.equality(
			winhl:find('CursorLine:' .. remap, 1, true) ~= nil,
			true
		)

		local bg = child.api.nvim_get_hl(0, { name = group }).bg
		expect.equality(('#%06x'):format(bg), color)

		child.type_keys('<Esc>')
	end
end

T['define'] = new_set()

T['define']['creates highlight groups'] = function()
	child.lua([[require('modes').setup()]])
	for _, group in ipairs({
		'ModesCopy',
		'ModesDelete',
		'ModesInsert',
		'ModesVisual',
	}) do
		expect.equality(child.fn.hlID(group) > 0, true)
	end
end

return T
