--- minimal-init.lua
---
---@usage
--- nvim --headless --noplugin -u scripts/minimal-init.lua -c "lua require('mini.test').setup()" -c "lua MiniTest.run()"

vim.opt.rtp:prepend(vim.fn.getcwd())
for _, path in
	ipairs(vim.fn.glob(vim.fn.getcwd() .. '/dependencies/*', true, true))
do
	vim.opt.rtp:prepend(path)
end
