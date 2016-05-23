" Author: Nate Peterson
" Repository: https://github.com/ntpeters/vim-better-whitespace

" Prevent loading the plugin multiple times
if exists('g:loaded_better_whitespace_plugin')
    finish
endif
let g:loaded_better_whitespace_plugin = 1

" Initializes a given variable to a given value. The variable is only
" initialized if it does not exist prior.
function! s:InitVariable(var, value)
    if !exists(a:var)
      execute 'let ' . a:var . ' = ' . string(a:value)
    endif
endfunction

" Set this to enable/disable whitespace highlighting
call s:InitVariable('g:better_whitespace_enabled', 1)

" Set this to disable highlighting on the current line in all modes
" WARNING: This checks for current line on cursor move, which can significantly
"          impact the performance of Vim (especially on large files)
call s:InitVariable('g:current_line_whitespace_disabled_hard', 0)

" Set this to disable highlighting of the current line in all modes
" This setting will not have the performance impact of the above, but
" highlighting throughout the file may be overridden by other highlight
" patterns with higher priority.
call s:InitVariable('g:current_line_whitespace_disabled_soft', 0)

" Set this to enable stripping whitespace on file save
call s:InitVariable('g:strip_whitespace_on_save', 0)

" Set this to blacklist specific filetypes
let default_blacklist=['diff', 'gitcommit', 'unite', 'qf', 'help']
call s:InitVariable('g:better_whitespace_filetypes_blacklist', default_blacklist)

" Disable verbosity by default
call s:InitVariable('g:better_whitespace_verbosity', 0)

" Only init once
let s:better_whitespace_initialized = 0

" Like windo but restore the current window.
function! s:Windo(command)
    let currwin=winnr()
    execute 'windo ' . a:command
    execute currwin . 'wincmd w'
endfunction

" Like tabdo but restore the current tab.
function! s:Tabdo(command)
    let currTab=tabpagenr()
    execute 'tabdo ' . a:command
    execute 'tabn ' . currTab
endfunction

" Execute command in all windows (across tabs).
function! s:InAllWindows(command)
    call s:Tabdo("call s:Windo('".substitute(a:command, "'", "''", 'g')."')")
endfunction

" Ensure the 'ExtraWhitespace' highlight group has been defined
function! s:WhitespaceInit()
    " Check if the user has already defined highlighting for this group
    if hlexists("ExtraWhitespace") == 0 || synIDattr(synIDtrans(hlID("ExtraWhitespace")), "bg") == -1
        highlight ExtraWhitespace ctermbg = red guibg = #FF0000
    endif
    let s:better_whitespace_initialized = 1
endfunction

" Like 'echo', but only outputs the message when verbosity is enabled
function! s:Echo(message)
    if g:better_whitespace_verbosity == 1
        echo a:message
    endif
endfunction

" Enable the whitespace highlighting
function! s:EnableWhitespace()
    if b:better_whitespace_enabled == 0
        let b:better_whitespace_enabled = 1
        call <SID>WhitespaceInit()
        call <SID>SetupAutoCommands()
        call <SID>Echo("Whitespace Highlighting: Enabled")
    endif
endfunction

" Disable the whitespace highlighting
function! s:DisableWhitespace()
    if b:better_whitespace_enabled == 1
        let b:better_whitespace_enabled = 0
        call <SID>SetupAutoCommands()
        call <SID>Echo("Whitespace Highlighting: Disabled")
    endif
endfunction

" Toggle whitespace highlighting on/off
function! s:ToggleWhitespace()
    if b:better_whitespace_enabled == 1
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
            call s:InAllWindows('syn clear ExtraWhitespace | match ExtraWhitespace /\s\+$/')
            call <SID>Echo("Current Line Hightlight Off (hard)")
        elseif a:level == 'soft'
            let g:current_line_whitespace_disabled_soft = 1
            let g:current_line_whitespace_disabled_hard = 0
            call s:InAllWindows("match ExtraWhitespace ''")
            call <SID>Echo("Current Line Hightlight Off (soft)")
        endif
        " Re-run auto commands with the new settings
        call <SID>SetupAutoCommands()
    endif
endfunction

" Enables whitespace highlighting for the current line
function! s:CurrentLineWhitespaceOn()
    if g:better_whitespace_enabled == 1
        let g:current_line_whitespace_disabled_hard = 0
        let g:current_line_whitespace_disabled_soft = 0
        call <SID>SetupAutoCommands()
        call s:InAllWindows('syn clear ExtraWhitespace | match ExtraWhitespace /\s\+$/')
        call <SID>Echo("Current Line Hightlight On")
    endif
endfunction

" Removes all extraneous whitespace in the file
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
        call <SID>Echo("Strip Whitespace On Save: Enabled")
    else
        let g:strip_whitespace_on_save = 0
        call <SID>Echo("Strip Whitespace On Save: Disabled")
    endif
    call <SID>SetupAutoCommands()
endfunction

" Determines if whitespace highlighting should currently be skipped
function! s:ShouldSkipHighlight()
    return &buftype == 'nofile' || index(g:better_whitespace_filetypes_blacklist, &ft) >= 0
endfunction

" Run :StripWhitespace to remove end of line whitespace
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

" Process auto commands upon load, update local enabled on filetype change
autocmd FileType * let b:better_whitespace_enabled = !<SID>ShouldSkipHighlight() | call <SID>SetupAutoCommands()
autocmd WinEnter,BufWinEnter * call <SID>SetupAutoCommands()
autocmd ColorScheme * call <SID>WhitespaceInit()

function! s:PerformMatchHighlight(pattern)
    call s:InitVariable('b:better_whitespace_enabled', !<SID>ShouldSkipHighlight())
    if b:better_whitespace_enabled == 1
        exe 'match ExtraWhitespace ' . a:pattern
    else
        match ExtraWhitespace ''
    endif
endfunction

function! s:PerformSyntaxHighlight(pattern)
    syn clear ExtraWhitespace
    call s:InitVariable('b:better_whitespace_enabled', !<SID>ShouldSkipHighlight())
    if b:better_whitespace_enabled == 1
        exe 'syn match ExtraWhitespace excludenl ' . a:pattern
    endif
endfunction

" Executes all auto commands
function! <SID>SetupAutoCommands()
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
                call <SID>PerformMatchHighlight('/\s\+$/')
                " Check if current line highglighting is disabled
                if g:current_line_whitespace_disabled_hard == 1
                    " Never highlight whitespace on current line
                    autocmd InsertEnter,CursorMoved,CursorMovedI * call <SID>PerformMatchHighlight('/\%<' . line(".") .  'l\s\+$\|\%>' . line(".") .  'l\s\+$/')
                else
                    " When in insert mode, do not highlight whitespace on the current line
                    autocmd InsertEnter,CursorMovedI * call <SID>PerformMatchHighlight('/\%<' . line(".") .  'l\s\+$\|\%>' . line(".") .  'l\s\+$/')
                endif
                " Highlight all whitespace when exiting insert mode
                autocmd InsertLeave,BufReadPost * call <SID>PerformMatchHighlight('/\s\+$/')
                " Clear whitespace highlighting when leaving buffer
                autocmd BufWinLeave * match ExtraWhitespace ''
            else
                " Highlight extraneous whitespace at the end of lines, but not the
                " current line.
                call <SID>PerformSyntaxHighlight('/\s\+$/')
                autocmd InsertEnter * call <SID>PerformSyntaxHighlight('/\s\+\%#\@!$/')
                autocmd InsertLeave,BufReadPost * call <SID>PerformSyntaxHighlight('/\s\+$/')
            endif
        endif

        " Strip whitespace on save if enabled
        if g:strip_whitespace_on_save == 1
            autocmd BufWritePre * call <SID>StripWhitespace( 0, line("$") )
        endif

    augroup END
endfunction

