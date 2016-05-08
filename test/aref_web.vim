let s:suite  = themis#suite('repl_vim')
let s:assert = themis#helper('assert')
let s:funcs  = vital#aref_web#import('Vim.ScriptLocal').sfuncs('autoload/aref_web.vim')

"-------------------"
" Functions

let s:is_supported_source = s:funcs.is_supported_source
let s:get_target_url      = s:funcs.get_target_url
let s:can_use_dump_cmd    = s:funcs.can_use_dump_cmd

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
	let l:act_valid   = s:is_supported_source(l:VALID_SOURCE_NAME)
	let l:act_invalid = s:is_supported_source(l:INVALID_SOURCE_NAME)
	call s:assert.true(l:act_valid)
	call s:assert.false(l:act_invalid)
endfunction

function! s:suite.get_target_url_test()
	" Used by is_supported_source func
	let g:aref_web_source = {
	\	'foo' : {
	\		'url' : 'http://example.com/%s'
	\	}
	\}
	let l:expedted = printf(g:aref_web_source.foo.url, 'hoge+to+ahoge')
	let l:act      = s:get_target_url('foo', ['hoge', 'to', 'ahoge'])
	call s:assert.equals(l:act, l:expedted)
endfunction

function! s:suite.can_use_dump_cmd_test()
	" Simulate when I has w3m browser
	let g:aref_web_dump_cmd = 'w3m -dump %s'
	let l:act1 = s:can_use_dump_cmd()
	call s:assert.true(l:act1)

	" Simulate when I cannnot use any cui browser
	let g:aref_web_dump_cmd = ''
	let l:act2 = s:can_use_dump_cmd()
	call s:assert.false(l:act2)
endfunction
