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

" If not exists Vital.Data.List yet, load it.
" and Return Vital.Data.List instance.
function! s:load_data_list() abort " {{{
	if !exists('s:List')
		let s:List = vital#aref_web#import('Data.List')
	endif
	return s:List
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
	nmap <buffer> O <Plug>(aref_web_open_browser_current_url)
endfunction " }}}

" Load webpage detail of a:request_url async.
" and Open its buffer async.
function! s:open_webpage_buffer_async(buffer_name, request_url, search_keywords, _) abort " {{{
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
	" Be referenced by job_start() and ArefWebOpenBuffer()
	let s:tempname = tempname() . '.html'
	"--

	" "out_cb" function for "curl {url} -o {s:tempname}"
	function! s:aggregate_stdout(_, stdout) abort
		let s:stdout_result .= a:stdout
	endfunction

	" "exit_cb" function for "curl {url} -o {s:tempname}"
	function! ArefWebOpenBuffer(_, __) abort
		execute 'new' s:buffer_name
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
	let l:command  = printf('curl %s -o %s', a:request_url, s:tempname)
	call job_start(l:command, {
	\	'out_cb'  : function('s:aggregate_stdout'),
	\	'exit_cb' : 'ArefWebOpenBuffer'
	\})
endfunction " }}}


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
	call s:open_webpage_buffer_async(l:buffer_name, l:request_url, a:000[1:], v:null)
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
