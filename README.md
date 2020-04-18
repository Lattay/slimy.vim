# slimy.vim

## What slimy.vim

Context for [SLIME](https://en.wikipedia.org/wiki/SLIME):

```
SLIME is an Emacs plugin to turn Emacs into a Lisp IDE.
You can type text in a file, send it to a live REPL, and 
avoid having to reload all your code every time you make
a change.
```

slimy.vim is a attempt at getting _some_ of these features into built-in
terminals of Vim and NeoVim. It works with any REPL and isn't tied to Lisp.

slimy.vim works on any NeoVim build, and on all Vim 8.x with terminal support enabled.

If you use a [REPL](http://en.wikipedia.org/wiki/REPL), maybe Clojure, R or
python, you may find this package useful.  As long as you can type text into
your target program, slimy can use it.  You just have to open your file with
vim, go to the code you want to send to your REPL and hit `CTRL-C CTRL-C`.
slimy.vim will prompt you for a command for the REPL if it is not opened yet
of try to guess what buffer is your REPL (and ask for confirmation).

## What slimy.vim is not

slimy.vim started its life as a fork of
[vim-slime](https://github.com/jpalardy/vim-slime).  However it greatly
diverged, first by dropping all features unrelated to Vim/Neovim builtin
terminal and the by adding features for a bettter integration with those.
Indeed vim-slime aims at supporting all sorts of targets like termux or screen
whereas this project aims at supporting only built-in terminals from NeoVim and
Vim and try to achieve a best experience possible in this restricted frame.

If you are interested in having this kind of features with anything that is not
Vim/Neovim builtin terminal, use
[vim-slime](https://github.com/jpalardy/vim-slime).  slimy.vim will never try
to support those external targets.

## Installation

I recommend installing [vim-plug](https://github.com/junegunn/vim-plug), and
then put

```
call plug#begin('~/.local/share/nvim/plugged')
Plug 'lattay/vim-slime'
call plug#end()
```

If you don't like this installation method you probably know what to do.

## Usage

Put your cursor over the text you want to send and type `<C-c><C-c>`.  It
is the same binding as SLIME but you can change it if you like.

Alternatively select text with visual mode and hit `<C-c><C-c>` to send
selection to REPL.

The current paragraph (what would be selected if you typed `vip`) is
automatically selected. To control exactly what is sent, you can manually
select text before calling vim-slime. I plan on implementing a smarter
default selection than paragraph that would depend on the language syntax.

You can also add the selection that make sense for you easily with
available mapping.

## Functions

Public functions are the following :

* `slimy#config()` reconfigure slimy
* `slimy#send_op(type, ...)` send the text covered by the last movement,
    type is the mode of edition
* `slimy#send_range(startline, endline)` send a range of line
* `slimy#send_lines(count)` send `count` lines starting from the cursor
* `slimy#send(text)` send an arbitrary string. If needed it will be
    modified to comply with the REPL expectation (see below).

## Commands

* `:SlimyConfig` reconfigure, ask for a REPL command and open a terminal (if
  needed)
* `:[range]SlimySend` send a range of lines to the REPL, the default range is
  the whole file
* `:[count]SlimySendLines [count]` send <count> lines starting from the cursor.
  The default count is one.

## Mapping

There are two mapping by default:

* <C-c><C-c> to send a paragraph or a selection to the REPL
* <C-c>v to reconfigure slimy

If you want to override the mappings (for example to use `!!` and `!c`) put
the following in your vimrc 
``` 
nmap !! <Plug>(slimy_send_paragraph)
xmap !! <Plug>(slimy_send_region)
nmap !c <Plug>(slimy_config)
```

Available `<plug>` mapping are:
* `<Plug>(slimy_send_region)` send the visual selection, use it with `vmap`,
  `xmap` and friends
* `<Plug>(slimy_send_line)` send the line under the cursor
* `<Plug>(slimy_send_motion)` wait for a motion or operator and send the
  corresponding content to the REPL. Use this to implement smarter selection.
  This is obviously the most powerfull of all mappings. For example you can do
  things like that:
```
" The following will send the whole file to the REPL
nnoremap <C-c>gg gg<Plug>(slimy_send_motion)G
" For Lisp and Scheme, the following will select the S-expr
" that contain the cursor and send it to the REPL
nnoremap <C-c><C-c> <Plug>(slimy_send_motion)a)
```
* `<Plug>(slimy_send_paragraph)` send the current paragraph
* `<Plug>slimy_config` reconfigure slimy

## Options

You can configure slimy with a default behaviour and specific behaviour for each
file type. For example:

```
let g:slimy_config = {
\    '*': {
\         'cmd': 'bash'
\    },
\    'python': {
\         'cmd': 'python3', 
\         'confirm': 0
\    },
\    'lua': {
\         'cmd': 'luajit'
\    }
\}
```

Any filetype can be used as a key. `'*'` is the "default filetype" used when
the current filetype is not found in `g:slimy_config`.

You can override this configuration per buffer with the following:
```
let b:slimy_config {'cmd': 'python2.7', 'confirm': 0}
```

Currently supported options are:
* `'cmd'` the command to be run in a new terminal
* `'confirm'` whether you want to be prompted (`1` the default) or not (`0`)  
* `'bufnr'` the id of the buffer of the terminal. Does not make sense in the
  global config but is present in the buffer wide config.

If you want to customize the way the new terminal is created you can use
```
let g:slimy_terminal_config = {...}
```

Available options are all the options of `term_open` in Vim (see `:help
term_open()`) and (for now) only `'vertical'` for NeoVim. Use the following to
open the terminal vertically by default.

```
let g:slimy_terminal_config = {'vertical': 1} 
```

Default mappings are not performed if they have been overridden already.
However if you want to disable them anyway you can add this to your config:
```
let g:slimy_no_mappings = 1
```

## Language Support

Most of the time slimy.vim work out of the box with the REPL of your choice.
However sometimes some tweaking might be necessary to address a particular
behaviour of a REPL.

Many languages are supported without modifications, while [others](ftplugin)
might tweak the text without explicit configuration:

* coffee-script
* fsharp
* haskell / lhaskell -- [README](ftplugin/haskell)
* ocaml
* python / ipython -- [README](ftplugin/python)
* scala
* sml

If you happen to find an interpreter that does not work out of the box, do not
hesitate to create an issue so I can solve the problem (or even better, submit
a pull request that solve the problem).

## Bugs, feature requests, contribution

I believe in open-source philosophy and that is why this is published under the
MIT permissive license.  As a consequence, if you think you are able to improve
slimy.vim in any way, feel free to tell me through issues, pull requests or by
mail.
