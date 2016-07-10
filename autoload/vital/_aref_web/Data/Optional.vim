" ___vital___
" NOTE: lines between '" ___vital___' is generated by :Vitalize.
" Do not mofidify the code nor insert new lines before '" ___vital___'
if v:version > 703 || v:version == 703 && has('patch1170')
  function! vital#_aref_web#Data#Optional#import() abort
    return map({'flatten': '', 'some': '', 'apply': '', 'set': '', 'get_unsafe': '', 'is_optional': '', 'echo': '', 'exists': '', 'none': '', 'empty': '', 'get': '', 'has': '', 'unset': '', 'bind': '', 'get_or': ''},  'function("s:" . v:key)')
  endfunction
else
  function! s:_SID() abort
    return matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze__SID$')
  endfunction
  execute join(['function! vital#_aref_web#Data#Optional#import() abort', printf("return map({'flatten': '', 'some': '', 'apply': '', 'set': '', 'get_unsafe': '', 'is_optional': '', 'echo': '', 'exists': '', 'none': '', 'empty': '', 'get': '', 'has': '', 'unset': '', 'bind': '', 'get_or': ''}, \"function('<SNR>%s_' . v:key)\")", s:_SID()), 'endfunction'], "\n")
  delfunction s:_SID
endif
" ___vital___
let s:save_cpo = &cpo
set cpo&vim

let s:ARRAY_TYPE = type([])

function! s:none() abort
  return []
endfunction

function! s:some(v) abort
  return [a:v]
endfunction

function! s:is_optional(v) abort
  return type(a:v) == s:ARRAY_TYPE && len(a:v) <= 1
endfunction

function! s:empty(o) abort
  return empty(a:o)
endfunction

function! s:exists(o) abort
  return !empty(a:o)
endfunction

function! s:set(o, v) abort
  if empty(a:o)
    call add(a:o, a:v)
  else
    let a:o[0] = a:v
  endif
endfunction

function! s:unset(o) abort
  if !empty(a:o)
    unlet! a:o[0]
  endif
endfunction

function! s:get(o) abort
  if empty(a:o)
    throw 'vital: Data.Optional: An empty Data.Optional value'
  endif
  return a:o[0]
endfunction

function! s:get_unsafe(o) abort
  return a:o[0]
endfunction

function! s:get_or(o, alt) abort
  return get(a:o, 0, a:alt)
endfunction

function! s:has(o, type) abort
  if empty(a:o)
    return 0
  else
    return type(a:o[0]) == a:type
  endif
endfunction

function! s:_valid_args(args) abort
  for Arg in a:args
    if !s:is_optional(Arg)
      throw 'vital: Data.Optional: Non-optional argument'
    endif
    unlet Arg
  endfor

  for Arg in a:args
    if empty(Arg)
      return 0
    endif
    unlet Arg
  endfor

  return 1
endfunction

function! s:apply(f, ...) abort
  if !s:_valid_args(a:000)
    return s:none()
  endif

  return s:some(call(a:f, map(copy(a:000), 'v:val[0]')))
endfunction

function! s:bind(f, ...) abort
  if !s:_valid_args(a:000)
    return s:none()
  endif

  return call(a:f, map(copy(a:000), 'v:val[0]'))
endfunction

function! s:flatten(o, ...) abort
  if (a:0 > 0 && a:1 == 0)
        \ || !s:is_optional(a:o)
        \ || empty(a:o)
        \ || !s:is_optional(a:o[0])
    return a:o
  endif

  if a:0 > 0
    return s:flatten(a:o[0], a:1 - 1)
  else
    return s:flatten(a:o[0])
  endif
endfunction

function! s:_echo(msg, hl) abort
  if empty(a:hl)
    echo a:msg
  else
    execute 'echohl' a:hl[0]
    echo a:msg
    echohl None
  endif
endfunction

function! s:echo(o, ...) abort
  if !s:is_optional(a:o)
    throw 'vital: Data.Optional: Not an optional value'
  endif

  if empty(a:o)
    call s:_echo('None', a:000)
  else
    call s:_echo('Some(' . string(a:o[0]) . ')', a:000)
  endif
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
