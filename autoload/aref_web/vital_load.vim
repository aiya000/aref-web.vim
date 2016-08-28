"
" Helper functions for loading vital modules
"

function! aref_web#vital_load#get(module_name) abort
	if !exists('s:V')
		" The stateful object for vital modules
		let s:V = vital#aref_web#new()
	endif

	if !exists('s:V.' . a:module_name)
		call s:V.load(a:module_name)
	endif
	return eval('s:V.' . a:module_name)
endfunction
