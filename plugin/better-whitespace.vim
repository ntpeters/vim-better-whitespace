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

" Set the highlight color for trailing whitespaces
call s:InitVariable('g:better_whitespace_ctermcolor', 'red')
call s:InitVariable('g:better_whitespace_guicolor', '#FF0000')

" Operator for StripWhitespace (empty to disable)
call s:InitVariable('g:better_whitespace_operator', '<leader>s')

" Set this to enable/disable whitespace highlighting
call s:InitVariable('g:better_whitespace_enabled', 1)

" Set this to match space characters that appear before or in-between tabs
call s:InitVariable('g:show_spaces_that_precede_tabs', 0)

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

" Set this to enable stripping white lines at the end of the file when we
" strip whitespace
call s:InitVariable('g:strip_whitelines_at_eof', 0)

" Set this to blacklist specific filetypes
let default_blacklist=['diff', 'gitcommit', 'unite', 'qf', 'help', 'markdown']
call s:InitVariable('g:better_whitespace_filetypes_blacklist', default_blacklist)

" Disable verbosity by default
call s:InitVariable('g:better_whitespace_verbosity', 0)

" Define custom whitespace character group to include all horizontal unicode
" whitespace characters except tab (\u0009). Vim's '\s' class only includes ASCII spaces and tabs.
let s:whitespace_chars='\u0020\u00a0\u1680\u180e\u2000-\u200b\u202f\u205f\u3000\ufeff'
let s:eol_whitespace_pattern = '[\u0009' . s:whitespace_chars . ']\+$'

call s:InitVariable('g:better_whitespace_skip_empty_lines', 0)
if g:better_whitespace_skip_empty_lines == 1
    let s:eol_whitespace_pattern = '[^\u0009' . s:whitespace_chars . ']\@1<=' . s:eol_whitespace_pattern
endif

let s:strip_whitespace_pattern = s:eol_whitespace_pattern
if g:show_spaces_that_precede_tabs == 1
    let s:eol_whitespace_pattern .= '\|[' . s:whitespace_chars . ']\+\ze[\u0009]'
endif

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
        execute 'highlight ExtraWhitespace ctermbg = '.g:better_whitespace_ctermcolor. ' guibg = '.g:better_whitespace_guicolor
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
    let b:better_whitespace_enabled = 1
    call <SID>Echo("Whitespace Highlighting: Enabled")
    call <SID>SetupAutoCommands()
endfunction

" Disable the whitespace highlighting
function! s:DisableWhitespace()
    let b:better_whitespace_enabled = 0
    call <SID>Echo("Whitespace Highlighting: Disabled")
    call <SID>SetupAutoCommands()
endfunction

" Toggle whitespace highlighting on/off
function! s:ToggleWhitespace()
    call <SID>Echo("Whitespace Highlighting: Toggling...")
    if <SID>ShouldHighlight()
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
            call s:InAllWindows('syn clear ExtraWhitespace | match ExtraWhitespace "' . s:eol_whitespace_pattern . '"')
            call <SID>Echo("Current Line Highlight Off (hard)")
        elseif a:level == 'soft'
            let g:current_line_whitespace_disabled_soft = 1
            let g:current_line_whitespace_disabled_hard = 0
            call s:InAllWindows("match ExtraWhitespace ''")
            call <SID>Echo("Current Line Highlight Off (soft)")
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
        call s:InAllWindows('syn clear ExtraWhitespace | match ExtraWhitespace "' . s:eol_whitespace_pattern . '"')
        call <SID>Echo("Current Line Highlight On")
    endif
endfunction

" Removes all extraneous whitespace in the file
function! s:StripWhitespace( line1, line2 )
    " Save the current search and cursor position
    let _s=@/
    let l = line(".")
    let c = col(".")

    " Strip the whitespace
    silent! execute ':' . a:line1 . ',' . a:line2 . 's/' . s:strip_whitespace_pattern . '//e'

    " Strip empty lines at EOF
    if g:strip_whitelines_at_eof == 1
        if &ff == 'dos'
            let nl='\r\n'
        elseif &ff == 'max'
            let nl='\r'
        else " unix
            let nl='\n'
        endif
        silent! execute '%s/\('.nl.'\)\+\%$//'
    endif

    " Restore the saved search and cursor position
    let @/=_s
    call cursor(l, c)
endfunction

" Search for trailing whitespace
function! s:GotoTrailingWhitespace(search_backwards, from, to)
    " Save the current search
    let _s=@/
    let l = line('.')
    let c = col('.')

    " Move to start of range (if we are outside of it)
    if l < a:from || l > a:to
        if a:search_backwards != 0
            call cursor(a:to, 0)
            call cursor(0, col('$'))
        else
            call cursor(a:from, 1)
        endif
    endif

    " Set options (search direction, last searched line)
    let opts = 'wz'
    let until = a:to
    if a:search_backwards != 0
        let opts .= 'b'
        let until = a:from
    endif
    " Full file, allow wrapping
    if a:from == 1 && a:to == line('$')
        let until = 0
    endif

    " Go to pattern
    let found = search(s:eol_whitespace_pattern, opts, until)

    " Restore position if there is no match (in case we moved it)
    if found == 0
        call cursor(l, c)
    endif

    " Restore the saved search
    let @/=_s
endfunction

" Strip whitespace on file save
function! s:EnableStripWhitespaceOnSave()
    let b:strip_whitespace_on_save = 1
    call <SID>Echo("Strip Whitespace On Save: Enabled")
    call <SID>SetupAutoCommands()
endfunction

" Don't strip whitespace on file save
function! s:DisableStripWhitespaceOnSave()
    let b:strip_whitespace_on_save = 0
    call <SID>Echo("Strip Whitespace On Save: Disabled")
    call <SID>SetupAutoCommands()
endfunction

" Strips whitespace on file save
function! s:ToggleStripWhitespaceOnSave()
    call <SID>Echo("Strip Whitespace On Save: Toggling...")
    if <SID>ShouldStripWhitespace()
        call <SID>DisableStripWhitespaceOnSave()
    else
        call <SID>EnableStripWhitespaceOnSave()
    endif
endfunction

" Determines if whitespace highlighting should currently be skipped
function! s:ShouldHighlight()
    call s:InitVariable('b:better_whitespace_enabled', -1)
    if b:better_whitespace_enabled < 0
        if empty(&buftype) && empty(&filetype)
            " We can't initialize buffer value properly yet, fall back to global one
            return g:better_whitespace_enabled
        else
            let b:better_whitespace_enabled = &buftype != 'nofile' &&
                        \ index(g:better_whitespace_filetypes_blacklist, &ft) == -1
        endif
    endif
    return b:better_whitespace_enabled
endfunction

function! s:ShouldStripWhitespace()
    call s:InitVariable('b:strip_whitespace_on_save', -1)
    if b:strip_whitespace_on_save < 0
        if !exists('b:better_whitespace_enabled') || b:better_whitespace_enabled < 0
            " We can't initialize buffer value properly yet, fall back to global one
            return g:strip_whitespace_on_save
        else
            let b:strip_whitespace_on_save = b:better_whitespace_enabled && g:strip_whitespace_on_save
        endif
    endif
    return b:strip_whitespace_on_save
endfunction

" Run :StripWhitespace to remove end of line whitespace
command! -range=% StripWhitespace call <SID>StripWhitespace( <line1>, <line2> )
" Run :EnableStripWhitespaceOnSave to enable whitespace stripping on save
command! EnableStripWhitespaceOnSave call <SID>EnableStripWhitespaceOnSave()
" Run :DisableStripWhitespaceOnSave to disable whitespace stripping on save
command! DisableStripWhitespaceOnSave call <SID>DisableStripWhitespaceOnSave()
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
" Search for trailing white space forwards or backwards
command! -range=% NextTrailingWhitespace call <SID>GotoTrailingWhitespace(0, <line1>, <line2>)
command! -range=% PrevTrailingWhitespace call <SID>GotoTrailingWhitespace(1, <line1>, <line2>)

if !empty(g:better_whitespace_operator)
    function! s:StripWhitespaceMotion(type)
        call <SID>StripWhitespace(line("'["), line("']"))
    endfunction

    " Ensure we only map if no identical, user-defined mapping already exists
    if (empty(mapcheck(g:better_whitespace_operator, 'x')))
        " Visual mode
        exe "xmap <silent> ".g:better_whitespace_operator." :StripWhitespace<CR>"
    else
        call <SID>Echo("Whitespace operator not mapped for visual mode. Mapping already exists.")
    endif

    " Ensure we only map if no identical, user-defined mapping already exists
    if (empty(mapcheck(g:better_whitespace_operator, 'n')))
        " Normal mode (+ space, with line count)
        exe "nmap <silent> ".g:better_whitespace_operator."<space> :<C-U>exe '.,+'.v:count' StripWhitespace'<CR>"
        " Other motions
        exe "nmap <silent> ".g:better_whitespace_operator."        :<C-U>set opfunc=<SID>StripWhitespaceMotion<CR>g@"
    else
        call <SID>Echo("Whitespace operator not mapped for normal mode. Mapping already exists.")
    endif
endif

" Process auto commands upon load, update local enabled on filetype change
autocmd FileType * call <SID>ShouldHighlight() | call <SID>SetupAutoCommands()
autocmd WinEnter,BufWinEnter * call <SID>ShouldHighlight() | call <SID>SetupAutoCommands()
autocmd ColorScheme * call <SID>WhitespaceInit()

function! s:PerformMatchHighlight(pattern)
    if <SID>ShouldHighlight()
        exe 'match ExtraWhitespace "' . a:pattern . '"'
    else
        match ExtraWhitespace ''
    endif
endfunction

function! s:PerformSyntaxHighlight(pattern)
    syn clear ExtraWhitespace
    if <SID>ShouldHighlight()
        exe 'syn match ExtraWhitespace excludenl "' . a:pattern . '"'
    endif
endfunction

function! s:HighlightEOLWhitespace(type)
    if (a:type == 'match')
        call s:PerformMatchHighlight(s:eol_whitespace_pattern)
    elseif (a:type == 'syntax')
        call s:PerformSyntaxHighlight(s:eol_whitespace_pattern)
    endif
endfunction

function! s:HighlightEOLWhitespaceExceptCurrentLine(type)
    let a:exclude_current_line_eol_whitespace_pattern = '\%<' . line(".") .  'l' . s:eol_whitespace_pattern . '\|\%>' . line(".") .  'l' . s:eol_whitespace_pattern
    if (a:type == 'match')
        call s:PerformMatchHighlight(a:exclude_current_line_eol_whitespace_pattern)
    elseif (a:type == 'syntax')
        call s:PerformSyntaxHighlight(a:exclude_current_line_eol_whitespace_pattern)
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
                call <SID>PerformMatchHighlight(s:eol_whitespace_pattern)
                " Check if current line highlighting is disabled
                if g:current_line_whitespace_disabled_hard == 1
                    " Never highlight whitespace on current line
                    autocmd InsertEnter,CursorMoved,CursorMovedI * call <SID>HighlightEOLWhitespaceExceptCurrentLine('match')
                else
                    " When in insert mode, do not highlight whitespace on the current line
                    autocmd InsertEnter,CursorMovedI * call <SID>HighlightEOLWhitespaceExceptCurrentLine('match')
                endif
                " Highlight all whitespace when exiting insert mode
                autocmd InsertLeave,BufReadPost * call <SID>HighlightEOLWhitespace('match')
                " Clear whitespace highlighting when leaving buffer
                autocmd BufWinLeave * match ExtraWhitespace ''
            else
                " Highlight extraneous whitespace at the end of lines, but not the
                " current line.
                call <SID>HighlightEOLWhitespace('syntax')
                autocmd InsertEnter * call <SID>HighlightEOLWhitespaceExceptCurrentLine('syntax')
                autocmd InsertLeave,BufReadPost * call <SID>HighlightEOLWhitespace('syntax')
            endif
        endif

        " Strip whitespace on save if enabled.
        if <SID>ShouldStripWhitespace()
            autocmd BufWritePre * call <SID>StripWhitespace( 0, line("$") )
        endif

    augroup END
endfunction
