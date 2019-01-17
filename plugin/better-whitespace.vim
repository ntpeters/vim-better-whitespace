" Author: Nate Peterson
" Repository: https://github.com/ntpeters/vim-better-whitespace

" Prevent loading the plugin multiple times
if exists('g:loaded_better_whitespace_plugin')
    finish
endif
let g:loaded_better_whitespace_plugin = 1


" Section: Preferences

" Initializes a given global variable to a given value, if it does not yet exist.
function! s:InitVariable(var, value)
    let g:[a:var] = get(g:, a:var, a:value)
endfunction
"
" Set the highlight color for trailing whitespaces
call s:InitVariable('better_whitespace_ctermcolor', 'red')
call s:InitVariable('better_whitespace_guicolor', '#FF0000')

" Operator for StripWhitespace (empty to disable)
call s:InitVariable('better_whitespace_operator', '<leader>s')

" Set this to enable/disable whitespace highlighting
call s:InitVariable('better_whitespace_enabled', 1)

" Set this to match space characters that appear before or in-between tabs
call s:InitVariable('show_spaces_that_precede_tabs', 0)

" Set this to disable highlighting on the current line in all modes
" WARNING: This checks for current line on cursor move, which can significantly
"          impact the performance of Vim (especially on large files)
" WARNING: Ignored if g:current_line_whitespace_disabled_soft is set.
call s:InitVariable('current_line_whitespace_disabled_hard', 0)

" Set this to disable highlighting of the current line in all modes
" This setting will not have the performance impact of the above, but
" highlighting throughout the file may be overridden by other highlight
" patterns with higher priority.
call s:InitVariable('current_line_whitespace_disabled_soft', 0)

" Set this to enable stripping whitespace on file save
call s:InitVariable('strip_whitespace_on_save', 0)

" Set this to enable stripping white lines at the end of the file when we
" strip whitespace
call s:InitVariable('strip_whitelines_at_eof', 0)

" Set this to blacklist specific filetypes
call s:InitVariable('better_whitespace_filetypes_blacklist', ['diff', 'gitcommit', 'unite', 'qf', 'help', 'markdown'])

" Skip empty (whitespace-only) lines for highlighting
call s:InitVariable('better_whitespace_skip_empty_lines', 0)

" Disable verbosity by default
call s:InitVariable('better_whitespace_verbosity', 0)


" Section: Whitespace matching setup

" Define custom whitespace character group to include all horizontal unicode
" whitespace characters except tab (\u0009). Vim's '\s' class only includes ASCII spaces and tabs.
let s:whitespace_chars='\u0020\u00a0\u1680\u180e\u2000-\u200b\u202f\u205f\u3000\ufeff'
let s:eol_whitespace_pattern = '[\u0009' . s:whitespace_chars . ']\+$'

if g:better_whitespace_skip_empty_lines == 1
    let s:eol_whitespace_pattern = '[^\u0009' . s:whitespace_chars . ']\@1<=' . s:eol_whitespace_pattern
endif

let s:strip_whitespace_pattern = s:eol_whitespace_pattern
if g:show_spaces_that_precede_tabs == 1
    let s:eol_whitespace_pattern .= '\|[' . s:whitespace_chars . ']\+\ze[\u0009]'
endif

" Only init once
let s:better_whitespace_initialized = 0

" Ensure the 'ExtraWhitespace' highlight group has been defined
function! s:WhitespaceInit()
    " Check if the user has already defined highlighting for this group
    if hlexists('ExtraWhitespace') == 0 || synIDattr(synIDtrans(hlID('ExtraWhitespace')), 'bg') == -1
        execute 'highlight ExtraWhitespace ctermbg = '.g:better_whitespace_ctermcolor. ' guibg = '.g:better_whitespace_guicolor
    endif
    let s:better_whitespace_initialized = 1
endfunction


" Section: Actual work functions

" query per-buffer setting for whitespace highlighting
function! s:ShouldHighlight()
    " Guess from the filetype if a) not locally decided, b) globally enabled, c) there is enough information
    if !exists('b:better_whitespace_enabled') && g:better_whitespace_enabled == 1 && !(empty(&buftype) && empty(&filetype))
        let b:better_whitespace_enabled = &buftype != 'nofile' && index(g:better_whitespace_filetypes_blacklist, &ft) == -1
    endif
    return get(b:, 'better_whitespace_enabled', g:better_whitespace_enabled)
endfunction

" query per-buffer setting for whitespace stripping
function! s:ShouldStripWhitespace()
    " Guess from local whitespace enabled-ness and global whitespace setting
    if !exists('b:strip_whitespace_on_save') && exists('b:better_whitespace_enabled')
        let b:strip_whitespace_on_save = b:better_whitespace_enabled && g:strip_whitespace_on_save
    endif
    return get(b:, 'strip_whitespace_on_save', g:strip_whitespace_on_save)
endfunction

" Setup matching with either syntax or match
if g:current_line_whitespace_disabled_soft == 1
    " Match Whitespace on all lines
    function! s:HighlightEOLWhitespace()
        call <SID>ClearHighlighting()
        if <SID>ShouldHighlight()
            exe 'syn match ExtraWhitespace excludenl "' . s:eol_whitespace_pattern . '"'
        endif
    endfunction

    " Match Whitespace on all lines except the current one
    function! s:HighlightEOLWhitespaceExceptCurrentLine()
        call <SID>ClearHighlighting()
        if <SID>ShouldHighlight()
            exe 'syn match ExtraWhitespace excludenl "\%<' . line('.') .  'l' . s:eol_whitespace_pattern .
                                                 \ '\|\%>' . line('.') .  'l' . s:eol_whitespace_pattern . '"'
        endif
    endfunction

    " Remove Whitespace matching
    function! s:ClearHighlighting()
        syn clear ExtraWhitespace
    endfunction
else
    " Match Whitespace on all lines
    function! s:HighlightEOLWhitespace()
        if <SID>ShouldHighlight()
            exe 'match ExtraWhitespace "' . s:eol_whitespace_pattern . '"'
        else
            call <SID>ClearHighlighting()
        endif
    endfunction

    " Match Whitespace on all lines except the current one
    function! s:HighlightEOLWhitespaceExceptCurrentLine()
        if <SID>ShouldHighlight()
            exe 'match ExtraWhitespace "\%<' . line('.') .  'l' . s:eol_whitespace_pattern .
                                   \ '\|\%>' . line('.') .  'l' . s:eol_whitespace_pattern . '"'
        else
            call <SID>ClearHighlighting()
        endif
    endfunction

    " Remove Whitespace matching
    function! s:ClearHighlighting()
        match ExtraWhitespace ''
    endfunction
endif


" Removes all extraneous whitespace in the file
function! s:StripWhitespace(line1, line2)
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

" Strip using motion lines
function! s:StripWhitespaceMotion(...)
    call <SID>StripWhitespace(line("'["), line("']"))
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


" Sets up (or removes) all auto commands in the buffer, after checking the
" per-buffer settings. Also performs an initial highlighting (or clears it).
function! <SID>SetupAutoCommands()
    augroup better_whitespace
        " Reset all auto commands in group
        autocmd!

        if <SID>ShouldHighlight()
            if s:better_whitespace_initialized == 0
                call <SID>WhitespaceInit()
            endif

            " Highlight extraneous whitespace at the end of lines, but not the current line in insert mode.
            call <SID>HighlightEOLWhitespace()
            autocmd CursorMovedI,InsertEnter * call <SID>HighlightEOLWhitespaceExceptCurrentLine()
            autocmd InsertLeave,BufReadPost * call <SID>HighlightEOLWhitespace()

            if g:current_line_whitespace_disabled_soft == 0
                " Using syntax: clear whitespace highlighting when leaving buffer
                autocmd BufWinLeave * call <SID>ClearHighlighting()

                " Do not highlight whitespace on current line in insert mode
                autocmd CursorMovedI * call <SID>HighlightEOLWhitespaceExceptCurrentLine()

                " Do not highlight whitespace on current line in normal mode?
                if g:current_line_whitespace_disabled_hard == 1
                    autocmd CursorMoved * call <SID>HighlightEOLWhitespaceExceptCurrentLine()
                endif
            endif

        elseif s:better_whitespace_initialized == 1
            " Clear highlighting if it disabled, as it might have just been toggled
            call <SID>ClearHighlighting()
        endif

        " Strip whitespace on save if enabled.
        if <SID>ShouldStripWhitespace()
            autocmd BufWritePre * call <SID>StripWhitespace(0, line("$"))
        endif

    augroup END
endfunction

" Check & setup auto commands upon enter & load, and again on filetype change.
autocmd FileType,WinEnter,BufWinEnter * call <SID>SetupAutoCommands()
autocmd ColorScheme * call <SID>WhitespaceInit()


" Section: Setting of per-buffer higlighting/stripping

function! s:EnableWhitespace()
    let b:better_whitespace_enabled = 1
    call <SID>SetupAutoCommands()
endfunction

function! s:DisableWhitespace()
    let b:better_whitespace_enabled = 0
    call <SID>SetupAutoCommands()
endfunction

function! s:ToggleWhitespace()
    let b:better_whitespace_enabled = 1 - <SID>ShouldHighlight()
    call <SID>SetupAutoCommands()
endfunction

function! s:EnableStripWhitespaceOnSave()
    let b:strip_whitespace_on_save = 1
    call <SID>SetupAutoCommands()
endfunction

function! s:DisableStripWhitespaceOnSave()
    let b:strip_whitespace_on_save = 0
    call <SID>SetupAutoCommands()
endfunction

function! s:ToggleStripWhitespaceOnSave()
    let b:strip_whitespace_on_save = 1 - <SID>ShouldStripWhitespace()
    call <SID>SetupAutoCommands()
endfunction


" Section: Public commands and mappings

" Run :StripWhitespace to remove end of line whitespace
command! -range=% StripWhitespace call <SID>StripWhitespace(<line1>, <line2>)
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
" Search for trailing white space forwards
command! -range=% NextTrailingWhitespace call <SID>GotoTrailingWhitespace(0, <line1>, <line2>)
" Search for trailing white space backwards
command! -range=% PrevTrailingWhitespace call <SID>GotoTrailingWhitespace(1, <line1>, <line2>)

if !empty(g:better_whitespace_operator)
    " Ensure we only map if no identical, user-defined mapping already exists
    if (empty(mapcheck(g:better_whitespace_operator, 'x')))
        " Visual mode
        exe 'xmap <silent> '.g:better_whitespace_operator.' :StripWhitespace<CR>'
    endif

    " Ensure we only map if no identical, user-defined mapping already exists
    if (empty(mapcheck(g:better_whitespace_operator, 'n')))
        " Normal mode (+ space, with line count)
        exe 'nmap <silent> '.g:better_whitespace_operator.'<space> :<C-U>exe ".,+".v:count" StripWhitespace"<CR>'
        " Other motions
        exe 'nmap <silent> '.g:better_whitespace_operator.'        :<C-U>set opfunc=<SID>StripWhitespaceMotion<CR>g@'
    endif
endif


" Deprecated legacy commands, set for compatiblity and to point users in the right direction.
let s:errmsg='please set g:current_line_whitespace_disabled_{soft,hard} and reload better whitespace'
command! -nargs=* CurrentLineWhitespaceOff echoerr 'Deprecated command CurrentLineWhitespaceOff: '.s:errmsg
command! CurrentLineWhitespaceOn echoerr 'Deprecated command CurrentLineWhitespaceOn: '.s:errmsg
