" Author: Nate Peterson
" Repository: https://github.com/ntpeters/vim-better-whitespace

" Prevent loading the plugin multiple times
if exists( "g:loaded_better_whitespace_plugin" )
    finish
else
    let g:loaded_better_whitespace_plugin = 1
endif

" Set this to enable/disable whitespace highlighting
let g:better_whitespace_enabled = 1

" Set this to disable highlighting on the current line in all modes
" WARNING: This checks for current line on cursor move, which can significantly
"          impact the performance of Vim (especially on large files)
let g:current_line_whitespace_disabled_hard = 0

" Set this to disable highlighting of the current line in all modes
" This setting will not have the performance impact of the above, but
" highlighting throughout the file may be overridden by other highlight
" patterns with higher priority.
let g:current_line_whitespace_disabled_soft = 0

" Set this to enable stripping whitespace on file save
let g:strip_whitespace_on_save = 0

" Only init once
let s:better_whitespace_initialized = 0

" Ensure the 'ExtraWhitespace' highlight group has been defined
function! s:WhitespaceInit()
    " Check if the user has already defined highlighting for this group
    if hlexists("ExtraWhitespace") == 0
        highlight ExtraWhitespace ctermbg = red
    endif
    let g:better_whitespace_initialized = 1
endfunction

" Enable the whitespace highlighting
function! s:EnableWhitespace()
    if g:better_whitespace_enabled == 0
        let g:better_whitespace_enabled = 1
        call <SID>WhitespaceInit()
        " Match default whitespace
        match ExtraWhitespace /\s\+$/
        call <SID>RunAutoCommands()
    endif
endfunction

" Disable the whitespace highlighting
function! s:DisableWhitespace()
    if g:better_whitespace_enabled == 1
        let g:better_whitespace_enabled = 0
        " Clear current whitespace matches
        match ExtraWhitespace ''
        syn clear ExtraWhitespace
        call <SID>RunAutoCommands()
    endif
endfunction

" Toggle whitespace highlighting on/off
function! s:ToggleWhitespace()
    if g:better_whitespace_enabled == 1
        call <SID>DisableWhitespace()
    else
        call <SID>EnableWhitespace()
    endif
endfunction

" This disabled whitespace highlighting on the current line in all modes
" Options:
" hard - Disables highlighting for current line and maintains high priority
"        highlighting for the entire file. Caution: may cause slowdown in Vim!
" soft - No potential slowdown as with 'hard' option, but other highlighting
"        rules of higher priority may overwrite these whitespace highlights.
function! s:CurrentLineWhitespaceOff( level )
    if g:better_whitespace_enabled == 1
        " Set current line whitespace level
        if a:level == 'hard'
            let g:current_line_whitespace_disabled_hard = 1
            let g:current_line_whitespace_disabled_soft = 0
            syn clear ExtraWhitespace
            match ExtraWhitespace /\s\+$/
        elseif a:level == 'soft'
            let g:current_line_whitespace_disabled_soft = 1
            let g:current_line_whitespace_disabled_hard = 0
            match ExtraWhitespace ''
        endif
        " Re-run auto commands with the new settings
        call <SID>RunAutoCommands()
    endif
endfunction

" Enables whitespace highlighting for the current line
function! s:CurrentLineWhitespaceOn()
    if g:better_whitespace_enabled == 1
        let g:current_line_whitespace_disabled_hard = 0
        let g:current_line_whitespace_disabled_soft = 0
        call <SID>RunAutoCommands()
        syn clear ExtraWhitespace
        match ExtraWhitespace /\s\+$/
    endif
endfunction

" Removes all extaneous whitespace in the file
function! s:StripWhitespace( line1, line2 )
    " Save the current search and cursor position
    let _s=@/
    let l = line(".")
    let c = col(".")

    " Strip the whitespace
    silent! execute ':' . a:line1 . ',' . a:line2 . 's/\s\+$//e'

    " Restore the saved search and cursor position
    let @/=_s
    call cursor(l, c)
endfunction

" Strips whitespace on file save
function! s:ToggleStripWhitespaceOnSave()
    if g:strip_whitespace_on_save == 0
        let g:strip_whitespace_on_save = 1
    else
        let g:strip_whitespace_on_save = 0
    endif
    call <SID>RunAutoCommands()
endfunction

" Run :StripWhitespace to remove end of line white space
command! -range=% StripWhitespace call <SID>StripWhitespace( <line1>, <line2> )
" Run :ToggleStripWhitespaceOnSave to enable/disable whitespace stripping on save
command! ToggleStripWhitespaceOnSave call <SID>ToggleStripWhitespaceOnSave()
" Run :EnableWhitespace to enable whitespace highlighting
command! EnableWhitespace call <SID>EnableWhitespace()
" Run :DisableWhitespace to disable whitespace highlighting
command! DisableWhitespace call <SID>DisableWhitespace()
" Run :ToggleWhitespace to toggle whitespace highlighting on/off
command! ToggleWhitespace call <SID>ToggleWhitespace()
" Run :CurrentLineWhitespaceOff(level) to disable highlighting for the current
" line. Levels are: 'hard' and 'soft'
command! -nargs=* CurrentLineWhitespaceOff call <SID>CurrentLineWhitespaceOff( <f-args> )
" Run :CurrentLineWhitespaceOn to turn on whitespace for the current line
command! CurrentLineWhitespaceOn call <SID>CurrentLineWhitespaceOn()

" Process auto commands upon load
autocmd VimEnter,WinEnter,BufEnter,FileType * call <SID>RunAutoCommands()

" Executes all auto commands
function! <SID>RunAutoCommands()
    " Auto commands group
    augroup better_whitespace
        autocmd!

        if g:better_whitespace_enabled == 1
            if s:better_whitespace_initialized == 0
                call <SID>WhitespaceInit()
            endif

            " Check if current line is disabled softly
            if g:current_line_whitespace_disabled_soft == 0
                " Highlight all whitespace upon entering buffer
                autocmd BufWinEnter * match ExtraWhitespace /\s\+$/
                " Check if current line highglighting is disabled
                if g:current_line_whitespace_disabled_hard == 1
                    " Never highlight whitespace on current line
                    autocmd InsertEnter,CursorMoved,CursorMovedI * exe 'match ExtraWhitespace ' . '/\%<' . line(".") .  'l\s\+$\|\%>' . line(".") .  'l\s\+$/'
                else
                    " When in insert mode, do not highlight whitespae on the current line
                    autocmd InsertEnter,CursorMovedI * exe 'match ExtraWhitespace ' . '/\%<' . line(".") .  'l\s\+$\|\%>' . line(".") .  'l\s\+$/'
                endif
                " Highlight all whitespace when exiting insert mode
                autocmd InsertLeave,BufReadPost * match ExtraWhitespace /\s\+$/
                " Clear whitespace highlighting when leaving buffer
                autocmd BufWinLeave * call clearmatches()
            else
                " Highlight extraneous whitespace at the end of lines, but not the
                " current line
                syn clear ExtraWhitespace | syn match ExtraWhitespace excludenl /\s\+$/
                autocmd InsertEnter * syn clear ExtraWhitespace | syn match ExtraWhitespace excludenl /\s\+\%#\@!$/ containedin=ALL
                autocmd InsertLeave,BufReadPost * syn clear ExtraWhitespace | syn match ExtraWhitespace excludenl /\s\+$/ containedin=ALL
            endif
        endif

        " Strip whitespace on save if enabled
        if g:strip_whitespace_on_save == 1
            autocmd BufWritePre * call <SID>StripWhitespace( 0, line("$") )
        endif

    augroup END
endfunction
