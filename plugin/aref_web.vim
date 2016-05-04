scriptencoding utf-8

if exists('g:loaded_aref_web')
  finish
endif
let g:loaded_aref_web = 1

"-------------------"

" Source URL
let g:aref_web_source = get(g:, 'aref_web_source', {
\	'weblio' : {
\		'url' : 'http://ejje.weblio.jp/content/%s'
\	},
\	'stackage' : {
\		'url' : 'https://www.stackage.org/lts-5.15/hoogle?q=%s'
\	}
\})

" Open webpage buffer async
command! -bar -nargs=+ Aref call aref_web#open(<f-args>)
