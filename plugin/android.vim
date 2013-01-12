function! s:fillBuffer(buf_name, text)
  let temp_o = @o
  let @o = a:text

  execute 'split ' . a:buf_name

  setlocal modifiable noreadonly
  " Delete anything that may be in the buffer
  silent %delete
  silent 0put o

  setlocal nomodifiable readonly nomodified bufhidden=delete
  let @o = temp_o
endfunction

function! s:callAndroid(...)
  redir => output
    execute 'silent !android ' . join(a:000, ' ')
  redir END

  return output
endfunction

function! s:listTargets()
  let output = s:callAndroid('list', 'targets')

  let list = split(output, "\<enter>\n")
  let g:test_list = list

  " The top line here is garbage.
  call remove(list, 0)
  call s:fillBuffer('temp', join(list, "\n"))
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
