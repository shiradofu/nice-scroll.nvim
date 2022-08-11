if exists('g:loaded_nice_scroll_nvim')
    finish
endif

let g:loaded_nice_scroll_nvim = 1

nnoremap <Plug>(nice-scroll-force)    <Cmd>lua require("nice-scroll").force()<CR>
nnoremap <Plug>(nice-scroll-force-r)  <Cmd>lua require("nice-scroll").force("r")<CR>
nnoremap <Plug>(nice-scroll-moderate) <Cmd>lua require("nice-scroll").moderate()<CR>
