# slimy.vim

## What is Slimy.vim?

Context for [SLIME](https://en.wikipedia.org/wiki/SLIME):

```
SLIME is an Emacs plugin to turn Emacs into a Lisp IDE.
You can type text in a file, send it to a live REPL, and 
avoid having to reload all your code every time you make
a change.
```

slimy.vim is a attempt at getting _some_ of these features into built-in
terminals of Vim and NeoVim. It works with any REPL and isn't tied to Lisp.

slimy.vim is a fork of [vim-slime](https://github.com/jpalardy/vim-slime) but
it greatly differ from it. This project aims at supporting only built-in
terminals from NeoVim and Vim and try to achieve a better integration of theses
features with a more intuitive and homogenous interface.

It work on any NeoVim build, and on all Vim 8.x with terminal support enabled.

If you use a [REPL](http://en.wikipedia.org/wiki/REPL), maybe Clojure, R or
python, you may find this package useful.  As long as you can type text into
your target program, slimy can use it.  You just have to open your file with
vim, go to the code you want to send to your REPL and hit `CTRL-C CTRL-C`.
slimy.vim will prompt you for a command for the REPL if it is not opened yet
of try to guess what buffer is your REPL (and ask for confirmation).

The reason you're doing this? Because you want the benefits of a REPL and the
benefits of using Vim (familiar environment, syntax highlighting, persistence
...).

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

Put your cursor over the text you want to send and type `<C-c><C-c>`.  It
is the same binding as SLIME but you can change it if you like.

The current paragraph (what would be selected if you typed `vip`) is
automatically selected. To control exactly what is sent, you can manually
select text before calling vim-slime. I plan on implementing a smarter
default selection than paragraph that would depend on the language syntax.

You can also add the selection that make sense for you easily with
available mapping.

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

There are thwo other mapping defined but not bound by default:
* `<Plug>(slimy_send_line)` send the line under the cursor
* `<Plug>(slimy_send_motion)` wait for a motion or operator and send the
    corresponding content to the REPL. Use this to implement smarter
    selection.

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

Any filetype can be used as a key. `'*'` is the "default filetype" used when the
current filetype is not found in `g:slimy_config`.

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

Available options are all the options of `term_open` in Vim (see `:help term_open()`)
and (for now) only `'vertical'` for NeoVim. Use the following to 
open the terminal vertically by default.

```
let g:slimy_terminal_config = {'vertical': 1} 
```

If you want to disable automatic mappings (they are not done if you
override them) you can use 
```
let g:slimy_no_mappings = 1
```

## Functions

Public functions are the following :

* `slimy#config()` reconfigure slimy
* `slimy#send_op(type, ...)` send the text covered by the last movement,
    type is the mode of edition
* `slimy#send_range(startline, endline)` send a range of line
* `slimy#send_lines(count)` send `count` lines starting from the cursor
* `slimy#send(text)` send an arbitrary string string. If needed it will be
    modified to comply with the REPL expectation (see below).

## Language Support

Most of the time slimy.vim work out of the box with the REPL of your
choice.  However sometimes some tweaking might be necessary to address a
particular behaviour of a REPL.

Many languages are supported without modifications, while [others](ftplugin)
might tweak the text without explicit configuration:

* coffee-script
* fsharp
* haskell / lhaskell -- [README](ftplugin/haskell)
* ocaml
* python / ipython -- [README](ftplugin/python)
* scala
* sml

If you happen to find an interpreter that does not work out of the box, do
not hesitate to create an issue so I can solve the problem (or even better,
submit a pull request that solve the problem).
