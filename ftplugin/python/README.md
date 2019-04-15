### Python

Sending code to an interactive Python session is tricky business due to
Python's indentation-sensitive nature. Perfectly valid code which executes when
run from a file may fail with a `SyntaxError` when pasted into the CPython
interpreter.

[IPython](http://ipython.org/) has a `%cpaste` "magic function" that allows for
error-free pasting. In order for slimy to make use of this feature for
Python buffers, you need to set the corresponding variable in your vimrc:

    let g:slimy_python_ipython = 1

Note: if you're using IPython 5, you _need_ to set `g:slimy_python_ipython` for
pasting to work correctly.

