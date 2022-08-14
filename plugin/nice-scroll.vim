if exists('g:loaded_nice_scroll_nvim')
    finish
endif

let g:loaded_nice_scroll_nvim = 1

nnoremap <Plug>(nice-scroll-adjust)     <Cmd>lua require('nice-scroll').adjust()<CR>
nnoremap <Plug>(nice-scroll-adjust-r)   <Cmd>lua require('nice-scroll').adjust('r')<CR>
nnoremap <Plug>(nice-scroll-adjust-eof) <Cmd>lua require('nice-scroll').adjust_eof()<CR>

command! -nargs=1 NiceScrollAdjust    lua require('nice-scroll').adjust(<args>)
command! -nargs=1 NiceScrollAdjust lua require('nice-scroll').adjust_eof(<args>)
