if exists('loaded_trailing_whitespace_plugin') | finish | endif
let loaded_trailing_whitespace_plugin = 1

" Set this to enable/disable whitespace highlighting
let g:trailing_whitespace_enabled=1

" Set this to disable highlighting on the current line in all modes
" WARNING: This checks for current line on cursor move, which can significantly
"		   impact the performance of Vim (especially on large files)
let g:current_line_whitespace_disabled=0

" Set this to disable highlighting of the current line in all modes
" This setting will not have the performance impact of the above, but
" highlighting throughout the file may be overridden by other highlight
" patterns with higher priority.
let g:current_line_whitespace_disabled_soft=0

" Set this to enable stripping whitespace on file save
let g:strip_whitespace_on_save=0

" Only init once
let s:trailing_whitespace_initialized=0


" Highlight EOL whitespace, http://vim.wikia.com/wiki/Highlight_unwanted_spaces
function! s:WhitespaceInit()
	if hlexists("ExtraWhitespace")==0
		highlight ExtraWhitespace ctermbg=red
	endif
	let g:trailing_whitespace_initialized=1
endfunction

" Enable the whitespace highlighting
function! s:EnableWhitespace()
	let g:trailing_whitespace_enabled=1
	call <SID>WhitespaceInit()
	match ExtraWhitespace /\s\+$/
endfunction

" Disable the whitespace highlighting
function! s:DisableWhitespace()
	let g:trailing_whitespace_enabled=0
	match ExtraWhitespace ''
endfunction

" Toggle whitespace highlighting on/off
function! s:ToggleWhitespace()
	if g:trailing_whitespace_enabled==1
		call <SID>DisableWhitespace()
	else
		call <SID>EnableWhitespace()
	endif
endfunction

" This disabled whitespace highlighting on the current line in all modes
" Options:
" hard - Disables highlighting for current line and maintains high priority
"		 highlighting for the entire file. Caution: may cause slowdown in Vim!
" soft - No potential slowdown as with 'hard' option, but other highlighting
"		 rules of higher priority may overwrite these whitespace highlights.
function! s:CurrentLineWhitespaceOff(level)
	if a:level=='hard'
		let g:current_line_whitespace_disabled=1
		let g:current_line_whitespace_disabled_soft=0
	elseif a:level=='soft'
		let g:current_line_whitespace_disabled_soft=1
		let g:current_line_whitespace_disabled=0
	endif
	match ExtraWhitespace ''
	call <SID>RunAutoCommands()
endfunction

" Enables whitespace highlighting for the current line
function! s:CurrentLineWhitespaceOn()
	let g:current_line_whitespace_disabled=0
	let g:current_line_whitespace_disabled_soft=0
	call <SID>RunAutoCommands()
	match ExtraWhitespace /\s\+$/
endfunction

" Removes all extaneous whitespace in the file
function! s:FixWhitespace(line1,line2)
	let l:save_cursor = getpos(".")
	silent! execute ':' . a:line1 . ',' . a:line2 . 's/\s\+$//'
	call setpos('.', l:save_cursor)
endfunction

" Strips whitespace on file save
function! s:ToggleFixWhitespaceOnSave()
	if g:strip_whitespace_on_save==0
		let g:strip_whitespace_on_save=1
	else
		let g:strip_whitespace_on_save=0
	endif
	call <SID>RunAutoCommands()
endfunction

" Run :FixWhitespace to remove end of line white space
command! -range=% FixWhitespace call <SID>FixWhitespace(<line1>,<line2>)
" Run :ToggleFixWhitespaceOnSave to enable/disable whitespace stripping on save
command! -nargs=* ToggleFixWhitespaceOnSave call <SID>ToggleFixWhitespaceOnSave()
" Run :EnableWhitespace to enable whitespace highlighting
command! -nargs=* EnableWhitespace call <SID>EnableWhitespace()
" Run :DisableWhitespace to disable whitespace highlighting
command! -nargs=* DisableWhitespace call <SID>DisableWhitespace()
" Run :ToggleWhitespace to toggle whitespace highlighting on/off
command! -nargs=* ToggleWhitespace call <SID>ToggleWhitespace()
" Run :CurrentLineWhitespaceOff(level) to disable highlighting for the current
" line. Levels are: 'hard' and 'soft'
command! -nargs=* CurrentLineWhitespaceOff call <SID>CurrentLineWhitespaceOff(<f-args>)
" Run :CurrentLineWhitespaceOn to turn on whitespace for the current line
command! -nargs=* CurrentLineWhitespaceOn call <SID>CurrentLineWhitespaceOn()

" Process auto commands upon load
autocmd VimEnter,WinEnter,BufEnter,FileType * call <SID>RunAutoCommands()

" Executes all auto commands
function! <SID>RunAutoCommands()
	" Auto commands group
	augroup trailing_whitespace
		autocmd!

		if g:trailing_whitespace_enabled==1
			if s:trailing_whitespace_initialized==0
				call <SID>WhitespaceInit()
            endif

			" Check if current line is disabled softly
			if g:current_line_whitespace_disabled_soft==0
				autocmd ColorScheme * highlight ExtraWhitespace ctermbg=red guibg=red
				" Highlight all whitespace upon entering buffer
				autocmd BufWinEnter * match ExtraWhitespace /\s\+$/
				" Check if current line highglighting is disabled
				if g:current_line_whitespace_disabled==1
					" Never highlight whitespace on current line
					autocmd InsertEnter,CursorMoved * exe 'match ExtraWhitespace ' . '/\%<' . line(".") .  'l\s\+$\|\%>' . line(".") .  'l\s\+$/'
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
				autocmd InsertEnter * syn clear ExtraWhitespace | syn match ExtraWhitespace excludenl /\s\+\%#\@!$/
				autocmd InsertLeave,BufReadPost * syn clear ExtraWhitespace | syn match ExtraWhitespace excludenl /\s\+$/
			endif
		endif

		" Strip whitespace on save if enabled
		if g:strip_whitespace_on_save==1
			autocmd BufWritePre * call <SID>FixWhitespace(0,line("$"))
		endif

	augroup END
endfunction
