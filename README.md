# slimy.vim

## What is Slimy.vim?

Context for [SLIME](https://en.wikipedia.org/wiki/SLIME):

    SLIME is an Emacs plugin to turn Emacs into a Lisp IDE. You can type text
    in a file, send it to a live REPL, and avoid having to reload all your code
    every time you make a change.

slimy.vim is a humble attempt at getting _some_ of these features into Vim.
It works with any REPL and isn't tied to Lisp.

slimy.vim is a fork of [vim-slime](https://github.com/jpalardy/vim-slime) but it
greatly differ from it. This project aims at supporting only integrated terminal
from NeoVim and Vim and try to achieve a better integration of thoses features.

It will work on any NeoVim build, however Vim need to be explicitly compiled
with terminal support.

Grab some text and send it to a terminal.

Presumably, your session contains a [REPL](http://en.wikipedia.org/wiki/REPL), maybe Clojure, R or python. If you can type text into it, slimy.vim can send text to it.

The reason you're doing this? Because you want the benefits of a REPL and the benefits of using Vim (familiar environment, syntax highlighting, persistence ...).

More details in the [blog post](http://technotales.wordpress.com/2007/10/03/like-slime-for-vim/).


## Installation

I recommend installing [vim-plug](https://github.com/junegunn/vim-plug), and
then put

```
call plug#begin('~/.local/share/nvim/plugged')
Plug 'lattay/vim-slime'
call plug#end()
```

If you don't like this installation you probably know what to do.


## Usage

Put your cursor over the text you want to send and type:

    C-c, C-c       --- the same as slime

_You can just hold `Ctrl` and double-tap `c`._

The current paragraph, what would be selected if you typed `vip`, is automatically
selected. To control exactly what is sent, you can manually select text before calling vim-slime.

TODO Detailed usage

## Configuration

You do not really need to configure anything for the first try. You will be
prompted for information and slimy will save you preferences somewhere.
However you use explicit configure in your vimrc if you want.


Vim terminal configuration can be set by using the following in your .vimrc:

    let g:slimy_config = {options}



## Advanced Configuration

If you need this, you might as well refer to [the code](https://github.com/jpalardy/vim-slime/blob/master/plugin/slime.vim#L233-L245) :-)

If you don't want the default key mappings, set:

    let g:slimy_no_mappings = 1

The default mappings are:

    xmap <c-c><c-c> <Plug>SlimyRegionSend
    nmap <c-c><c-c> <Plug>SlimyParagraphSend
    nmap <c-c>v     <Plug>SlimyConfig

If you want vim-slime to bypass the prompt and use the specified default configuration options, set the `g:slime_dont_ask_default` option:

    let g:slime_dont_ask_default = 1

By default, vim-slime will try to restore your cursor position after it runs. If you don't want that behavior, unset the `g:slimy_preserve_curpos` option:

    let g:slimy_preserve_curpos = 0


## Language Support

slimy.vim _might_ have to modify its behavior according to the language or REPL
you want to use.

Many languages are supported without modifications, while [others](ftplugin)
might tweak the text without explicit configuration:

  * coffee-script
  * fsharp
  * haskell / lhaskell -- [README](ftplugin/haskell)
  * ocaml
  * python / ipython -- [README](ftplugin/python)
  * scala
  * sml
