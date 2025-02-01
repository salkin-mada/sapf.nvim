if !exists('g:do_filetype_lua')
  autocmd BufEnter,BufWinEnter,BufNewFile,BufRead *.sapf set filetype=sapf
endif
