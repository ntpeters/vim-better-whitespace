Vim Whitespace Plugin
=====================
This plugin causes all trailing whitespace and tab characters to be
highlighted in red by default. Whitespace for the current line will not be highlighted
while in insert mode. It is possible to disable current line highlighting while in other
modes as well (see options below).

To set a custom highlight color, just call:
```
highlight ExtraWhitespace ctermbg=<desired_color>
```

To toggle whitespace highlighting, call `:ToggleWhitespace`.

To disable highlighting for the current line in normal mode call
`:CurrentLineWhitespaceOff` with either `hard` or `soft` as an option.
The option `hard` will maintain whitespace highlighting as it is, but may
cause a slow down in Vim since it uses the CursorMoved event to detect and 
exclude the current line.
The option `soft` will use syntax based highlighting, so there shouldn't be
a performance hit like with the 'hard' option.  The drawback is that this
highlighting will have a lower priority and may be overwritten by higher
priority highlighting.

To re-enable highlighting for the current line in normal mode
call `:CurrentLineWhitespaceOn`.

To fix the whitespace errors, just call `:FixWhitespace`. By default it
operates on the entire file. Pass a range (or use V to select some lines)
to restrict the portion of the file that gets fixed.

To enable/disable stripping of extra whitespace on file save, call: `:ToggleFixWhitespaceOnSave`

The main repository is at http://github.com/bronson/vim-trailing-whitespace

Originally based on http://vim.wikia.com/wiki/Highlight_unwanted_spaces
