"
" Test for aref_web#stateless
"

"-------------------"
" Vital modules

let s:Optional = vital#aref_web#import('Data.Optional')

"-------------------"
" Themis variables

let s:suite  = themis#suite('aref_web#stateless')
let s:assert = themis#helper('assert')

"-------------------"
" Tests

function! s:suite.url_has_page_num_test() abort
	" These url has page num
	let l:act1 = aref_web#stateless#url_has_page_num('https://www.stackage.org/lts-6.6/hoogle?q=%28%3C%2B%2B%29&page=1')
	let l:act2 = aref_web#stateless#url_has_page_num('http://www.bing.com/search?q=haskell&first=11')
	call s:assert.same(l:act1, v:true, 'fail of 1')
	call s:assert.same(l:act2, v:true, 'fail of 2')

	" These url has not page num
	let l:act3 = aref_web#stateless#url_has_page_num('https://www.stackage.org/lts-6.6/hoogle?q=%28%3C%2B%2B%29')
	let l:act4 = aref_web#stateless#url_has_page_num('http://google.co.jp')
	call s:assert.same(l:act3, v:false, 'fail of 3')
	call s:assert.same(l:act4, v:false, 'fail of 4')
endfunction

function! s:suite.get_next_page_url_test() abort
	" These result has a value
	let l:act1 = aref_web#stateless#get_next_page_url('https://www.stackage.org/lts-6.6/hoogle?q=%28%3C%2B%2B%29&page=1')
	let l:act2 = aref_web#stateless#get_next_page_url('http://www.bing.com/search?q=haskell&first=11')
	call s:assert.false(s:Optional.empty(l:act1))
	call s:assert.false(s:Optional.empty(l:act2))
	call s:assert.equals(
	\	s:Optional.get_unsafe(l:act1),
	\	'https://www.stackage.org/lts-6.6/hoogle?q=%28%3C%2B%2B%29&page=2')
	call s:assert.equals(
	\	s:Optional.get_unsafe(l:act2),
	\	'http://www.bing.com/search?q=haskell&first=12')

	" These result has not a value
	let l:act3 = aref_web#stateless#get_next_page_url('https://www.stackage.org/lts-6.6/hoogle?q=%28%3C%2B%2B%29')
	let l:act4 = aref_web#stateless#get_next_page_url('http://google.co.jp')
	call s:assert.true(s:Optional.empty(l:act3))
	call s:assert.true(s:Optional.empty(l:act4))
endfunction
