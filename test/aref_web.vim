let s:ScriptLocal = vital#aref_web#import('Vim.ScriptLocal')
let s:HTTP        = vital#aref_web#import('Web.HTTP')

"-------------------"

let s:suite  = themis#suite('aref-web.vim')
let s:assert = themis#helper('assert')
let s:funcs  = s:ScriptLocal.sfuncs('autoload/aref_web.vim')

"-------------------"
" Functions

let s:is_supported_source  = s:funcs.is_supported_source
let s:get_target_url       = s:funcs.get_target_url
let s:can_use_dump_cmd     = s:funcs.can_use_dump_cmd
let s:have_openbrowser_vim = s:funcs.have_openbrowser_vim

"-------------------"

function! s:suite.is_supported_source_test() abort
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

function! s:suite.get_target_url_test() abort
	" Used by is_supported_source func
	let g:aref_web_source = {
	\	'foo' : {
	\		'url' : 'http://example.com/%s'
	\	}
	\}
	let l:encoded_params = s:HTTP.encodeURI('hoge+to+ahoge')
	let l:expedted = printf(g:aref_web_source.foo.url, l:encoded_params)
	let l:act      = s:get_target_url('foo', ['hoge', 'to', 'ahoge'])
	call s:assert.equals(l:act, l:expedted)
endfunction

function! s:suite.can_use_dump_cmd_test() abort
	" Simulate when I has w3m browser
	let g:aref_web_dump_cmd = 'w3m -dump %s'
	let l:act1 = s:can_use_dump_cmd()
	call s:assert.true(l:act1)

	" Simulate when I cannnot use any cui browser
	let g:aref_web_dump_cmd = ''
	let l:act2 = s:can_use_dump_cmd()
	call s:assert.false(l:act2)
endfunction

function! s:suite.have_openbrowser_vim_test() abort
	" I have not open-browser.vim
	let l:act1 = s:have_openbrowser_vim()
	"call s:assert.false(l:act1)
	call s:assert.same(l:act1, v:false)

	" I have open-browser.vim
	try
		call LoadOpenBrowserToRTP()
	catch /^AHOGEHOGE/
		call s:assert.fail('open-browser.vim is not found, Please check test environment')
	endtry
	"----------"
	let l:act2 = s:have_openbrowser_vim()
	"call s:assert.true(l:act2)
	call s:assert.same(l:act2, v:true)
	"----------"
	" Turn off after effect
	try
		call UnloadOpenBrowserToRTP()
	catch /^AHOGEHOGE/
		call s:assert.fail('fatal exception, Please check test logic')
	endtry
endfunction
