scriptencoding utf-8

function! s:find_match(start, end, flags) abort
    return searchpairpos(a:start, '', a:end, a:flags)
endfunction

function!sapf#editor#get_block() abort
    let start_char_sym = '('
    let end_char_sym = ')'
    let start_pos = [0, 0]
    let end_pos = [0, 0]
    let forward_flags = 'nW'
    let backward_flags = 'nbW'
    let c_curpos = getcurpos()
    call setpos('.', [0, c_curpos[1], 1, 0])
    let [xs, ys] = s:find_match(start_char_sym, end_char_sym, backward_flags)
    let start_pos = [xs, ys]
    if xs == 0 && ys == 0
      let start_pos = [line('.'), col('.')]
    else
      while xs > 0 && ys > 0
        call setpos('.', [0, xs, ys, 0])
        let start_pos = [xs, ys]
        let [xs, ys] = s:find_match(start_char_sym, end_char_sym, backward_flags)
      endwhile
    endif
    call setpos('.', [0, start_pos[0], start_pos[1], 0])
    let end_pos = s:find_match(start_char_sym, end_char_sym, forward_flags)
    call setpos('.', c_curpos)
    return [start_pos[0], end_pos[0]]
endfunction

function!sapf#editor#get_visual_selection() abort
  exe "normal! \<Esc>"
  exe "normal! gv"
  let [lnum1, col1] = getpos("'<")[1:2]
  let [lnum2, col2] = getpos("'>")[1:2]
  if &selection ==# 'exclusive'
    let col2 -= 1
  endif
  let lines = getline(lnum1, lnum2)
  if !empty(lines)
    let lines[-1] = lines[-1][:col2 - 1]
    let lines[0] = lines[0][col1 - 1:]
  endif
  return {
  \ 'lines': lines,
  \ 'line_start': lnum1,
  \ 'line_end': lnum2,
  \ 'col_start': col1,
  \ 'col_end': col2,
  \ }
endfunction
