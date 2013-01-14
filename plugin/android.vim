
let s:project_root = getcwd()

" {{{ Utils
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

" Search subdirectories for a test project. Return the test project
" root directory if found.
function! s:getTestBuildFile()
  " We make the assumption here that if a subdirectory contains
  " a build.xml file that it is the test project for our current project.
  return findfile('build.xml', s:project_root . '/*')
endfunction
" }}}
" {{{ External Commands (android, ant, etc.)
function! s:callAndroid(...)
  redir => output
    execute 'silent !android ' . join(a:000, ' ')
  redir END

  return output
endfunction

function! s:callAnt(...)
  let makeprg = &makeprg
  let &makeprg = 'ant ' . join(a:000)

  let errorformat = &errorformat
  set errorformat=%A\ %#[javac]\ %f:%l:\ %m,%-Z\ %#[javac]\ %p^,%-C%.%#

  make

  let &makeprg = makeprg
  let &errorformat = errorformat
endfunction

function! s:listTargets()
  let output = s:callAndroid('list', 'targets')

  let list = split(output, "\<enter>\n")

  " The top line here is garbage.
  call remove(list, 0)
  call s:fillBuffer('temp', join(list, "\n"))
endfunction

function! s:runTests()
  call s:callAnt('debug', 'install', 'test', '-f', s:getTestBuildFile())
endfunction
" }}}
" {{{ Navigation
function! s:gotoAndroid() abort

  let line = getline(line('.'))
  let resource_pattern = '\vR\.([^.]+)\.(\w+)'
  let start = match(line, resource_pattern)
  let end = matchend(line, resource_pattern)

  let col = col('.')
  if col > start && col <= end
    let matches = matchlist(line, resource_pattern)
    let type = matches[1]
    let name = matches[2]

    let res_dir = s:project_root . '/res'

    let dir = finddir(type, res_dir)
    if dir == ''
      " Directory not found, let's check in values.
      let file = findfile(type . 's.xml', res_dir . '/values')

      if file != ''
        execute 'edit ' . file
        call search('\vname\=("|'')' . name . '("|'')[^>]*\>.', 'we')
      endif
    else
      let file = findfile(name . '.xml', dir)

      if file != ''
        execute 'edit ' . file
      endif
    endif

  else
    " Item doesn't appear to be a resource pass the call onto tags.
    try
      normal! 
    catch /E426/
      echohl ErrorMsg | echom v:errmsg | echohl None
    endtry
  endif

endfunction

" TODO: Only set the path if we are in an android project.
" Set up our the path for find.

" Remove /usr/include we won't need it.
set path-=/usr/include
" Add source and res directories
set path+=src/**/*,res/**/*
" }}}

command! Adebug call s:callAnt('debug')
command! Arelease call s:callAnt('release')
command! Ainstalld call s:callAnt('installd')
command! Ainstallr call s:callAnt('installr')
command! Adebugi call s:callAnt('debug install')
command! Areleasei call s:callAnt('release install')
command! Aclean call s:callAnt('clean')
command! Atest call s:runTests()

command! Alisttargets call s:listTargets()

command! Agoto call s:gotoAndroid()
