function! s:callAndroid(...)
  redir => output
    execute 'silent !android ' . join(a:000, ' ')
  redir END

  return output
endfunction

function! s:listTargets()
  let temp_o = @o
  let @o = s:callAndroid('list', 'targets')

  pedit temp
  wincmd j

  let @o = substitute(@o, "\<enter>", '', 'g')

  setlocal modifiable noreadonly
  " Delete anything that may be in the buffer
  silent %delete
  silent put o

  " The top three lines of the register are garbage.
  silent 0,3delete
  setlocal nomodifiable readonly nomodified
  let @o = temp_o
endfunction

function! s:build(type)
  execute '!ant ' . a:type
endfunction

" Set up our the path for find.

" Remove /usr/include we won't need it.
set path-=/usr/include
" Add source and res directories
set path+=src/**/*,res/**/*

command! Abuild call s:build('debug')
command! Alisttargets call s:listTargets()
