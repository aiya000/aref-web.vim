let s:ScriptLocal = vital#aref_web#import('Vim.ScriptLocal')
let s:HTTP        = vital#aref_web#import('Web.HTTP')
let s:Optional    = vital#aref_web#import('Data.Optional')

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
let s:url_has_page_num     = s:funcs.url_has_page_num
let s:get_next_page_url    = s:funcs.get_next_page_url

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
	let l:param_list1 = ['Int', '->', 'Int']
	let l:expedted1   = printf(g:aref_web_source.foo.url, 'Int+->+Int')
	let l:act1        = s:get_target_url('foo', l:param_list1)
	call s:assert.equals(l:act1, l:expedted1)

	let l:param_list2 = ['Monad', 'm', '=>', 'm', 'a', '->', '(a', '->', 'm', 'b)', '->', 'm', 'b']
	let l:expedted2   = printf(g:aref_web_source.foo.url, 'Monad+m+=>+m+a+->+(a+->+m+b)+->+m+b')
	let l:act2        = s:get_target_url('foo', l:param_list2)
	call s:assert.equals(l:act2, l:expedted2)

	let l:param_list3 = ['($$+-)']
	let l:expedted3   = printf(g:aref_web_source.foo.url, '($$%2B-)')  " Encode '+' of param
	let l:act3        = s:get_target_url('foo', l:param_list3)
	call s:assert.equals(l:act3, l:expedted3)
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

function! s:suite.url_has_page_num_test() abort
	" These url has page num
	let l:act1 = s:url_has_page_num('https://www.stackage.org/lts-6.6/hoogle?q=%28%3C%2B%2B%29&page=1')
	let l:act2 = s:url_has_page_num('http://www.bing.com/search?q=haskell&first=11')
	call s:assert.same(l:act1, v:true, 'fail of 1')
	call s:assert.same(l:act2, v:true, 'fail of 2')

	" These url has not page num
	let l:act3 = s:url_has_page_num('https://www.stackage.org/lts-6.6/hoogle?q=%28%3C%2B%2B%29')
	let l:act4 = s:url_has_page_num('http://google.co.jp')
	call s:assert.same(l:act3, v:false, 'fail of 3')
	call s:assert.same(l:act4, v:false, 'fail of 4')
endfunction

function! s:suite.get_next_page_url_test() abort
	" These result has a value
	let l:act1 = s:get_next_page_url('https://www.stackage.org/lts-6.6/hoogle?q=%28%3C%2B%2B%29&page=1')
	let l:act2 = s:get_next_page_url('http://www.bing.com/search?q=haskell&first=11')
	call s:assert.false(s:Optional.empty(l:act1))
	call s:assert.false(s:Optional.empty(l:act2))

	" These result has not a value
	let l:act3 = s:get_next_page_url('https://www.stackage.org/lts-6.6/hoogle?q=%28%3C%2B%2B%29')
	let l:act4 = s:get_next_page_url('http://google.co.jp')
	call s:assert.true(s:Optional.empty(l:act3))
	call s:assert.true(s:Optional.empty(l:act4))
endfunction
