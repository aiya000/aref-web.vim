scriptencoding utf-8

if exists('g:loaded_aref_web')
  finish
endif
let g:loaded_aref_web = 1

"-------------------"

" Source URL
"Example:
"  let g:aref_web_source = {
"  \	'weblio' : {
"  \		'url' : 'http://ejje.weblio.jp/content/%s'
"  \	},
"  \	'stackage' : {
"  \		'url' : 'https://www.stackage.org/lts-5.15/hoogle?q=%s'
"  \	}
"  \}
let g:aref_web_source = get(g:, 'aref_web_source', {})

" If this value is empty,
" Will warn by autoload/aref_web.vim's s:can_use_dump_cmd() and s:echo_error()
let g:aref_web_dump_cmd = get(g:, 'aref_web_dump_cmd',
\	  executable('w3m')    ? 'w3m -dump %s'
\	: executable('elinks') ? 'elinks -dump -no-numbering -no-references %s'
\	: executable('links')  ? 'links -dump %s'
\	: '')
"\	: executable('lynx')   ? 'lynx -dump -nonumbers %s'

" Open webpage buffer async
command! -bar -nargs=+ Aref call aref_web#open(<f-args>)

"nnoremap <silent> <Plug>(aref_web_open_cur_source_cword) :<C-u>call
