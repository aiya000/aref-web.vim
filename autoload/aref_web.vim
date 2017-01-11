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

" Aggregate async stdout result to s:stdout_result
function! s:aggregate_stdout(_, data, __) abort " {{{
	let s:stdout_result .= a:data
endfunction " }}}

" Load webpage detail of a:request_url async.
" and Open its buffer async.
function! s:open_webpage_buffer_async(buffer_name, request_url, search_keywords, timer) abort " {{{
	let l:Job = aref_web#vital_load#get('System.Job')

	" Progress only one job
	if s:another_job_progresssive
		" Recurse by timer
		call timer_start(3000, function('s:open_webpage_buffer_async', [a:buffer_name, a:request_url, a:search_keywords]))
		return
	endif
	" Represent starting current job progress
	let s:another_job_progresssive = v:true

	"-- These s: scope variables will be unlet by s:open_webpage_buffer()
	" Binding to s: scope
	let s:buffer_name     = a:buffer_name
	let s:request_url     = a:request_url
	let s:search_keywords = join(a:search_keywords)
	" Job.start()'s result
	let s:stdout_result = ''
	" Be referenced by Job.start() and s:open_webpage_buffer()
	let s:tempname = tempname() . '.html'
	"--

	" The "on_exit" function for "curl {url} -o {s:tempname}"
	function! s:open_webpage_buffer(_, __, ___) abort
		execute 'new' s:buffer_name
		" Set buffer type of scratch
		setl noswapfile buftype=nofile filetype=aref_web
		" Unlock extended lock
		setl modifiable noreadonly
		"----------"
		" Show html page detail
		let l:dump_cmd = printf(g:aref_web_dump_cmd, s:tempname)
		1put!=system(l:dump_cmd)
		execute 'normal! G"_ddgg'

		" Save url for open-browser.vim
		let b:aref_web_current_url = s:request_url

		" Mapping default keymappings
		if g:aref_web_enable_default_keymappings
			call aref_web#stateful#map_default_keys()
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

	" It's derived vim spec
	"FIXME: Branch into Job.vim
	if has('nvim')
		let l:command = printf('curl "%s" -o %s', a:request_url, s:tempname)
	else
		let l:command = printf('curl %s -o %s', a:request_url, s:tempname)
	endif
	call l:Job.start(l:command, {
	\	'on_stdout' : function('s:aggregate_stdout'),
	\	'on_exit'   : function('s:open_webpage_buffer')
	\})
endfunction " }}}

" Like s:open_webpage_buffer_async(), but I don't open new buffer
" I use "target_aref_web_bufnr" buffer instead of new buffer
function! s:show_webpage_buffer_async(target_aref_web_bufnr, request_url, timer) abort " {{{
	let l:Job = aref_web#vital_load#get('System.Job')

	" Progress only one job
	if s:another_job_progresssive
		" Recurse by timer
		call timer_start(3000, function('s:show_webpage_buffer_async', [a:target_aref_web_bufnr, a:request_url]))
		return
	endif
	" Represent starting current job progress
	let s:another_job_progresssive = v:true

	"-- These s: scope variables will be unlet by s:show_webpage_buffer()
	" Binding to s: scope
	let s:target_bufnr = a:target_aref_web_bufnr
	let s:request_url  = a:request_url
	" Job.start()'s result
	let s:stdout_result = ''
	" Be referenced by Job.start() and s:show_webpage_buffer()
	let s:tempname = tempname() . '.html'
	"--

	" The "on_exit" function for "curl {url} -o {s:tempname}"
	function! s:show_webpage_buffer(_, __, ___) abort
		let l:current_bufnr = winbufnr('.')
		execute 'buffer!' s:target_bufnr
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

	" It's derived vim spec
	"FIXME: Branch into Job.vim
	if has('nvim')
		let l:command = printf('curl "%s" -o %s', a:request_url, s:tempname)
	else
		let l:command = printf('curl %s -o %s', a:request_url, s:tempname)
	endif
	call Job.start(l:command, {
	\	'on_stdout' : function('s:aggregate_stdout'),
	\	'on_exit'   : function('s:show_webpage_buffer')
	\})
endfunction " }}}


"-------------------"
" autoload functions

" Open webpage buffer async
function! aref_web#open_webpage(...) abort
	let l:M = aref_web#vital_load#get('Vim.Message')

	let l:source_name = a:1
	if !aref_web#stateful#is_supported_source(l:source_name)
		call l:M.error(l:source_name . ' is not supported.')
		call l:M.error('Please verify g:loaded_aref_web')
		return
	endif
	if !aref_web#stateful#can_use_dump_cmd()
		call l:M.error('Sorry. aref_web.vim needs w3m, lynx, elinks or links browser.')
		call l:M.error('Please add it to your $PATH')
		return
	endif
	let l:request_url = aref_web#stateful#get_target_url(l:source_name, a:000[1:])
	let l:buffer_name = aref_web#stateless#get_buffer_name(l:source_name, a:000[1:])
	call s:open_webpage_buffer_async(l:buffer_name, l:request_url, a:000[1:], v:null)
endfunction


" Open current url by open-browser.vim in filetype=aref_web buffer
function! aref_web#open_browser() abort
	let l:M = aref_web#vital_load#get('Vim.Message')

	if !aref_web#stateful#have_openbrowser_vim()
		call l:M.error('calling open-browser.vim failed')
		call l:M.error('Please install and load open-browser.vim')
		return
	endif
	if &filetype !=# 'aref_web'
		call l:M.error('Invalid call situation')
		call l:M.error('Please call from filetype=aref_web buffer')
		return
	endif
	call openbrowser#open(b:aref_web_current_url)
endfunction


" Show next page
function! aref_web#show_next_page() abort
	let l:M = aref_web#vital_load#get('Vim.Message')
	let l:O = aref_web#vital_load#get('Data.Optional')

	let l:maybe_nextpage_url = aref_web#stateless#get_next_page_url(b:aref_web_current_url)
	if l:O.empty(l:maybe_nextpage_url)
		call l:M.error("Sorry, this site url doesn't support page moving")
		return
	endif

	echo 'aref_web> go to next page'
	let l:nextpage_url  = l:O.get_unsafe(l:maybe_nextpage_url)
	let l:current_bufnr = winbufnr('.')
	call s:show_webpage_buffer_async(l:current_bufnr, l:nextpage_url, v:null)
endfunction


" Show previous page
function! aref_web#show_prev_page() abort
	let l:M = aref_web#vital_load#get('Vim.Message')
	let l:O = aref_web#vital_load#get('Data.Optional')

	let l:maybe_prevpage_url = aref_web#stateless#get_prev_page_url(b:aref_web_current_url)
	if l:O.empty(l:maybe_prevpage_url)
		call l:M.error("Sorry, this site url doesn't support page moving")
		return
	endif

	echo 'aref_web> go to previous page'
	let l:prevpage_url  = l:O.get_unsafe(l:maybe_prevpage_url)
	let l:current_bufnr = winbufnr('.')
	call s:show_webpage_buffer_async(l:current_bufnr, l:prevpage_url, v:null)
endfunction
