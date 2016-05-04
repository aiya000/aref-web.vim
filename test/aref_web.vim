let s:suite       = themis#suite('repl_vim')
let s:assert      = themis#helper('assert')
let s:ScriptLocal = vital#aref_web#import('Vim.ScriptLocal')

"-------------------"

function! s:suite.is_supported_source_test()
	let l:VALID_SOURCE_NAME   = 'valid'   | lockvar l:VALID_SOURCE_NAME
	let l:INVALID_SOURCE_NAME = 'invalid' | lockvar l:INVALID_SOURCE_NAME
	" Used by is_supported_source func
	let g:aref_web_source = {
	\	l:VALID_SOURCE_NAME : {
	\		'url' : 'http://example.com/%s'
	\	}
	\}
	let s:is_supported_source = s:ScriptLocal.sfuncs('autoload/aref_web.vim').is_supported_source
	let l:act_valid   = s:is_supported_source(l:VALID_SOURCE_NAME)
	let l:act_invalid = s:is_supported_source(l:INVALID_SOURCE_NAME)
	call s:assert.true(l:act_valid)
	call s:assert.false(l:act_invalid)
endfunction
