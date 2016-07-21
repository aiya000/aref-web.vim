"
" Helper functions for loading vital modules
"

" If not exists Vital.Data.List yet, load it.
" and Return Vital.Data.List instance.
function! aref_web#vital_load#data_list() abort " {{{
	if !exists('s:List')
		let s:List = vital#aref_web#import('Data.List')
	endif
	return s:List
endfunction " }}}

" If not exists Vital.Data.String yet, load it.
" and Return Vital.Data.String instance.
function! aref_web#vital_load#data_string() abort " {{{
	if !exists('s:String')
		let s:String = vital#aref_web#import('Data.String')
	endif
	return s:String
endfunction " }}}

" If not exists Vital.Data.Optional yet, load it.
" and Return Vital.Data.Optional instance.
function! aref_web#vital_load#data_optional() abort " {{{
	if !exists('s:Optional')
		let s:Optional = vital#aref_web#import('Data.Optional')
	endif
	return s:Optional
endfunction " }}}
