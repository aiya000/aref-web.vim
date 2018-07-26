let s:V = vital#aref_web#new()

let s:Job = s:V.import('System.Job')
let s:Msg = s:V.import('Vim.Message')
let s:Option = s:V.import('Data.Optional')

"-------------------"
" Variables

" The global value.
"
" If any job is progressive, this value is set v:true .
" and this value is set v:false when it job terminated .
" this value is set by s:open_webpage_buffer_async() .
"
" this value for parallel execution these.
" > :Aref weblio foo
" > :Aref weblio bar
let s:another_job_progresssive = v:false

"---------
" OPENER_SCOPE is used the open_webpage_buffer_async()'s job instead of the global variable
let s:OPENER_SCOPE = {}

" `buffer_name` is used as the name buffer of the web page view.
" `request_url` for the fetching web page,
"     and this is shared by the each jobs and timers.
" `search_keyword` for the highlighting only in the buffer.
" `curl_tempname` is used between and the curl command and a job,
"     and this is unique in the OPENER_SCOPE instances.
" `job_stdout_result` is created from `instance.job_stdout_aggregator()` only
function! s:OPENER_SCOPE.new(buffer_name, request_url, search_keywords) dict abort
    "NOTE: Is The search_keywords handling appropriate?
    let new_instance = {
        \ 'buffer_name'       : a:buffer_name,
        \ 'request_url'       : a:request_url,
        \ 'search_keyword'    : join(a:search_keywords),
        \ 'curl_tempname'     : tempname() . '.html',
        \ 'job_stdout_result' : '!!! undefined !!!'
    \ }
    return new_instance
endfunction

lockvar! s:OPENER_SCOPE

" Aggregate the stdout result to a:aref_web_scope.job_stdout_result asynchronously.
" Be used with the partial applying
function! s:job_stdout_aggregate_to(aref_web_scope, _, data, __) abort
    for line in a:data
        let a:aref_web_scope.job_stdout_result .= line
    endfor
endfunction


"---------
" SHOWER_SCOPE is used the show_webpage_buffer_async()'s job instead of the global variable
let s:SHOWER_SCOPE = copy(s:OPENER_SCOPE)

function! s:SHOWER_SCOPE.new(opener_scope, new_request_url, working_bufnr) dict abort
    " Overwrite .request_url
    return extend(a:opener_scope, {
        \ 'request_url'   : a:new_request_url,
        \ 'working_bufnr' : a:working_bufnr
    \ })
endfunction

lockvar! s:SHOWER_SCOPE


"-------------------"
" subroutine functions

" Load webpage detail of a:request_url async.
" and Open its buffer async.
function! s:open_webpage_buffer_async(opener_scope, timer) abort " {{{
    " Progress only one job
    if s:another_job_progresssive
        "NOTE: Neovim doesn't support the partial applying now
        call timer_start(3000, function('s:open_webpage_buffer_async', [a:opener_scope]))
        return
    endif
    " Represent starting current job progress
    let s:another_job_progresssive = v:true
    " Initialize Job.start()'s result
    let s:stdout_result = ''

    " The "on_exit" function for "curl {url} -o {s:tempname}"
    function! s:open_webpage_buffer(opener_scope, _, __, ___) abort
        execute g:aref_web_buffer_opening a:opener_scope.buffer_name
        " Set buffer type of scratch
        setl noswapfile buftype=nofile filetype=aref_web
        " Unlock extended lock
        setl modifiable noreadonly
        "----------"
        " Show html page detail
        let dump_cmd = printf(g:aref_web_dump_cmd, a:opener_scope.curl_tempname)
        1put!=system(dump_cmd)
        execute 'normal! G"_ddgg'

        " Save the scope for aref_web#show_{next,prev}_page() and aref_web#open_browser()
        let b:aref_web_scope = a:opener_scope

        " Mapping default keymappings
        if g:aref_web_enable_default_keymappings
            call aref_web#stateful#map_default_keys()
        endif

        " Highlight searched keyword
        execute printf('syntax match arefWebKeyword "%s"', a:opener_scope.search_keyword)
        highlight default link arefWebKeyword Special
        "----------"
        setl nomodifiable
        wincmd p
        " Represent current job termination
        let s:another_job_progresssive = v:false
    endfunction

    "FIXME: Branch into Job.vim
    if has('nvim')
        let command = printf('curl "%s" -o %s', a:opener_scope.request_url, a:opener_scope.curl_tempname)
    else
        let command = printf('curl %s -o %s', a:opener_scope.request_url, a:opener_scope.curl_tempname)
    endif
    call s:Job.start(command, {
        \ 'on_stdout' : function('s:job_stdout_aggregate_to', [a:opener_scope]),
        \ 'on_exit'   : function('s:open_webpage_buffer', [a:opener_scope])
    \ })
endfunction " }}}

" Like s:open_webpage_buffer_async(), but I don't open new buffer
" I use "working_aref_web_bufnr" buffer instead of new buffer
function! s:show_webpage_buffer_async(shower_scope, timer) abort " {{{

    " Progress only one job
    if s:another_job_progresssive
        "NOTE: Neovim doesn't support the partial applying now
        call timer_start(3000, function('s:show_webpage_buffer_async', [a:shower_scope]))
        return
    endif
    " Represent starting current job progress
    let s:another_job_progresssive = v:true

    " The "on_exit" function for "curl {url} -o {s:tempname}"
    function! s:show_webpage_buffer(shower_scope, _, __, ___) abort
        let current_bufnr = winbufnr('.')
        execute 'buffer!' a:shower_scope.working_bufnr
        " Unlock for modifying
        setl modifiable
        "----------"
        " Show html page detail
        let dump_cmd = printf(g:aref_web_dump_cmd, a:shower_scope.curl_tempname)
        execute 'normal! gg"_dG'
        1put!=system(dump_cmd)
        execute 'normal! G"_ddgg'

        " Save the scope for aref_web#show_{next,prev}_page() and aref_web#open_browser()
        let b:aref_web_scope = a:shower_scope

        "----------"
        setl nomodifiable
        execute 'buffer' current_bufnr
        " Represent current job termination
        let s:another_job_progresssive = v:false
    endfunction

    "FIXME: Branch into Job.vim
    if has('nvim')
        let command = printf('curl "%s" -o %s', a:shower_scope.request_url, a:shower_scope.curl_tempname)
    else
        let command = printf('curl %s -o %s', a:shower_scope.request_url, a:shower_scope.curl_tempname)
    endif
    call s:Job.start(command, {
        \ 'on_stdout' : function('s:job_stdout_aggregate_to', [a:shower_scope]),
        \ 'on_exit'   : function('s:show_webpage_buffer', [a:shower_scope])
    \ })
endfunction " }}}


"-------------------"
" autoload functions

" Open webpage buffer async
function! aref_web#open_webpage(...) abort
    let source_name = a:1
    if !aref_web#stateful#is_supported_source(source_name)
        call s:Msg.error(source_name . ' is not supported.')
        call s:Msg.error('Please verify g:loaded_aref_web')
        return
    endif
    if !aref_web#stateful#can_use_dump_cmd()
        call s:Msg.error('Sorry. aref_web.vim needs w3m, lynx, elinks or links browser.')
        call s:Msg.error('Please add it to your $PATH')
        return
    endif
    let search_keywords = a:000[1:]
    let request_url     = aref_web#stateful#get_target_url(source_name, search_keywords)
    let buffer_name     = aref_web#stateless#get_buffer_name(source_name, search_keywords)

    let s:Optionpener_scope = s:OPENER_SCOPE.new(buffer_name, request_url, search_keywords)
    call s:open_webpage_buffer_async(s:Optionpener_scope, v:null)
endfunction


" Open current url by open-browser.vim in filetype=aref_web buffer
function! aref_web#open_browser() abort
    if !aref_web#stateful#have_openbrowser_vim()
        call s:Msg.error('calling open-browser.vim failed')
        call s:Msg.error('Please install and load open-browser.vim')
        return
    endif
    if &filetype !=# 'aref_web'
        call s:Msg.error('Invalid call situation')
        call s:Msg.error('Please call from filetype=aref_web buffer')
        return
    endif
    call openbrowser#open(b:aref_web_scope.request_url)
endfunction


" Show next page
function! aref_web#show_next_page() abort
    let s:Msgaybe_nextpage_url = aref_web#stateless#get_next_page_url(b:aref_web_scope.request_url)
    if s:Option.empty(s:Msgaybe_nextpage_url)
        call s:Msg.error("Sorry, this site url doesn't support page moving")
        return
    endif

    echo 'aref_web> go to next page'
    let nextpage_url  = s:Option.get_unsafe(s:Msgaybe_nextpage_url)
    let working_bufnr = winbufnr('.')
    let shower_scope  = s:SHOWER_SCOPE.new(b:aref_web_scope, nextpage_url, working_bufnr)
    call s:show_webpage_buffer_async(shower_scope, v:null)
endfunction


" Show previous page
function! aref_web#show_prev_page() abort
    let prevpage_url = aref_web#stateless#get_prev_page_url(b:aref_web_scope.request_url)
    if s:Option.empty(prevpage_url)
        call s:Msg.error("Sorry, this site url doesn't support page moving")
        return
    endif
    let prevpage_url  = s:Option.get_unsafe(prevpage_url)

    echo 'aref_web> go to previous page'
    let working_bufnr = winbufnr('.')
    let shower_scope  = s:SHOWER_SCOPE.new(b:aref_web_scope, prevpage_url, working_bufnr)
    call s:show_webpage_buffer_async(shower_scope, v:null)
endfunction


" Completion
function! aref_web#complete(_, __, ___) abort
    return keys(g:aref_web_source)
endfunction
