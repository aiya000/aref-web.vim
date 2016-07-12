"-------------------"
" Variables

" If any job is progressive, this value is set v:true .
" and this value is set v:false when it job terminated .
" this value is set by s:open_webpage_buffer_async() .
"
" this value for parallel execution these.
" > :Aref weblio foo
" > :Aref weblio bar
let s:another_job_progresssive = v:false


"-------------------"
" subroutine functions

" Convert numeric_boolean to boolean
function! s:bool(num) abort " {{{
	return (a:num is 0) ? v:false : v:true
endfunction " }}}

" If not exists Vital.Data.List yet, load it.
" and Return Vital.Data.List instance.
function! s:load_data_list() abort " {{{
	if !exists('s:List')
		let s:List = vital#aref_web#import('Data.List')
	endif
	return s:List
endfunction " }}}

" If not exists Vital.Data.String yet, load it.
" and Return Vital.Data.String instance.
function! s:load_data_string() abort " {{{
	if !exists('s:String')
		let s:String = vital#aref_web#import('Data.String')
	endif
	return s:String
endfunction " }}}

" If not exists Vital.Data.Optional yet, load it.
" and Return Vital.Data.Optional instance.
function! s:load_data_optional() abort " {{{
	if !exists('s:Optional')
		let s:Optional = vital#aref_web#import('Data.Optional')
	endif
	return s:Optional
endfunction " }}}

" If keys(g:aref_web_source) contains a:source_name, Return true.
" otherwise Return false.
function! s:is_supported_source(source_name) abort " {{{
	let l:supported_sources = keys(g:aref_web_source)
	return s:load_data_list().has(l:supported_sources, a:source_name)
endfunction " }}}

" If you have cui web browser, Return true.
" otherwise Return false.
function! s:can_use_dump_cmd() abort " {{{
	return !empty(g:aref_web_dump_cmd)
endfunction " }}}

" If you have open-browser.vim, Return v:true.
" otherwise Return v:false.
function! s:have_openbrowser_vim() abort " {{{
	try
		call openbrowser#load()
		return v:true
	catch /E117/
		return v:false
	endtry
endfunction " }}}

" Do echomsg the error
function! s:echo_error(msg) abort " {{{
	echohl Error
	echomsg a:msg
	echohl None
endfunction " }}}

"Example: echo s:get_target_url('stackage', ['Int', '->', 'Int'])
"  ==> 'https://www.stackage.org/(lts-5.15 or other version)/hoogle?q=Int+->+Int
function! s:get_target_url(source_name, param_list) abort " {{{
	"Example: Aref stackage Int -> Int  ==>  l:request_param == 'Int+->+Int'
	"Example: Aref stackage ($$+-)      ==>  l:request_param == '($$%2B-)'
	" Avoid invalid url generating
	let l:encoded_param_list = map(a:param_list, 'substitute(v:val, "+", "%2B", "g")')
	let l:request_params     = join(l:encoded_param_list, '+')
	return printf(g:aref_web_source[a:source_name].url, l:request_params)
endfunction " }}}

"Example: echo s:get_buffer_name('stackage', ['Int', '->', 'Int'])
"  ==> '[aref-web: stackage Int -> Int]'
function! s:get_buffer_name(source_name, params) abort " {{{
	let l:base = '[aref-web: %s]'
	let l:body = a:source_name . ' ' . join(a:params)
	return printf(l:base, l:body)
endfunction " }}}

" Do nmap for filetype=aref_web buffer
function! s:map_default_keys() abort " {{{
	nmap <buffer> O     <Plug>(aref_web_open_browser_current_url)
	nmap <buffer> <C-a> <Plug>(aref_web_show_next_page)
	nmap <buffer> <C-x> <Plug>(aref_web_show_prev_page)
endfunction " }}}

" Load webpage detail of a:request_url async.
" and Open its buffer async.
function! s:open_webpage_buffer_async(buffer_name, request_url, search_keywords) abort " {{{
	" Progress only one job
	if s:another_job_progresssive
		" Recurse by timer
		call timer_start(3000, function('s:open_webpage_buffer_async', [a:buffer_name, a:request_url, a:search_keywords]))
		return
	endif
	" Represent starting current job progress
	let s:another_job_progresssive = v:true

	"-- These s: scope variables will be unlet by ArefWebOpenBuffer()
	" Binding to s: scope
	let s:buffer_name = a:buffer_name
	let s:request_url = a:request_url
	"Example: ['a', '->', 'b'] ==> 'a -> b'
	let s:search_keywords = join(a:search_keywords)
	" job_start()'s result
	let s:stdout_result = ''
	" Referenced by job_start() and ArefWebOpenBuffer()
	let s:tempname = tempname() . '.html'
	"--

	" "out_cb" function for "curl {url} -o {s:tempname}"
	function! s:aggregate_stdout(_, stdout) abort
		let s:stdout_result .= a:stdout
	endfunction

	" "exit_cb" function for "curl {url} -o {s:tempname}"
	function! ArefWebOpenBuffer(_, __) abort
		execute 'new' s:buffer_name
		" Set buffer type of scratch
		setl noswapfile buftype=nofile filetype=aref_web
		"----------"
		" Show html page detail
		let l:dump_cmd = printf(g:aref_web_dump_cmd, s:tempname)
		1put!=system(l:dump_cmd)
		execute 'normal! G"_ddgg'

		" Save url for open-browser.vim
		let b:aref_web_current_url = s:request_url

		" Mapping default keymappings
		if g:aref_web_enable_default_keymappings
			call s:map_default_keys()
		endif

		" Highlight searched keyword
		execute printf('syntax match arefWebKeyword "%s"', s:search_keywords)
		highlight default link arefWebKeyword Special
		"----------"
		unlet s:buffer_name s:request_url s:search_keywords s:stdout_result s:tempname
		setl nomodifiable
		wincmd p
		" Represent current job termination
		let s:another_job_progresssive = v:false
	endfunction

	"NOTE:
	" Why "exit_cb" don't use funcref ?
	" It's derived vim spec
	let l:command = printf('curl %s -o %s', a:request_url, s:tempname)
	call job_start(l:command, {
	\	'out_cb'  : function('s:aggregate_stdout'),
	\	'exit_cb' : 'ArefWebOpenBuffer'
	\})
endfunction " }}}

" Check url format.
" If url's query parameter contains num, return v:true.
" otherwise return v:false
function! s:url_has_page_num(url) abort " {{{
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
" otherwise Return none.
function! s:get_next_page_url(current_url) abort " {{{
	let l:O = s:load_data_optional()
	let l:S = s:load_data_string()

	if !s:url_has_page_num(a:current_url)
		return l:O.none()
	endif
	let l:page_num     = matchstr(a:current_url, '=\zs\d\+\ze')
	let l:nextpage_url = l:S.substitute_last(a:current_url, '=\zs\d\+\ze', l:page_num + 1)
	return l:O.some(l:nextpage_url)
endfunction " }}}

" If url has page num, return previous page url.
" otherwise return none.
function! s:get_prev_page_url(current_url) abort " {{{
	let l:O = s:load_data_optional()
	let l:S = s:load_data_string()

	if !s:url_has_page_num(a:current_url)
		return l:O.none()
	endif
	let l:page_num     = matchstr(a:current_url, '=\zs\d\+\ze')
	let l:prevpage_url = l:S.substitute_last(a:current_url, '=\zs\d\+\ze', l:page_num - 1)
	return l:O.some(l:prevpage_url)
endfunction " }}}

" Like s:open_webpage_buffer_async(), but I don't open new buffer
" I use "target_aref_web_bufnr" buffer instead of new buffer
function! s:show_webpage_buffer_async(target_aref_web_bufnr, request_url) abort
	" Progress only one job
	if s:another_job_progresssive
		" Recurse by timer
		call timer_start(3000, function('s:show_webpage_buffer_async', [a:target_aref_web_bufnr, a:request_url]))
		return
	endif
	" Represent starting current job progress
	let s:another_job_progresssive = v:true

	"-- These s: scope variables will be unlet by ArefWebShowBuffer()
	" Binding to s: scope
	let s:target_bufnr = a:target_aref_web_bufnr
	let s:request_url  = a:request_url
	" job_start()'s result
	let s:stdout_result = ''
	" Referenced by job_start() and ArefWebShowBuffer()
	let s:tempname = tempname() . '.html'
	"--

	" "out_cb" function for "curl {url} -o {s:tempname}"
	function! s:aggregate_stdout(_, stdout) abort
		let s:stdout_result .= a:stdout
	endfunction

	" "exit_cb" function for "curl {url} -o {s:tempname}"
	function! ArefWebShowBuffer(_, __) abort
		let l:current_bufnr = winbufnr('.')
		execute 'buffer' s:target_bufnr
		" Unlock for modifying
		setl modifiable
		"----------"
		" Show html page detail
		let l:dump_cmd = printf(g:aref_web_dump_cmd, s:tempname)
		execute 'normal! gg"_dG'
		1put!=system(l:dump_cmd)
		execute 'normal! G"_ddgg'

		" Save url for open-browser.vim
		let b:aref_web_current_url = s:request_url

		"----------"
		unlet s:request_url s:stdout_result s:tempname
		setl nomodifiable
		execute 'buffer' l:current_bufnr
		" Represent current job termination
		let s:another_job_progresssive = v:false
	endfunction

	"NOTE:
	" Why "exit_cb" don't use funcref ?
	" It's derived vim spec
	let l:command = printf('curl %s -o %s', a:request_url, s:tempname)
	call job_start(l:command, {
	\	'out_cb'  : function('s:aggregate_stdout'),
	\	'exit_cb' : 'ArefWebShowBuffer'
	\})
endfunction


"-------------------"
" autoload functions

" Open webpage buffer async
function! aref_web#open_webpage(...) abort
	let l:source_name = a:1
	if !s:is_supported_source(l:source_name)
		call s:echo_error(l:source_name . ' is not supported.')
		call s:echo_error('Please verify g:loaded_aref_web')
		return
	endif
	if !s:can_use_dump_cmd()
		call s:echo_error('Sorry. aref_web.vim needs w3m, lynx, elinks or links browser.')
		call s:echo_error('Please add it to your $PATH')
		return
	endif
	let l:request_url = s:get_target_url(l:source_name, a:000[1:])
	let l:buffer_name = s:get_buffer_name(l:source_name, a:000[1:])
	call s:open_webpage_buffer_async(l:buffer_name, l:request_url, a:000[1:])
endfunction


" Open current url by open-browser.vim in filetype=aref_web buffer
function! aref_web#open_browser() abort
	if !s:have_openbrowser_vim()
		call s:echo_error('calling open-browser.vim failed')
		call s:echo_error('Please install and load open-browser.vim')
		return
	endif
	if &filetype !=# 'aref_web'
		call s:echo_error('Invalid call situation')
		call s:echo_error('Please call from filetype=aref_web buffer')
		return
	endif
	call openbrowser#open(b:aref_web_current_url)
endfunction


" Show next page
function! aref_web#show_next_page() abort
	let l:O = s:load_data_optional()

	let l:maybe_nextpage_url = s:get_next_page_url(b:aref_web_current_url)
	if l:O.empty(l:maybe_nextpage_url)
		echohl Error
		echo "Sorry, this site url doesn't support page moving"
		echohl None
		return
	endif

	echo 'aref_web> go to next page'
	let l:nextpage_url  = l:O.get_unsafe(l:maybe_nextpage_url)
	let l:current_bufnr = winbufnr('.')
	call s:show_webpage_buffer_async(l:current_bufnr, l:nextpage_url)
endfunction


" Show previous page
function! aref_web#show_prev_page() abort
	let l:O = s:load_data_optional()

	let l:maybe_prevpage_url = s:get_prev_page_url(b:aref_web_current_url)
	if l:O.empty(l:maybe_prevpage_url)
		echohl Error
		echo "Sorry, this site url doesn't support page moving"
		echohl None
		return
	endif

	echo 'aref_web> go to previous page'
	let l:prevpage_url  = l:O.get_unsafe(l:maybe_prevpage_url)
	let l:current_bufnr = winbufnr('.')
	call s:show_webpage_buffer_async(l:current_bufnr, l:prevpage_url)
endfunction
