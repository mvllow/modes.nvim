" Deal with issues in neovim/neovim#11362
set display=lastline
set directory=""
set noswapfile

let $dependencies = "./dependencies"

set rtp+=.,$dependencies

runtime! plugin/plenary.vim

function Test() abort
	lua << EOF
	require("plenary.test_harness").test_directory("./tests", {
		minimal_init = vim.fn.getcwd() .. "/tests/minimal.vim"
	})
EOF
endfunction
