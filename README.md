#Vim Better Whitespace Plugin

This plugin causes all trailing whitespace characters (spaces and tabs) to be
highlighted. Whitespace for the current line will not be highlighted
while in insert mode. It is possible to disable current line highlighting while in other
modes as well (see options below). A helper function `:StripWhitespace` is also provided
to make whitespace cleaning painless.

Here is a screenshot of this plugin at work:
![Example Screenshot](http://i.imgur.com/St7yHth.png)

##Installation
There are a few ways you can go about installing this plugin:

1.  If you have [Vundle](https://github.com/gmarik/Vundle.vim) you can simply add:
    ```
    Bundle 'ntpeters/vim-better-whitespace'
    ```
    to your `.vimrc` file then run:
    ```
    :BundleInstall
    ```
2.  If you are using [Pathogen](https://github.com/tpope/vim-pathogen), you can just run the following command:
    ```
    git clone git://github.com/ntpeters/vim-better-whitespace.git ~/.vim/bundle/
    ```
3.  While this plugin can also be installed by copying its contents into your `~/.vim/` directory, I would highly recommend using one of the above methods as they make managing your Vim plugins painless.

##Usage
Whitespace highlighting is enabled by default, with a highlight color of red.

*  To set a custom highlight color, just call:
    ```
    highlight ExtraWhitespace ctermbg=<desired_color>
    ```

*  To toggle whitespace highlighting on/off, call:
    ```
    :ToggleWhitespace
    ```

*  To disable highlighting for the current line in normal mode call:
    ```
    :CurrentLineWhitespaceOff <level>
    ```
    Where `<level>` is either `hard` or `soft`.

    *  The level `hard` will maintain whitespace highlighting as it is, but may
        cause a slow down in Vim since it uses the CursorMoved event to detect and
        exclude the current line.

    *  The level `soft` will use syntax based highlighting, so there shouldn't be
        a performance hit like with the `hard` option.  The drawback is that this
        highlighting will have a lower priority and may be overwritten by higher
        priority highlighting.

*  To re-enable highlighting for the current line in normal mode:
    ```
    :CurrentLineWhitespaceOn
    ```

*  To clean extra whitespace, call:
    ```
    :StripWhitespace
    ```
    By default this operates on the entire file. To restrict the portion of
    the file that it cleans, either give it a range or select a group of lines
    in visual mode and then execute it.

*  To enable/disable stripping of extra whitespace on file save, call:
    ```
    :ToggleStripWhitespaceOnSave
    ```
    This will strip all trailing whitespace everytime you save the file for all file types.
    *  If you would prefer to only stip whitespace for certain filetypes, add
        the following to your `~/.vimrc`:

        ```
        autocmd FileType <desired_filetypes> autocmd BufWritePre <buffer> StripWhitespace
        ```

        where `<desired_filetypes>` is a comma separated list of the file types you want
        to be stripped of whitespace on file save ( ie. `javascript,c,cpp,java,html,ruby` )
        Note that `<buffer>` is a keyword here denoting operation on the current buffer and
        should stay just as it appears in the line above.

*  To disable this plugin for specific file types, add the following to your `~/.vimrc`:
    ```
    let g:better_whitespace_filetypes_blacklist=['<filetype1>', '<filetype2>', '<etc>']
    ```

##Screenshots
Here are a couple more screenshots of the plugin at work.

This screenshot shows the current line not being highlighted in insert mode:
![Insert Screenthot](http://i.imgur.com/RNHR9KX.png)

This screenshot shows the current line not being highlighted in normal mode( `CurrentLineWhitespaceOff hard` ):
![Normal Screenshot](http://i.imgur.com/o888Z7b.png)

This screenshot shows that highlighting works fine for spaces, tabs, and a mixture of both:
![Tabs Screenshot](http://i.imgur.com/bbsVRUf.png)

##Frequently Asked Questions
Hopefully some of the most common questions will be answered here.  If you still have a question
that I have failed to address, please open an issue and ask it!

**Q:  Why is trailing whitespace such a big deal?**

A:  In most cases it is not a syntactical issue, but rather is a common annoyance among
    programmers.


**Q:  Why not just use `listchars` with `SpecialKey` highlighting?**

A:  I tried using `listchars` to show trail characters with `SpecialKey` highlighting applied.
    Using this method the characters would still show on the current line for me even when the
    `SpecialKey` foreground highlight matched the `CursorLine` background highlight.


**Q:  Okay, so `listchars` doesn't do exactly what you want, why not just use a `match` in your `vimrc`?**

A:  I am using `match` in this plugin, but I've also added a way to exclude the current line in
    insert mode and/or normal mode.


**Q:  If you just want to exclude the current line, why not just use syntax-based highlight rather
    than using `match` and `CursorMoved` events?**

A:  Syntax-based highlighting is an option in this plugin.  It is used to omit the current line when
    using `CurrentLineWhitespaceOff soft`. The only issue with this method is that `match` highlighing
    takes higher priorty than syntax highlighting. For example, when using a plugin such as
    [Indent Guides](https://github.com/nathanaelkane/vim-indent-guides), syntax-based highlighting of
    extra whitespace will not highlight additional white space on emtpy lines.


**Q:  I already have my own method of removing white space, why is the method used in this plugin better?**

A:  It may not be, depending on the method you are using. The method used in this plugin strips extra
    white space and then restores the cursor position and last search history.


**Q:  Most of this is pretty easy to just add to users' `vimrc` files. Why make it a plugin?**

A:  It is true that a large part of this is fairly simple to make a part of an individuals
    configuration in their `vimrc`.  I wanted to provide something that is easy to setup and use
    for both those new to Vim and others who don't want to mess around setting up this
    functionality in their `vimrc`.

**Q:  Can you add indentation highlighting for spaces/tabs? Can you add highlighting for other
    types of white space?**

A:  No, and no.  Sorry, but both are outside the scope of this plugin.  The purpose of this plugin
    is to provide a better experience for showing and dealing with extra white space.  There is
    already an amazing plugin for showing indentation in Vim called [Indent Guides](https://github.com/nathanaelkane/vim-indent-guides).
    For other types of white space highlighting, [listchars](http://vimdoc.sourceforge.net/htmldoc/options.html#'listchars') should be sufficient.

**Q:  I have a better way to do something in this plugin. OR You're doing something stupid/wrong/bad.**

A:  If you know of a better way to do something I am attempting in this plugin, or if I am doing
    something improperly/not reccomended then let me know! Please either open an issue informing
    me or make the changes yourself and open a pull request. If I am doing something that is bad
    or can be improved, I more than willing to hear about it!

##Promotion
If you like this plugin, please star it on Github and vote it up at Vim.org!

Repository exists at: http://github.com/ntpeters/vim-better-whitespace

Plugin also hosted at: http://www.vim.org/scripts/script.php?script_id=4859

##Credits
Originally inspired by: https://github.com/bronson/vim-trailing-whitespace

Based on:

http://sartak.org/2011/03/end-of-line-whitespace-in-vim.html

http://vim.wikia.com/wiki/Highlight_unwanted_spaces
