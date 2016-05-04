" If not exists Vital.Data.List yet, load it.
" and Return Vital.Data.List instance.
function! s:load_data_list() " {{{
	if !exists('s:List')
		let s:List = vital#aref_web#import('Data.List')
	endif
	return s:List
endfunction " }}}

" If keys(g:aref_web_source) contains a:source_name, Return true.
" otherwise Return false
function! s:is_supported_source(source_name) " {{{
	let l:supported_sources = keys(g:aref_web_source)
	return s:load_data_list().has(l:supported_sources, a:source_name)
endfunction " }}}

" warn_supporting_error supporting error
function! s:warn_supporting_error(source_name) " {{{
	echohl Error
	echo a:source_name . ' is not supported.'
	echo 'Please verify g:loaded_aref_web'
	echohl None
endfunction " }}}

function! s:load_page_async(url)
	
endfunction

"-------------------"

function! aref_web#open(...)
	let l:source_name = a:1
	if !s:is_supported_source(l:source_name)
		call s:warn_supporting_error(l:source_name)
		return
	endif
	throw 'todo: implementation'
endfunction
