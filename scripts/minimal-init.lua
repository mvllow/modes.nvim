--- minimal-init.lua
---
---@usage
--- nvim -u minimal-init.lua

vim.opt.rtp:prepend(".")

vim.o.packpath = "/tmp/nvim/site"

local url = "https://github.com/echasnovski/mini.doc"
local install_path = "/tmp/nvim/site/pack/test/start/mini.doc"
if vim.fn.isdirectory(install_path) then
	vim.fn.system({ "git", "clone", "--depth=1", url, install_path })
end
