if exists('g:loaded_nice_scroll_nvim')
    finish
endif

let g:loaded_nice_scroll_nvim = 1

nnoremap <Plug>(nice-scroll-fit)     <Cmd>lua require("nice-scroll").fit()<CR>
nnoremap <Plug>(nice-scroll-fit-r)   <Cmd>lua require("nice-scroll").fit("r")<CR>
nnoremap <Plug>(nice-scroll-fit-eof) <Cmd>lua require("nice-scroll").fit_eof()<CR>

command! -nargs=1 NiceScrollFit    lua require('nice-scroll').fit(<args>)
command! -nargs=1 NiceScrollFitEof lua require('nice-scroll').fit_eof(<args>)
