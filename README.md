#Vim Whitespace Plugin

This plugin causes all trailing whitespace and tab characters to be
highlighted. Whitespace for the current line will not be highlighted
while in insert mode. It is possible to disable current line highlighting while in other
modes as well (see options below).

##Installation
There are a few ways you can go about installing this plugin:
1.  If you have [Vundle](https://github.com/gmarik/Vundle.vim) you can simply add:
    `Bundle 'ntpeters/vim-better-whitespace'`
    to your `.vimrc` file then run:
    `:BundleInstall`
2.  If you are using [Pathogen](https://github.com/tpope/vim-pathogen), you can just run the following command:
    `git clone git://github.com/ntpeters/vim-better-whitespace.git ~/.vim/bundle/`
3.  This plugin can also be installed by copying its contents into your `~/.vim/` directory.

##Usage
Whitespace highlighting is enabled by default, with a highlight color of red.

To set a custom highlight color, just call:
```
highlight ExtraWhitespace ctermbg=<desired_color>
```

To toggle whitespace highlighting on/off, call:
`:ToggleWhitespace`.

To disable highlighting for the current line in normal mode call:
`:CurrentLineWhitespaceOff <level>`
Were `<level>` is either `hard` or `soft`.

The level `hard` will maintain whitespace highlighting as it is, but may
cause a slow down in Vim since it uses the CursorMoved event to detect and
exclude the current line.

The level `soft` will use syntax based highlighting, so there shouldn't be
a performance hit like with the 'hard' option.  The drawback is that this
highlighting will have a lower priority and may be overwritten by higher
priority highlighting.

To re-enable highlighting for the current line in normal mode:
`:CurrentLineWhitespaceOn`.

To fix the whitespace errors, call:
`:FixWhitespace`
By default it operates on the entire file.
Pass a range (or use V to select some lines) to restrict the portion of the
file that gets fixed.

To enable/disable stripping of extra whitespace on file save, call:
`:ToggleFixWhitespaceOnSave`

The main repository is at http://github.com/ntpeters/vim-better-whitespace

Forked from: http://github.com/bronson/vim-trailing-whitespace
Originally based on http://vim.wikia.com/wiki/Highlight_unwanted_spaces
