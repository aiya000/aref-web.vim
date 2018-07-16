let s:V = vital#aref_web#new()

let s:HTTP = s:V.import('Web.HTTP')
let s:List = s:V.import('Data.List')

" If you have open-browser.vim, return v:true.
" otherwise return v:false.
function! aref_web#stateful#have_openbrowser_vim() abort " {{{
    try
        call openbrowser#load()
        return v:true
    catch /E117/
        return v:false
    endtry
endfunction " }}}

" Do nmap for filetype=aref_web buffer
function! aref_web#stateful#map_default_keys() abort " {{{
    nmap <buffer> O     <Plug>(aref_web_open_browser_current_url)
    nmap <buffer> <C-a> <Plug>(aref_web_show_next_page)
    nmap <buffer> <C-x> <Plug>(aref_web_show_prev_page)
endfunction " }}}

" If keys(g:aref_web_source) contains a:source_name, return true.
" otherwise return false.
function! aref_web#stateful#is_supported_source(source_name) abort " {{{
    let supported_sources = keys(g:aref_web_source)
    return s:List.has(supported_sources, a:source_name)
endfunction " }}}

" If you have some CLI web browser, return true.
" otherwise return false.
function! aref_web#stateful#can_use_dump_cmd() abort " {{{
    return !empty(g:aref_web_dump_cmd)
endfunction " }}}

" Create special url for source_name with param_list
function! aref_web#stateful#get_target_url(source_name, param_list) abort " {{{
    let params        = map(a:param_list, 's:HTTP.encodeURI(v:val)')
    let request_query = join(params, '+')
    return printf(g:aref_web_source[a:source_name].url, request_query)
endfunction " }}}
