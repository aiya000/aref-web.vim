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
    let base = '[aref-web: %s]'
    let body = a:source_name . ' ' . join(a:params)
    return printf(base, body)
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
    let [_, params] = split(a:url, '?')
    let result      = match(params, '=\d') isnot -1
    return s:bool(result)
endfunction " }}}

" If url has page num, return next page url.
" otherwise return none.
function! aref_web#stateless#get_next_page_url(current_url) abort " {{{
    if !aref_web#stateless#url_has_page_num(a:current_url)
        return s:Option.none()
    endif
    let page_num     = matchstr(a:current_url, '=\zs\d\+\ze')
    let nextpage_url = s:String.substitute_last(a:current_url, '=\zs\d\+\ze', page_num + 1)
    return s:Option.some(nextpage_url)
endfunction " }}}

" If url has page num, return previous page url.
" otherwise return none.
function! aref_web#stateless#get_prev_page_url(current_url) abort " {{{
    if !aref_web#stateless#url_has_page_num(a:current_url)
        return s:Option.none()
    endif
    let page_num     = matchstr(a:current_url, '=\zs\d\+\ze')
    let prevpage_url = s:String.substitute_last(a:current_url, '=\zs\d\+\ze', page_num - 1)
    return s:Option.some(prevpage_url)
endfunction " }}}
