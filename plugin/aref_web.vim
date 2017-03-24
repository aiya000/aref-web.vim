scriptencoding utf-8

if exists('g:loaded_aref_web')
  finish
endif
let g:loaded_aref_web = 1


"-------------------"
" Variables

" Sources URL
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

" Set define default keymaps automatically if this value is v:true
let g:aref_web_enable_default_keymappings = get(g:, 'aref_web_enable_default_keymappings', v:true)

" Set open the buffer to left when new buffer is opend If this value is v:true
let g:aref_web_split_vertically = get(g:, 'aref_web_split_vertically', v:false)


"-------------------"
" Commands

" Open webpage buffer async
command! -bar -nargs=+ -complete=customlist,aref_web#complete Aref call aref_web#open_webpage(<f-args>)

" Open browser by open-browser.vim
command! -bar -complete=customlist,aref_web#complete ArefOpenBrowser call aref_web#open_browser()


"-------------------"
" Keymappings

" Open browser by open-browser.vim
nnoremap <silent> <Plug>(aref_web_open_browser_current_url) :<C-u>call aref_web#open_browser()<CR>

"nnoremap <silent> <Plug>(aref_web_open_cur_source_cword) :<C-u>call

" Show next page
nnoremap <silent> <Plug>(aref_web_show_next_page) :<C-u>call aref_web#show_next_page()<CR>

" Show previous page
nnoremap <silent> <Plug>(aref_web_show_prev_page) :<C-u>call aref_web#show_prev_page()<CR>
