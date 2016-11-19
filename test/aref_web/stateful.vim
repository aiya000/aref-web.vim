"
" Test for aref_web#stateful
"

"-------------------"
" Vital modules

let s:HTTP = vital#aref_web#import('Web.HTTP')

"-------------------"
" Themis variables

let s:suite  = themis#suite('aref_web#stateful')
let s:assert = themis#helper('assert')

"-------------------"
" Tests

function! s:suite.is_supported_source_test() abort
	let l:VALID_SOURCE_NAME   = 'valid'   | lockvar l:VALID_SOURCE_NAME
	let l:INVALID_SOURCE_NAME = 'invalid' | lockvar l:INVALID_SOURCE_NAME
	" Used by is_supported_source func
	let g:aref_web_source = {
	\	l:VALID_SOURCE_NAME : {
	\		'url' : 'http://example.com/%s'
	\	}
	\}
	let l:act_valid   = aref_web#stateful#is_supported_source(l:VALID_SOURCE_NAME)
	let l:act_invalid = aref_web#stateful#is_supported_source(l:INVALID_SOURCE_NAME)
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

	" Simply
	let l:param_list1 = ['throwM']
	let l:expedted1   = printf(g:aref_web_source.foo.url, 'throwM')
	let l:act1        = aref_web#stateful#get_target_url('foo', l:param_list1)
	call s:assert.equals(l:act1, l:expedted1)

	" It contains the spaces.
	" The words should be catenated with '+'
	let l:param_list2 = split('aho baka unko', ' ')
	let l:expedted2   = printf(g:aref_web_source.foo.url, join(l:param_list2, '+'))
	let l:act2        = aref_web#stateful#get_target_url('foo', l:param_list2)
	call s:assert.equals(l:act2, l:expedted2)

	" All mark characters should be encoded
	let l:param_list3 = ['($$+-)']
	let l:expedted3   = printf(g:aref_web_source.foo.url, s:HTTP.encodeURI('($$+-)'))
	let l:act3        = aref_web#stateful#get_target_url('foo', l:param_list3)
	call s:assert.equals(l:act3, l:expedted3)
endfunction

function! s:suite.can_use_dump_cmd_test() abort
	" Simulate when I has w3m browser
	let g:aref_web_dump_cmd = 'w3m -dump %s'
	let l:act1 = aref_web#stateful#can_use_dump_cmd()
	call s:assert.true(l:act1)

	" Simulate when I cannnot use any cui browser
	let g:aref_web_dump_cmd = ''
	let l:act2 = aref_web#stateful#can_use_dump_cmd()
	call s:assert.false(l:act2)
endfunction

function! s:suite.have_openbrowser_vim_test() abort
	" I have not open-browser.vim
	let l:act1 = aref_web#stateful#have_openbrowser_vim()
	call s:assert.same(l:act1, v:false)

	" I have open-browser.vim
	try
		call LoadOpenBrowserToRTP()
	catch /^AHOGEHOGE/
		call s:assert.fail('open-browser.vim is not found, Please check test environment')
	endtry
	"----------"
	let l:act2 = aref_web#stateful#have_openbrowser_vim()
	call s:assert.same(l:act2, v:true)
	"----------"
	" Turn off after effect
	try
		call UnloadOpenBrowserToRTP()
	catch /^AHOGEHOGE/
		call s:assert.fail('fatal exception, Please check test logic')
	endtry
endfunction
