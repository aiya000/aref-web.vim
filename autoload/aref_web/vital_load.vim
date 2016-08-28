"
" Helper functions for loading vital modules
"

" The stateful object for vital modules
let s:V = vital#aref_web#new()

" If not exists Vital.Data.List yet, load it.
" and Return Vital.Data.List instance.
function! aref_web#vital_load#data_list() abort " {{{
	if !exists('s:V.Data.List')
		call s:V.load('Data.List')
	endif
	return s:V.Data.List
endfunction " }}}

" If not exists Vital.Data.String yet, load it.
" and Return Vital.Data.String instance.
function! aref_web#vital_load#data_string() abort " {{{
	if !exists('s:V.Data.String')
		call s:V.load('Data.String')
	endif
	return s:V.Data.String
endfunction " }}}

" If not exists Vital.Data.Optional yet, load it.
" and Return Vital.Data.Optional instance.
function! aref_web#vital_load#data_optional() abort " {{{
	if !exists('s:V.Data.Optional')
		call s:V.load('Data.Optional')
	endif
	return s:V.Data.Optional
endfunction " }}}

" If not exists Vim.Message yet, load it.
" and Return Vim.Message instance.
function! aref_web#vital_load#vim_message() abort " {{{
	if !exists('s:V.Vim.Message')
		call s:V.load('Vim.Message')
	endif
	return s:V.Vim.Message
endfunction " }}}
