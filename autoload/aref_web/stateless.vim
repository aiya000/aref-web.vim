let s:V = vital#aref_web#new()

let s:Option = s:V.import('Data.Optional')
let s:String = s:V.import('Data.String')

"
" Stateless helper functions
"

"---

" Convert numeric_boolean to boolean
function! s:bool(num) abort " {{{
    return (a:num is 0) ? v:false : v:true
endfunction " }}}

"---

"Example: echo aref_web#stateless#get_buffer_name('stackage', ['Int', '->', 'Int'])
"  ==> '[aref-web: stackage Int -> Int]'
function! aref_web#stateless#get_buffer_name(source_name, params) abort " {{{
    let l:base = '[aref-web: %s]'
    let l:body = a:source_name . ' ' . join(a:params)
    return printf(l:base, l:body)
endfunction " }}}

" Check url format.
" If url's query parameter contains num, return v:true.
" otherwise return v:false
function! aref_web#stateless#url_has_page_num(url) abort " {{{
    " If url string doesn't have "?", url doesn't have query parameter
    if match(a:url, '?') is -1
        return v:false
    endif

    " Does the url parameters contain some num ?
    let [_, l:params] = split(a:url, '?')
    let l:result      = match(l:params, '=\d') isnot -1
    return s:bool(l:result)
endfunction " }}}

" If url has page num, return next page url.
" otherwise return none.
function! aref_web#stateless#get_next_page_url(current_url) abort " {{{
    if !aref_web#stateless#url_has_page_num(a:current_url)
        return s:Option.none()
    endif
    let l:page_num     = matchstr(a:current_url, '=\zs\d\+\ze')
    let l:nextpage_url = s:String.substitute_last(a:current_url, '=\zs\d\+\ze', l:page_num + 1)
    return s:Option.some(l:nextpage_url)
endfunction " }}}

" If url has page num, return previous page url.
" otherwise return none.
function! aref_web#stateless#get_prev_page_url(current_url) abort " {{{
    if !aref_web#stateless#url_has_page_num(a:current_url)
        return s:Option.none()
    endif
    let l:page_num     = matchstr(a:current_url, '=\zs\d\+\ze')
    let l:prevpage_url = s:String.substitute_last(a:current_url, '=\zs\d\+\ze', l:page_num - 1)
    return s:Option.some(l:prevpage_url)
endfunction " }}}
