" Deal with issues in neovim/neovim#11362
set display=lastline
set directory=""
set noswapfile

set rtp+=$VIMRUNTIME

packadd plenary.nvim
packadd modes.nvim

function Test() abort
    lua << EOF
    require("plenary.test_harness").test_directory("./tests", {
        minimal_init = vim.fn.getcwd() .. "/tests/minimal.vim"
    })
EOF
endfunction
