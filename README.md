**Deprecated!**

Please use [vim-webpage](https://github.com/aiya000/vim-webpage) instead.

# aref-web.vim

[![Build Status](https://travis-ci.org/aiya000/aref-web.vim.svg?branch=master)](https://travis-ci.org/aiya000/aref-web.vim)
[![Powered by vital.vim](https://img.shields.io/badge/powered%20by-vital.vim-80273f.svg)](https://github.com/vim-jp/vital.vim)

aref-web.vim can open web dictionaries on the vim async.

The use scene example exists [--here--](https://youtu.be/lQ-QpPtGck4) .

![aref-web-vim_preview](./aref-web-vim_preview.gif)

## Example

- 1. Add this config to your .vimrc

```vim
let g:aref_web_source = {
\  'stackage' : {
\    'url' : 'https://www.stackage.org/lts-6.6/hoogle?q=%s&page=1'
\  }
\}
```

- 2. Execute command

```vim
:Aref stackage Int -> Int
```

- 3. https://www.stackage.org/lts-6.6/hoogle?q=Int+->+Int&page=1 will be open in buffer async

## Requirements

* Vim or NeoVim
    * Vim
        - 8.0 or later
        - +job
    * NeoVim
        - 0.1.7 or later

* CLI Command
    - `curl`
    - `w3m` or `elinks` or `links`

* Another Plugin
  - (optional) [open-browser.vim](http://github.com/tyru/open-browser.vim) (for :ArefOpenBrowser)


## Thanks

This plugin respected [ref.vim](https://github.com/thinca/vim-ref/)'s webdict.
