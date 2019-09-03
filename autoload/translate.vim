let s:default_options   = get(g:, 'translate#default_options', '-no-ansi -no-auto -no-warn -brief')
let s:default_languages = get(g:, 'translate#default_languages', {})

let s:base_cmd = 'trans ' . s:default_options
let s:is_win = has('win32') || has('win64')

" {{{ Exposed

function! translate#run_replace(type) abort
    call translate#run(a:type, '', '!')
endfunction

function! translate#run(type, ...) range abort
  if !s:check_executable() | return | endif

  let l:source_target = get(a:, 1, '')
  let l:replace = get(a:, 2, '')

  let l:regtype = getregtype('a')
  let l:regtext = getreg('a')

  if a:type ==# 'visual'
    silent! normal! gv"ay
  elseif a:type ==# 'lrange'
    silent! exe 'normal! '.a:firstline.'GV'.a:lastline.'G"ay'
  elseif a:type ==# 'char'
    silent! normal! `[v`]"ay
  elseif a:type ==# 'line'
    silent! normal! '[V']"ay
  else
    " Forget about blockwise operator for now, it's unlikely
    return
  endif

  let l:seltype = a:type ==# 'visual' ? visualmode() : a:type[0]
  call setreg('a', s:translate(l:source_target, @a), l:seltype)
  if l:replace !=# ''
    silent! normal! gv"ap
  else
    call translate#open_trans_buf(@a)
  endif

  call setreg('a', l:regtext, l:regtype)
endfunction

function! translate#open_trans_buf(text) abort
  let l:winnr = winnr()
  call translate#clear_trans_buf()
  silent! botright 8new Translation
  set buftype=nofile
  set bufhidden=hide
  set nobuflisted
  set noswapfile
  let s:trans_buf = bufnr('%')

  let @a = a:text
  silent! put! a
  execute('resize ' . line('$'))
  silent! normal! gg

  if (l:winnr != winnr())
    wincmd p
  endif
endfunction

function! translate#clear_trans_buf() abort
  if exists('s:trans_buf') && bufexists(s:trans_buf)
    sil! exe 'bd! ' . s:trans_buf
    unlet s:trans_buf
  endif
endfunction

"}}}

"{{{ Helpers

function! s:translate(source_target, text) abort
  echo 'Translating...'
  let l:source_target = s:get_source_target(a:text, a:source_target)

  redraw | echo 'Translating ' . l:source_target . '...'
  " let l:cmd = s:base_cmd . ' ' . l:source_target
  " let l:result = system(l:cmd, a:text)[:-2]
  let l:result = system(s:base_cmd, a:text)[:-2]

  redraw | echo ''
  return l:result
endfunction

function! s:get_source_target(text, source_target) abort
  if (a:source_target !=# '') 
    return a:source_target
  endif

  let l:source_lang = system(s:base_cmd .' -id ' . shellescape(a:text))[:-2]
  if (!has_key(s:default_languages, l:source_lang)) 
    return '' 
  endif

  let l:target_lang = s:default_languages[l:source_lang]
  return l:source_lang . ':' . l:target_lang
endfunction

function! s:msg_error(str) abort
  echohl ErrorMsg 
  echo a:str
  echohl None
endfunction

function! s:check_executable() abort
  " translate-shell works on windows via WSL or cygwin
  " Thus we must set vim shell accordingly.
  " However executable() doesn't seem to check to right $PATH 
  " So bypassing that check on windows for now
  if s:is_win
    return 1
  endif

  if !executable('trans')
    call s:msg_error('translate-shell not found. Please install it.')
    return 0
  endif

  return 1
endfunction

function! s:is_trans_buf_open() abort
  return exists('s:trans_buf') && bufnr('%') == s:trans_buf
endfunction

"}}}

augroup translate
  autocmd!
  autocmd bufenter * if (winnr("$") == 1 && s:is_trans_buf_open()) | q! | endif
augroup END
