" 'is GUI' means vim is _not_ running within the terminal.
" sample values:
"   &term  = win32 //vimrc running in msysgit terminal
"   $TERM  = xterm-color , cygwin
"   &term  = builtin_gui //*after* vimrc but *before* gvimrc
"   &shell = C:\Windows\system32\cmd.exe , /bin/bash
let s:is_gui = has('gui_running') || strlen(&term) == 0 || &term ==? 'builtin_gui'

if has("nvim")
  if (!filereadable(expand("~/.nvimrc", 1)) || (!isdirectory(expand("~/.nvim", 1))))
    echomsg "Missing .nvim/ or .nvimrc"
  endif

  tnoremap <esc><esc> <c-\><c-n>
  let $NVIM_TUI_ENABLE_CURSOR_SHAPE = 1
else
  " required for alt/meta mappings  https://github.com/tpope/vim-sensible/issues/69
  set encoding=utf-8

  " To map a 'meta' escape sequence in a terminal, you must map the literal control character.
  " insert-mode, type ctrl-v, then press alt+<key> (while in a terminal, not gvim).
  " http://vim.wikia.com/wiki/Mapping_fast_keycodes_in_terminal_Vim
  " http://stackoverflow.com/a/10633069/152142
  if !s:is_msysgit && !s:is_gui
      "avoid: m-b m-d m-f
      set <m-g>=g <m-h>=h <m-i>=i <m-j>=j <m-k>=k <m-l>=l <m-m>=m
            \ <m-n>=n <m-o>=o <m-p>=p <m-q>=q <m-r>=r <m-s>=s
            \ <m-t>=t <m-w>=w <m-x>=x <m-y>=y <m-z>=z
            \ <m-]>=]
  endif

  " may affect performance: https://github.com/tpope/vim-sensible/issues/57
  " let &listchars = "tab:\u21e5 ,trail:\u2423,extends:\u21c9,precedes:\u21c7,nbsp:\u00b7"
  " let &showbreak="\u21aa" " precedes line wrap
  set listchars=tab:>\ ,trail:-,nbsp:+

  if has('vim_starting') && s:is_windows
    set runtimepath+=~/.vim/
  endif

  set ttyfast

  " avoid sourcing stupid menu.vim (saves ~100ms)
  let g:did_install_default_menus = 1

  if s:is_cygwin || !empty($TMUX)
    " Mode-dependent cursor   https://code.google.com/p/mintty/wiki/Tips
    let &t_ti.="\e[1 q"
    let &t_SI.="\e[5 q"
    let &t_EI.="\e[1 q"
    let &t_te.="\e[0 q"
  endif

  if s:is_cygwin && !s:is_msys
    " use separate viminfo to avoid weird permissions issues
    set viminfo+=n~/.viminfo_cygwin

    " set escape key to an unambiguous keycode, to avoid escape timeout delay.
    let &t_ti.="\e[?7727h"
    let &t_te.="\e[?7727l"
    noremap  <Esc>O[ <Esc>
    noremap! <Esc>O[ <C-c>
  endif
endif

func! EnsureDir(path)
  "trim
  let l:path = expand(substitute(a:path,  '\s\+', '', 'g'), 1)

  if empty(l:path)
    echom "EnsureDir(): invalid path: ".a:path
    return 0 "path is empty/blank.
  endif

  if !isdirectory(l:path)
    call mkdir(l:path, 'p')
  endif
  return isdirectory(l:path)
endfun

func! EnsureFile(path)
  let l:path = expand(a:path, 1)
  if !filereadable(l:path) && -1 == writefile([''], l:path)
    echoerr "failed to create file: ".l:path
  endif
endf

command! LoadSession if filereadable(expand("~/.vim/session.vim", 1)) | source ~/.vim/session.vim
      \ | else | Obsession ~/.vim/session.vim | endif
set sessionoptions-=blank

"==============================================================================
" general settings / options
"==============================================================================

" replacement for vim-vertical-move
func! s:vjump(col, direction) abort
  let w=winsaveview()

  " Find a:col _above_ a line that has only whitespace extending to the first
  " or last column.
  let pat_above_ws =
    \ '\v.*\S.*%'.(a:col).'v\zs.\ze(.*\S.*)?\n((.*%<'.(a:col).'v.)?|(\s*%'.(a:col+1).'v.*)|(.*%'.(a:col-1).'v\s*))$'
  "             ^                       ^          ^                   ^                     ^
  "             match                 line2:       |                   |                     |
  "                                              empty?         all whitespace      all whitespace
  "                                                             to the left?        to the right?

  " Find a:col _below_ a line that has only whitespace extending to the first
  " or last column.
  let pat_below_ws =
    \ '\v\_^((.*%<'.(a:col).'v.)?|(\s*%'.(a:col+1).'v.*)|(.*%'.(a:col-1).'v\s*))\n.*\S.*%'.(a:col).'v\zs.\ze(.*\S.*)?$'

  let above = searchpos(pat_above_ws, 'nW'.(a:direction ? 'b' : ''), 0, 1000)
  let below = searchpos(pat_below_ws, 'nW'.(a:direction ? 'b' : ''), 0, 1000)
  "choose the nearest match
  let goto = a:direction ? (above[0] > below[0] ? above : below)
        \ : (above[0] > 0 && above[0] < below[0] ? above : below)
  norm! m`

  call winrestview(w)
  if goto[0] != 0
    call cursor(goto)
  endif "else, no match found

  " let @a = pat_below_ws
  " echom 'patabove:' pat_above_ws
  " echom 'above:' above[0] 'below:' below[0]
endf
nnoremap <silent> 1j      :<c-u>call <sid>vjump(virtcol('.'), 0)<cr>
nnoremap <silent> 1k      :<c-u>call <sid>vjump(virtcol('.'), 1)<cr>
xnoremap <silent> 1j <esc>:<c-u>call <sid>vjump(virtcol('.'), 0)<cr>``gv``
xnoremap <silent> 1k <esc>:<c-u>call <sid>vjump(virtcol('.'), 1)<cr>``gv``
onoremap <silent> 1j      :<c-u>call <sid>vjump(virtcol('.'), 0)<cr>
onoremap <silent> 1k      :<c-u>call <sid>vjump(virtcol('.'), 1)<cr>

let g:EclimBufferTabTracking = 0 "legacy version
let g:EclimBuffersTabTracking = 0

let mapleader = "z,"
let g:mapleader = "z,"

try | lang en_US | catch | endtry

set list

set cursorline

set path+=/usr/lib/gcc/**/include

let g:sh_noisk = 1
set hidden      " Allow buffer switching even if unsaved 
set lazyredraw  " no redraws in macros
set cmdheight=2
set ignorecase " case-insensitive searching
set smartcase  " but become case-sensitive if you type uppercase characters

"audible bell persists unless visualbell is enabled.
set noerrorbells novisualbell t_vb=

set timeoutlen=3000
set noshowmode " Hide the mode text (e.g. -- INSERT --)
set foldlevelstart=99 "open all folds by default
set noequalalways
set splitright
if has('patch-7.4.314') | set shortmess+=c | endif
set shortmess+=I

nnoremap <silent> coz :<c-u>if &foldenable && &foldmethod==#'indent' <bar> set nofoldenable foldmethod=manual <bar> else <bar> set foldmethod=indent foldnestmax=3 foldlevel=0 foldenable <bar> endif<cr>
nnoremap <silent> coM :<c-u>if '' ==# synIDattr(synIDtrans(hlID("MatchParen")),"bg") 
      \ <bar> hi MatchParen guifg=NONE guibg=orange gui=underline ctermfg=NONE ctermbg=cyan cterm=underline 
      \ <bar> else <bar> hi MatchParen guifg=NONE guibg=NONE gui=underline ctermfg=NONE ctermbg=NONE cterm=underline<bar> endif<cr>


set nojoinspaces

set nostartofline
" restore cursor position upon returning to a buffer, _without_ permanently 
" setting 'nostartofline' (which affects many other behaviors).
if &startofline
  augroup vimrc_stayput
    autocmd!
      " 1. disable 'startofline' temporarily while switching buffers, 
      " 2. then re-enable it on CursorMoved, 
      " 3. then clear the CursorMoved autocmd to avoid spam
      autocmd BufLeave * set nostartofline |
            \ autocmd vimrc_stayput CursorMoved,CursorMovedI * set startofline |
            \ autocmd! vimrc_stayput CursorMoved,CursorMovedI
  augroup END
endif

" platform-specific settings
if s:is_windows
    set winaltkeys=no
    set guifont=Consolas:h11
    if has("directx")
      set renderoptions=type:directx
    endif
elseif s:is_gui "linux or other
    set guifont=Monospace\ 10
endif

"colorscheme {{{
  call matchadd('ColorColumn', '\%81v', 100)
  if s:is_msys
    let &t_Co = 256
  endif

  if (!s:is_gui && &t_Co <= 88) || findfile('colors/molokai.vim', &rtp) ==# ''
    silent! colorscheme ron
  else
    let s:color_override_dark = '
          \ if &background == "dark"
          \ | hi StatusLine    guifg=#000000 guibg=#ffffff gui=NONE  ctermfg=16 ctermbg=15     cterm=NONE
          \ | hi CursorLine    guibg=#293739 ctermbg=236
          \ | hi PmenuSel      guibg=#0a9dff guifg=white   gui=NONE  ctermbg=39 ctermfg=white  cterm=NONE
          \ | hi PmenuSbar     guibg=#857f78
          \ | hi PmenuThumb    guifg=#242321
          \ | hi WildMenu      gui=NONE cterm=NONE guifg=#f8f6f2 guibg=#0a9dff ctermfg=255 ctermbg=39
          \ | hi DiffAdd       guifg=#ffffff guibg=#006600 gui=NONE  ctermfg=231  ctermbg=22   cterm=NONE 
          \ | hi DiffChange    guifg=#ffffff guibg=#007878 gui=NONE  ctermfg=231  ctermbg=30   cterm=NONE 
          \ | hi DiffDelete    guifg=#ff0101 guibg=#9a0000 gui=NONE  ctermfg=196  ctermbg=88   cterm=NONE 
          \ | hi DiffText      guifg=#000000 guibg=#ffb733 gui=NONE  ctermfg=000  ctermbg=214  cterm=NONE 
          \ | hi MatchParen    guifg=NONE   guibg=NONE gui=underline ctermfg=NONE ctermbg=NONE cterm=underline
          \ | endif
          \'

    if has('vim_starting') "only on startup
      exe 'autocmd ColorScheme * '.s:color_override_dark
      " expects &runtimepath/colors/{name}.vim.
      silent! colorscheme molokai
    endif
  endif

func! s:set_CursorLine()
  if s:is_msysgit | return | endif

  hi clear CursorLine
  if &diff
    hi CursorLine gui=underline cterm=underline
  else
    hi CursorLine guibg=#293739 ctermbg=236
  endif
endf
"}}}

"==============================================================================
" text, tab and indent 

set formatoptions+=rno1l
" don't syntax-highlight long lines
set synmaxcol=1000

set expandtab
if (v:version > 703)
  set softtabstop=-1 "use value of 'shiftwidth'
endif
set shiftwidth=2

set linebreak
set nowrap

" =============================================================================
" util functions

" http://www.vim.org/scripts/script.php?script_id=1714
" - uses FileChangedShell and :checktime to avoid re-loading an un-changed file.
" - only updates if the buffer is visible.
" - autocmds are torn down after buffer is closed or hidden.
" - let b:tail_follow=1 to auto-scroll
" - Vim:
"     - depends on CursorHold, so tailed buffers won't update while you are moving the cursor.
"     - set 'updatetime' lower if you want faster updates
"     - b:tail_follow only works if the tailed file is the current buffer
let s:tail_orig_updtime = &updatetime
func! Tail(filename) "TODO: disable undo for buffer?
  let filename = escape(dispatch#expand(a:filename), '#%')
  if strlen(filename) > 0
    exec 'split '.filename
  endif "else: tail the current buffer.

  let &updatetime=1000
  setlocal autoread

  let aubuff = '<buffer='.bufnr("%").'>'
  "buffer-local
  augroup TailSmurf
    exec 'au! * '.aubuff
    exec 'autocmd BufEnter,WinEnter '.aubuff.' let &updatetime=1000'
    exec 'autocmd BufLeave,BufHidden,WinLeave '.aubuff.' let &updatetime='.s:tail_orig_updtime
    "Follow only the current buffer (anything more sophisticated is a pain in the ass).
    exec 'autocmd FileChangedShellPost '.aubuff.' if get(b:, "tail_follow", 0) && bufnr("%")=='.bufnr("%").'|exec "norm! G"|endif'
  augroup END

  call feedkeys("f\e", "n") "force cursor activity to kick CursorHold

  "global
  au! TailSmurf CursorHold
  autocmd TailSmurf CursorHold * checktime | call feedkeys("f\e", "n")
endf
command! -bang -nargs=? -complete=file Tail call Tail(<q-args>)

" =============================================================================
" normal mode

nnoremap & :&&<CR>
xnoremap & :&&<CR>

" Make Y consistent with C and D.
nnoremap Y y$
" copy selection to gui-clipboard
xnoremap Y "+y
" copy entire file contents (to gui-clipboard if available)
nnoremap yY :let b:winview=winsaveview()<bar>exe 'norm ggVG'.(has('clipboard')?'"+y':'y')<bar>call winrestview(b:winview)<cr>
inoremap <insert> <C-r>+

" delete the 'head' of a path on the command line
cnoremap <silent> <c-x> <C-\>e<sid>delete_until()<cr>

func! s:delete_until()
  let c = nr2char(getchar())
  return substitute(getcmdline(), '\(.*['.escape(c, '\').']\).*', '\1', '')
endfunc

" key mappings/bindings =================================================== {{{


" word-wise i_CTRL-Y
inoremap <expr> <c-y> pumvisible() ? "\<c-y>" : matchstr(getline(line('.')-1), '\%' . virtcol('.') . 'v\%(\k\+\\|.\)')

" current-file directory
noremap! <silent> <c-r><c-\> <c-r>=expand('%:p:h', 1)<cr>

inoremap z,   <c-o>
inoremap z,p  <c-r>"

noremap! <c-r>? <c-r>=substitute(getreg('/'), '[<>\\]', '', 'g')<cr>

" mark position before search
nnoremap / ms/

func! s:norm_n(n)
  let topline = winsaveview().topline
  try
    exe 'norm! ' a:n
  catch /E486:/
    echohl ErrorMsg | echom matchstr(v:exception, 'E486:.*') | echohl None
  endtry
  if topline != winsaveview().topline
    normal! zz
    call feedkeys("\<Plug>Pulse", 'm')
  endif
endf
nnoremap <silent> n :<C-U>call <SID>norm_n('n')<CR>
nnoremap <silent> N :<C-U>call <SID>norm_n('N')<CR>

" manage windows
"       [count]<c-w>s and [count]<c-w>v create a [count]-sized split
"       [count]<c-w>| and [count]<c-w>_ resize the current window
" user recommendation:
"       <c-w>eip
" available:
"       <c-w><space>{motion}
nnoremap <m-h> <c-w>h
nnoremap <m-j> <c-w>j
nnoremap <m-k> <c-w>k
nnoremap <m-l> <c-w>l
nnoremap <c-w>N :vnew<cr>
nnoremap <silent> c<tab> <c-w>s
nnoremap <silent> d<tab> <c-w>c
nnoremap <silent><expr> <tab> (v:count > 0 ? '<c-w>w' : ':<C-u>call <sid>switch_to_alt_win()<cr>')
xmap     <silent>       <tab> <esc><tab>
nnoremap <m-i> <c-i>

func! s:win_motion_resize(type)
  let sel_save = &selection
  let &selection = "inclusive"

  if a:type ==# 'line' || line("']") > line("'[")
    exe (line("']") - line("'[") + 1) 'wincmd _'
    norm! `[zt
  endif
  if a:type !=# 'line'
    "TODO: this assumes sign column is visible.
    exe ( col("']") -  col("'[") + 3) 'wincmd |'
  endif

  let &selection = sel_save
endf

" fit the current window height to the selected text
xnoremap <silent> <c-w><c-w>  :<C-u>set winfixwidth winfixheight opfunc=<sid>win_motion_resize<CR>gvg@

" go to the previous window (or any other window if there is no 'previous' window).
func! s:switch_to_alt_win()
  let currwin = winnr()
  wincmd p
  if winnr() == currwin "window didn't change, so there was no 'previous' window.
    wincmd W
  endif
endf

func! s:get_alt_winnr()
  call s:switch_to_alt_win()
  let n = winnr()
  call s:switch_to_alt_win()
  return n
endf

" manage tabs
"       gwT (built-in) breaks out window into new Tab.
nnoremap cgt      :tabnew<cr>
nnoremap dgt      :tabclose<cr>
nnoremap ]gt      :tabmove +1<cr>
nnoremap [gt      :tabmove -1<cr>
" move tab to Nth tab position
nnoremap <expr> gT (v:count > 0 ? ':<c-u>tabmove '.(v:count - 1).'<cr>' : 'gT')

" manage buffers
nnoremap <expr><silent> ZB  ':<c-u>call <SID>buf_kill('. !v:count .')<cr>'

" quickfix window
nnoremap <silent><c-q> :silent! botright copen<cr>
" location window
" nnoremap q] :botright lopen<cr>

nnoremap <expr> zt (v:count > 0 ? '@_zt'.v:count.'<c-y>' : 'zt')
nnoremap <expr> zb (v:count > 0 ? '@_zb'.v:count.'<c-e>' : 'zb')

nnoremap <silent> ^ :Dirvish %:p:h<cr>
" set working directory to the current buffer's directory
nnoremap cd :lcd %:p:h<bar>pwd<cr>
nnoremap cu :lcd ..<bar>pwd<cr>
nnoremap cD :cd %:p:h<bar>pwd<cr>
nnoremap cU :cd ..<bar>pwd<cr>

if findfile('plugin/fugitive.vim', &rtp) !=# ''
  " show git branch with ctrl-g info
  func! s:ctrl_g(cnt) abort
    redir => msg | silent exe "norm! 1\<c-g>" | redir END
    echo fugitive#head(7) msg[2:] (a:cnt?strftime('%Y-%m-%d %H:%M',getftime(expand('%:p'))):'')
  endf
  nnoremap <C-g> :<c-u>call <sid>ctrl_g(v:count)<cr>
endif

" show the working directory and session
nnoremap <M-g> :<C-u>echo fnamemodify(getcwd(), ":~")
      \ (strlen(v:this_session) ? fnamemodify(v:this_session, ":~") : "[No session]")<cr>

nmap     <c-n>    ]c
nmap     <c-p>    [c

" version control
xnoremap <expr> D (mode() ==# "V" ? ':Linediff<cr>' : 'D')
nnoremap UU :if &diff<bar>diffupdate<bar>else<bar>diffthis<bar>endif<cr>
nnoremap Ud :if &diff<bar>diffupdate<bar>else<bar>Gdiff<bar>endif<cr>
nmap     Uc :exe 'Gsplit '.matchstr('<c-r><c-g>', '[^:]*')<cr>
nnoremap Us :Gstatus<cr>
nnoremap Ul :Gllog<cr>
nnoremap Ug :Ggrep<space>
nnoremap UB :Gblame<cr>
nnoremap Ue :Gedit<cr>
nnoremap Uh :SignifyToggleHighlight<cr>
nnoremap UR :Gread<cr>
nnoremap UW :if !exists(":Gwrite")<bar>call fugitive#detect(expand('%:p'))
      \ <bar>endif<bar>Gwrite<bar>call <sid>reload_without_jank()<cr>
"                                 ^reload buffer to kick signify.vim
nnoremap <silent> UG :cd %:p:h<bar>silent exec '!git gui '.(has('win32')<bar><bar>has('win64') ? '' : '&')<bar>cd -<bar>if !has('gui_running')<bar>redraw!<bar>endif<cr>
nnoremap <silent> UL :cd %:p:h<bar>silent exec '!gitk --all '.(has('win32')<bar><bar>has('win64') ? '' : '&')<bar>cd -<bar>if !has('gui_running')<bar>redraw!<bar>endif<cr>
"linewise partial staging in visual-mode.
xnoremap <c-p> :diffput<cr>
xnoremap <c-o> :diffget<cr>
nnoremap <expr> dp &diff ? 'dp' : ':pclose<cr>'

" Executes git cmd in the context of b:git_dir.
function! s:git_do(cmd) abort
  " git 1.8.5: -C is a (more reliable) alternative to --git-dir/--work-tree.
  return systemlist('git -C '.shellescape(fnamemodify(b:git_dir, ':p:h:h'))
        \ . ' ' . a:cmd)
endfunction

" Gets the git commit hash associated with the given file line.
function! s:git_sha(filepath, line) abort
  if "" ==# s:trimws_ml(a:filepath)
    echoerr "invalid (empty) filepath"
  elseif !exists("b:git_dir")
    echoerr "Missing b:git_dir"
  elseif a:line <= 0
    echoerr "Invalid a:line: ".a:line
  endif

  let cmd_out = join(s:git_do('blame --root -l -L'.a:line.','.a:line.' -- '.a:filepath))
  if cmd_out =~# '\v^0{40,}'
    return ""
  endif

  return matchstr(cmd_out, '\w\+\ze\W\?', 0, 1)
endfunction

function! s:git_blame_line(filepath, line) abort
  let commit_id = s:git_sha(a:filepath, a:line)
  if commit_id ==# ""
    echo 'not committed'
    return
  endif

  " Find commit(s) with 0 parents.
  " Note: `git blame` prepends a caret ^ to root commits unless --root is
  "       passed. But it doesn't always mark the 'root' commits we are
  "       interested in, so collect them explicitly with `git rev-list`.
  let b:git_root_commits = get(b:, 'git_root_commits', s:git_do('rev-list --max-parents=0 HEAD'))

  if -1 != index(b:git_root_commits, commit_id)
    echo 'root commit'
    return
  endif

  exe 'Gpedit '.commit_id
endfunction

nmap     Ub :<c-u>call <sid>git_blame_line('<c-r><c-g>', line('.'))<cr>
"                                            ^^
" Get the repo-relative path with fugitive's CTRL-R_CTRL-G

func! Fugitive_browse_cwsrc2(o) "https://github.com/tommcdo/vim-fubitive/blob/master/plugin/fubitive.vim
  if a:0 || type(a:o) != type({})
    return ''
  endif
  let path = a:o.path
  let domain_pattern = 'cwsrc2'
  let repo = matchstr(a:o.remote,'^\%(https\=://\|git://\|\(ssh://\)\=git@\)\zs\('.domain_pattern.'\)[/:].\{-\}\ze\%(\.git\)\=$')
  let repo = substitute(repo, '^cwsrc2:', '', '')
  if repo ==# ''
    return ''
  endif
  let root = 'http://cwsrc2/' . repo
  if path =~# '^\.git/refs/heads/'
    let branch = a:o.repo.git_chomp('config','branch.'.path[16:-1].'.merge')[11:-1]
    if branch ==# ''
      return root . '/commits/' . path[16:-1]
    else
      return root . '/commits/' . branch
    endif
  elseif path =~# '^\.git/refs/.'
    return root . '/commits/' . matchstr(path,'[^/]\+$')
  elseif path =~# '.git/\%(config$\|hooks\>\)'
    return root . '/admin'
  elseif path =~# '^\.git\>'
    return root
  endif
  if a:o.revision =~# '^[[:alnum:]._-]\+:'
    let commit = matchstr(a:o.revision,'^[^:]*')
  elseif a:o.commit =~# '^\d\=$'
    let local = matchstr(a:o.repo.head_ref(),'\<refs/heads/\zs.*')
    let commit = a:o.repo.git_chomp('config','branch.'.local.'.merge')[11:-1]
    if commit ==# ''
      let commit = local
    endif
  else
    let commit = a:o.commit
  endif
  if a:o.type == 'tree'
    let url = s:sub(root . '/tree/' . commit . '/' . path,'/$','')
  elseif a:o.type == 'blob'
    let url = root . '/blob/' . commit . '/' . path
    if get(a:o, 'line1')
      let url .= '#cl-' . a:o.line1
    endif
  elseif a:o.type == 'tag'
    let commit = matchstr(getline(3),'^tag \zs.*')
    let url = root . '/tree/' . commit
  else
    let url = root . '/commit/' . commit
  endif
  return url
endf
let g:fugitive_browse_handlers = [ function('Fugitive_browse_cwsrc2') ]



" :help :DiffOrig
command! DiffOrig leftabove vnew | set bt=nofile | r ++edit # | 0d_ | diffthis | wincmd p | diffthis

nnoremap <silent> co<space> :set <C-R>=(&diffopt =~# 'iwhite') ? 'diffopt-=iwhite' : 'diffopt+=iwhite'<CR><CR>

" execute/evaluate
nmap yxa.    <Plug>(quickrun)
xmap <enter> <Plug>(quickrun)

" filter
" TODO: https://github.com/Chiel92/vim-autoformat
" nnoremap c<cr>jj    :%!python -m json.tool<cr>
" nnoremap z<cr>jj    :%!python -m json.tool<cr>
" nnoremap c<space>jj :%!python -m json.tool<cr>
" nnoremap g<bar>jj   :%!python -m json.tool<cr>
nnoremap <bar>jj :%!python -m json.tool<cr>
xnoremap <bar>jj :!python -m json.tool<cr>
" windows binary: http://tidybatchfiles.info
nnoremap gqax    :%!tidy -q -i -xml -utf8<cr>
nnoremap gqah    :%!tidy -q -i -ashtml -utf8<cr>

" available mappings:
"   visual: c-\ <space> m R c-r c-n c-g c-a c-x c-h,<bs>
"   insert: c-\ c-g
"   normal: c-f c-t c-b c-j c-k + _ c-\ g= zu z/ m<enter> zy zi zp m<tab> q<special> y<special> <del> <pageup/down> q<special>
"           1j 1k 1...
"           c<space> --> easyalign
"           !@       --> async run

func! s:buf_compare(b1, b2)
  let b1_visible = -1 == index(tabpagebuflist(), a:b1)
  let b2_visible = -1 == index(tabpagebuflist(), a:b2)
  "prefer loaded and NON-visible buffers
  if bufloaded(a:b1)
    if bufloaded(a:b2)
      return b2_visible ? !b1_visible : -1
    endif
    return 0
  endif
  return !bufloaded(a:b2) ? 0 : 1
endf

func! s:buf_find_displayed_bufs() " find all buffers displayed in any window, any tab.
  let l:bufs = []
  for i in range(1, tabpagenr('$'))
    call extend(l:bufs, tabpagebuflist(i))
  endfor
  return l:bufs
endf

func! s:buf_find_valid_next_bufs()
  "valid 'next' buffers
  "   EXCLUDE:
  "     - current
  "     - unlisted
  "     - directory buffers marked as 'readonly' and 'modified' (netrw sometimes leaves a _listed_ buffer in this weird state)
  "   INCLUDE: normal buffers; 'help' buffers
  let l:valid_buffers = filter(range(1, bufnr('$')), 
              \ 'buflisted(v:val) 
              \  && ("" ==# getbufvar(v:val, "&buftype") || "help" ==# getbufvar(v:val, "&buftype")) 
              \  && v:val != bufnr("%") 
              \  && -1 == index(tabpagebuflist(), v:val) 
              \  && !(isdirectory(bufname(v:val)) && getbufvar(v:val, "&modified") && getbufvar(v:val, "&readonly"))
              \ ')
  call sort(l:valid_buffers, '<sid>buf_compare')
  return l:valid_buffers
endf

func! s:buf_switch_to_altbuff()
  " change to the 'alternate' buffer if:
  "   - it exists, and 
  "   - it is not the current buffer (yes, this really happens, eg with netrw)
  if -1 != bufnr("#") && bufnr("#") != bufnr("%")
    buffer #
    return 1
  else " change to first 'valid' buffer
    let l:valid_buffers = s:buf_find_valid_next_bufs()
    if len(l:valid_buffers) > 0
      exe 'buffer '.l:valid_buffers[0]
      return 1
    endif
  endif

  return 0
endf

" close the current buffer with a vengeance
" BDSN: Buffer DiScipliNe
func! s:buf_kill(mercy)
  let l:origbuf = bufnr("%")
  let l:origbufname = bufname(l:origbuf)
  if a:mercy && &modified
    echom 'buffer has unsaved changes (use "[count]ZB" to discard changes)'
    return
  endif

  if !s:buf_switch_to_altbuff()
    "No alternate buffer found; create a new, blank buffer.
    "Note: :bwipe will still close any window that displays the buffer being
    "      wiped. To preven this, those windows would each need to be switched
    "      to a new or alt buffer.
    enew
  endif

  " remove the buffer filename (if any) from the args list, else it might come back in the next session.
  if !empty(l:origbufname)
    silent! exe 'argdelete '.l:origbufname
  endif
  " obliterate the buffer and all of its related state (marks, local options, ...), 
  if bufexists(l:origbuf) "some other mechanism may have deleted the buffer already.
    exe 'bwipeout! '.l:origbuf
  endif
endf

nnoremap <silent> <c-^> :<c-u>if !<sid>buf_switch_to_altbuff()
      \<bar>echohl WarningMsg<bar>echo "No other buffers"<bar>echohl None<bar>endif<cr>

"move to last character 
nnoremap - $
xnoremap - $
onoremap - $

nnoremap <c-cr> -
xnoremap <c-cr> -
onoremap <c-cr> -

" un-join (split) the current line at the cursor position
nnoremap gj i<c-j><esc>k$
" vaporize delete without overwriting the default register
nnoremap vd "_d
xnoremap x  "_d
nnoremap vD "_D
xnoremap P  "0p

func! s:trimws_ml(s) "trim whitespace across multiple lines
  return substitute(a:s, '^\_s*\(.\{-}\)\_s*$', '\1', '')
endf
"why?
" - repeatable
" - faster/more convenient than visual-replace
" - does not modify ' mark
" - DWIM behavior for linewise => characterwise
let s:rr_reg = '"'
func! s:set_reg(reg_name)
  let s:rr_reg = a:reg_name
endf
func! s:replace_without_yank(type)
  let rr_orig = getreg(s:rr_reg, 1) "save registers and types to restore later.
  let rr_type = getregtype(s:rr_reg)
  let ur_orig = getreg('"', 1)
  let ur_type = getregtype('"')
  let sel_save = &selection
  let &selection = "inclusive"
  let replace_curlin = (1==col("'[") && (col('$')==1 || col('$')==(col("']")+1)) && line("'[")==line("']"))

  if a:type ==? 'line' || replace_curlin
    exe "keepjumps normal! '[V']\"".s:rr_reg."p"
  elseif a:type ==? 'block'
    exe "keepjumps normal! `[\<C-V>`]\"".s:rr_reg."p"
  else
    "DWIM: if pasting linewise contents in a _characterwise_ motion, trim
    "      surrounding whitespace from the content to be pasted.
    if rr_type ==# "V"
      call setreg(s:rr_reg, s:trimws_ml(rr_orig), "v")
    endif
    exe "keepjumps normal! `[v`]\"".s:rr_reg."p"
  endif

  let &selection = sel_save
  call setreg('"',      ur_orig, ur_type)
  call setreg(s:rr_reg, rr_orig, rr_type)
endf

nnoremap <silent> dr  :<C-u>call <sid>set_reg(v:register)<bar>set opfunc=<sid>replace_without_yank<CR>g@
nnoremap <silent> drr :<C-u>call <sid>set_reg(v:register)<cr>0:<C-u>set opfunc=<sid>replace_without_yank<CR>g@$

inoremap jk <esc>
inoremap kj <esc>
" from tpope vimrc
inoremap <M-o> <C-O>o
inoremap <M-O> <C-O>O
inoremap <silent> <C-G><C-T> <C-R>=repeat(complete(col('.'),map(["%Y-%m-%d %H:%M:%S","%a, %d %b %Y %H:%M:%S %z","%Y %b %d","%d-%b-%y","%a %b %d %T %Z %Y"],'strftime(v:val)')+[localtime()]),0)<CR>

nnoremap z. :w<cr>
nnoremap z<space> :enew<cr>
xnoremap z<space> :enew<cr>

func! s:reload_without_jank()
  let w=winsaveview()
  e
  call winrestview(w)
endf
nnoremap r<bs> :call <sid>reload_without_jank()<cr>

" map m-] to be the inverse of c-]
nnoremap <m-]> <c-t>

" select last inserted text
nnoremap gV `[v`]

nnoremap cg* *``cgn

" replay macro for each line of a visual selection
xnoremap @q :normal @q<CR>
xnoremap @@ :normal @@<CR>
" repeat last command for each line of a visual selection
xnoremap . :normal .<CR>
" disable Ex mode key and map it to something awesome
nnoremap Q @@
xnoremap Q :normal @@<CR>
" repeat the last edit on the next [count] matches.
nnoremap <m-n> :normal n.<cr>

" augroup vimrc_qompose
"   autocmd!
" augroup END
" nnoremap ,
"       \ :<c-u>let g:qompose_orig_z=@z<cr>
"       \ qz
"       \ :<c-u>autocmd vimrc_qompose TextChanged,InsertLeave * exe 'normal! q'<bar>call repeat#set(@z)<bar>let @z=g:qompose_orig_z<bar>autocmd! vimrc_qompose *<cr>

"j,k move by screen line instead of file line
nnoremap j gj
nnoremap k gk
xnoremap j gj
xnoremap k gk
inoremap <Down> <C-o>gj
inoremap <Up>   <C-o>gk

" disable F1 help key
noremap! <F1> <nop>
noremap <F1> <nop>

nnoremap <expr> <c-w><c-q>  (v:count ? ':<c-u>confirm qa<cr>' : '<c-w><c-q>')
nnoremap <expr> <c-w>q      (v:count ? ':<c-u>confirm qa<cr>' : '<c-w><c-q>')
nnoremap <expr> ZZ          (v:count ? ':<c-u>xa!<cr>' : '@_ZZ')
nnoremap <expr> ZQ          (v:count ? ':<c-u>qa!<cr>' : '@_ZQ')
nnoremap <expr> <c-w>=      (v:count ? ':<c-u>windo set nowinfixheight nowinfixwidth<cr><c-w>=' : '@_<c-w>=')

func! ReadExCommandOutput(newbuf, cmd)
  redir => l:message
  silent! execute a:cmd
  redir END
  if a:newbuf | wincmd n | endif
  silent put=l:message
endf
command! -nargs=+ -bang -complete=command R call ReadExCommandOutput(<bang>1, <q-args>)
inoremap <c-r>R <c-o>:<up><home>R! <cr>

func! s:get_visual_selection_list()
  let [lnum1, col1] = getpos("'<")[1:2]
  let [lnum2, col2] = getpos("'>")[1:2]
  let lines = getline(lnum1, lnum2)
  let lines[-1] = lines[-1][: col2 - (&selection ==? 'inclusive' ? 1 : 2)]
  let lines[0] = lines[0][col1 - 1:]
  return lines
endf

func! s:get_visual_selection_searchpattern()
  let lines = s:get_visual_selection_list()
  let lines = map(lines, 'escape(v:val, ''/\'')')
  " Join with a _literal_ \n to make a valid search pattern.
  return join(lines, '\n')
endf

"read last visual-selection into command line
cnoremap <c-r><c-v> <c-r>=join(<sid>get_visual_selection_list(), " ")<cr>
inoremap <c-r><c-v> <c-r>=join(<sid>get_visual_selection_list(), " ")<cr>

"read the current line into command line
cnoremap <c-r><c-l> <c-r>=getline('.')<cr>

xmap * <esc>/\V<c-r>=<sid>get_visual_selection_searchpattern()<cr><cr><Plug>Pulse
nmap <silent> *  :<c-u>let @/='\V\<'.escape(expand('<cword>'), '/\').'\>'<bar>set hlsearch<cr>
nmap <silent> g* :<c-u>let @/='\V' . escape(expand('<cword>'), '/\')     <bar>set hlsearch<cr>

hi MarkLine guibg=darkred guifg=gray ctermbg=9 ctermfg=15
func! s:markline()
  let b:vimrc_markedlines = get(b:, "vimrc_markedlines", {})
  "TODO: This will get stale if the line moves.
  "      :sign is a solution, but need to create a way to get un-used sign {id}s.
  let b:vimrc_markedlines[line('.')] = matchaddpos("MarkLine", [line('.')])
endf
nnoremap <silent> m.  :call <sid>markline()<cr>
nnoremap <silent> m<space> :call matchdelete(b:vimrc_markedlines[line('.')])<cr>

nnoremap gow :Start "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe" --no-proxy-server "%:p"<cr>

" }}} mappings

" python ======================================================================
augroup vimrc_python
  autocmd!
  autocmd FileType python syn keyword pythonDecorator True None False self | setlocal nosmartindent tabstop=4
  let g:jedi#force_py_version = 3
  let g:jedi#auto_vim_configuration = 0
  let g:jedi#goto_assignments_command = 'gd'
  let g:jedi#goto_definitions_command = 'gD'
  let g:jedi#rename_command = 'crn'
  let g:jedi#usages_command = 'gr'
augroup END

" java ========================================================================
" gradle makeprg/quickfix settings:
"   https://github.com/luciano-fiandesio/dotfiles/blob/master/.vim/compiler/gradle.vim
augroup vimrc_java
  autocmd!
  autocmd FileType java setlocal tabstop=4 shiftwidth=4 noexpandtab copyindent softtabstop=0 nolist
  if s:has_eclim
    autocmd FileType java nnoremap <buffer> gd :<c-u>JavaSearchContext<cr>
          \| nnoremap <buffer> <silent> gI :<c-u>JavaSearch -x implementors -s workspace<cr>
          \| nnoremap <buffer> <c-t> :<c-u>JavaHierarchy<cr>
          \| nnoremap <buffer> cri   :<c-u>JavaImportOrganize<cr>
          \| nnoremap <buffer> K     :<c-u>JavaDocPreview<cr>
          \| nnoremap <buffer> <bs>  :<c-u>JavaCorrect<cr>
  endif
augroup END


" golang ======================================================================
" code search:
"    https://sourcegraph.com/code.google.com/p/go/tree
" code navigation/inspection(!!!):
"   https://github.com/AndrewRadev/go-oracle.vim
augroup vimrc_golang
  autocmd!
  autocmd FileType go iabbrev <buffer> err- if err != nil {<C-j>log.Fatal(err)<C-j>}<C-j>
  autocmd FileType go setlocal tabstop=4 shiftwidth=4 noexpandtab copyindent softtabstop=0 nolist

  if exists("$GOPATH")
    let s:gopaths = split($GOPATH, ':')
    for s:gopath in s:gopaths
      "set up Golint    https://github.com/golang/lint
      if isdirectory(s:gopath."/src/github.com/golang/lint/misc/vim")
        exe 'set runtimepath+='.s:gopath.'/src/github.com/golang/lint/misc/vim'
        autocmd BufWritePost,FileWritePost *.go execute 'Lint' | cwindow
        break
      endif
    endfor
  endif
augroup END


" A massively simplified take on https://github.com/chreekat/vim-paren-crosshairs
func! s:matchparen_cursorcolumn_setup()
  augroup matchparen_cursorcolumn
    autocmd!
    autocmd CursorMoved * if get(w:, "paren_hl_on", 0) | set cursorcolumn | else | set nocursorcolumn | endif
    autocmd InsertEnter * set nocursorcolumn
  augroup END
endf
if 0 && !&cursorcolumn
  augroup matchparen_cursorcolumn_setup
    autocmd!
    " - Add the event _only_ if matchparen is enabled.
    " - Event must be added _after_ matchparen loaded (so we can react to w:paren_hl_on).
    autocmd CursorMoved * if exists("#matchparen#CursorMoved") | call <sid>matchparen_cursorcolumn_setup() | endif
          \ | autocmd! matchparen_cursorcolumn_setup
  augroup END
endif

augroup vimrc_savecommitmsg
  autocmd!
  " Remember last commit message for fugitive commit editor
  func! s:store_commit_msg()
    let [w,r]=[winsaveview(),getreg('"', 1)]
    let @c=''
    silent! 1;/^#/-1 g/.*/y C
    if 0 <= match(@c, '[^ \t\n\r]')
      let g:LAST_COMMIT_MSG=@c
    endif
    call winrestview(w)
    call setreg('"', r)
  endf
  autocmd BufEnter COMMIT_EDITMSG
        \ exe 'au! vimrc_savecommitmsg * <buffer>' | autocmd vimrc_savecommitmsg TextChanged,TextChangedI <buffer> silent call <sid>store_commit_msg()
augroup END

augroup vimrc_autocmd
  autocmd!

  " Closes the current quickfix list and returns to the alternate window.
  func! s:close_qflist()
    let altwin = s:get_alt_winnr()
    wincmd c
    exe altwin.'wincmd w'
    " let [win_cnt, last_win] = [winnr('$'), winnr() == winnr('$')]
    " if last_win "If quickfix window is open, it is _always_ the last window.
    "   cclose
    "   if win_cnt == winnr('$')
    "     lclose " :cclose didn't change win count; that means we were in loclist.
    "   end
    " else
    "   lclose
    " endif
  endf
  autocmd FileType qf nnoremap <buffer> <c-p> <up>
        \|nnoremap <buffer> <c-n> <down>
        \|nnoremap <silent><buffer> q :call <sid>close_qflist()<cr>

  autocmd CmdwinEnter * nnoremap <silent><buffer> q <C-W>c

  " Jump to the last position when reopening a file (except Git commit)
  autocmd BufReadPost * if @% !~# '\.git[\/\\]COMMIT_EDITMSG$' && line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g`\"" | endif

  autocmd BufNewFile,BufRead *.txt,README,INSTALL,NEWS,TODO if &ft == ""|set ft=text|endif
  autocmd FileType text setlocal tabstop=4 shiftwidth=4 textwidth=80
  autocmd FileType gitconfig setlocal commentstring=#\ %s

  autocmd FileType css set omnifunc=csscomplete#CompleteCSS

  " syntaxcomplete provides basic completion for filetypes that lack a custom one.
  "   :h ft-syntax-omni
  if has("autocmd") && exists("+omnifunc")
    autocmd Filetype * if &omnifunc == "" | setlocal omnifunc=syntaxcomplete#Complete | endif
  endif

  if exists("*mkdir") "auto-create directories for new files
    au BufWritePre,FileWritePre * call EnsureDir('<afile>:p:h')
  endif

  "when Vim starts in diff-mode (vim -d, git mergetool):
  "  - do/dp should not auto-fold
  "  - tweak CursorLine to be less broken
  autocmd VimEnter * if &diff | exe 'windo set foldmethod=manual' | call <sid>set_CursorLine() | endif
  autocmd WinEnter * call <sid>set_CursorLine()

  autocmd BufRead,BufNewFile *.{ascx,aspx} setlocal tabstop=4 shiftwidth=4 copyindent

  if s:is_windows
    " always maximize initial GUI window size
    autocmd GUIEnter * simalt ~x
  endif
augroup END

nnoremap \b    :buffer<space>
" _opt-in_ to sloppy-search https://github.com/neovim/neovim/issues/3209#issuecomment-133183790
nnoremap \f    :edit **/
nnoremap \t    :tag<space>
nnoremap \\\ mS:<c-u>noau vimgrep /\C/j **<left><left><left><left><left>
" search all file buffers (clear loclist first).
nnoremap \\b mS:<c-u>lexpr []<bar>exe 'bufdo silent! noau lvimgrepadd/\C/j %'<bar>lopen<s-left><left><left><left>
" search current buffer and open results in quickfix window
nnoremap \\a. ms:<c-u>lvimgrep  % <bar>lw<s-left><left><left><left>
" search-replace
nnoremap gsa. ms:<c-u>OverCommandLine<cr>%s/
xnoremap gs   ms:OverCommandLine<cr>s/\%V
" recursively search for word under cursor (:noau speeds up vimgrep)
nnoremap \\*  mS:<c-u>noau vimgrep /\C\V<c-r><c-w>/j **<cr>
xnoremap \\*  mS:<c-u>noau vimgrep /\C<c-r>=<SID>get_visual_selection_searchpattern()<cr>/j **<cr>

" show :ilist or ]I results in the quickfix window
function! s:ilist_qf(start_at_cursor)
  redir => output
    silent! exec 'normal! '.(a:start_at_cursor ? ']I' : '[I')
  redir END
  let lines = split(output, '\n')
  if lines[0] =~? '^Error detected'
    echomsg "Could not find the word in file"
    return
  endif
  let [filename, line_info] = [lines[0], lines[1:-1]]
  "turn the :ilist output into a quickfix dictionary
  let qf_entries = map(line_info, "{
        \ 'filename': filename,
        \ 'lnum': split(v:val)[1],
        \ 'text': getline(split(v:val)[1])
        \ }")
  call setqflist(qf_entries)
  cwindow
endfunction
nnoremap <silent> [I :call <sid>ilist_qf(0)<CR>
nnoremap <silent> ]I :call <sid>ilist_qf(1)<CR>

" =============================================================================
" autocomplete / omnicomplete / tags
" =============================================================================
" Don't scan includes (tags file is more performant).
set complete-=i
set completeopt-=preview

set wildignore+=tags,*/gwt-unitCache/*

" Files with these suffixes get a lower priority when matching a wildcard
set suffixes+=.aux,.log,.dvi,.bbl,.blg,.brf,.cb,.ind,.idx,.ilg,.inx,.out,.toc,.o,.obj,.dll,.class,.pyc,.so,.swp,.zip,.exe,.jar

function! s:fzf_open_file_at_line(e)
  "Get the <path>:<line> tuple; fetch.vim plugin will handle the rest.
  execute 'edit' fnameescape(matchstr(a:e, '\v([^:]{-}:\d+)'))
endfunction

" search current working directory
nnoremap <silent> <m-/> :FZF<cr>
" full-text search
nnoremap <silent> g/g   :call fzf#run({'source':'git grep --line-number --color=never -v "^[[:space:]]*$"',
      \ 'sink':function('<sid>fzf_open_file_at_line')})<cr>
nnoremap <silent> g/x   :call fzf#vim#command_history(g:fzf#vim#default_layout)<cr>
nmap     <silent> <m-x> g/x
nnoremap <silent> g/l   :call fzf#vim#buffer_lines(g:fzf#vim#default_layout)<cr>
if findfile('plugin/tmuxcomplete.vim', &rtp) ==# ''
  nnoremap <silent> g/L mS:call fzf#vim#lines(g:fzf#vim#default_layout)<cr>
else
  " TODO
  " nnoremap <silent> g/L mS:Unite line:buffers tmuxcomplete/lines<CR>
  " nnoremap <silent> g/W :Unite tmuxcomplete<CR>
endif
nnoremap <silent> g/v   :Scriptnames<cr>
nnoremap <silent> gl    :ls<cr>
nnoremap <silent> <m-o> :call fzf#vim#buffer_tags(g:fzf#vim#default_layout)<cr>
nnoremap <silent> g/t   :call fzf#vim#tags(g:fzf#vim#default_layout)<cr>


" statusline  ░▒▓█ ============================================================
" show winnr iff there are >2 windows
if s:plugins_fluff
  hi NoScrollBar  guibg=black guifg=darkgrey ctermbg=0 ctermfg=darkgrey gui=NONE cterm=NONE
  set statusline=%{winnr('$')>2?winnr():''}\ %<%f\ %h%m%*%r\ %=%#NoScrollBar2#%P%*%#NoScrollBar#%{noscrollbar#statusline(20,'\ ','▒',['▐'],['▌'])}%*\ %{strlen(&fenc)?&fenc:&enc}\ %{(&ff==#'unix')?'':(&ff==#'dos')?'CRLF':&ff}\ %y\ %-10.(%l,%c%V%)
else
  set statusline=
endif

" Slides plugin {{{
func! SlidesStatusline()
  " echo substitute(substitute(expand('%:p:t:r'), '\v(\d+-)|_', ' ', 'g'), '\v(\W)(\w)', '\=submatch(1).toupper(submatch(2))', 'g')
  let section_dot_subsection = substitute(expand('%:p:t:r'), '\v(\d+)-(\d+).*', '\=(0+submatch(1)).".".(0+submatch(2))', '')
  let title  = substitute(expand('%:p:t:r'), '\v(\d+-)|_', ' ', 'g')
  if len(section_dot_subsection) < 6
    "pad with leading spaces
    let section_dot_subsection = repeat(' ', 7 - len(section_dot_subsection))
          \ . section_dot_subsection
  endif
  return section_dot_subsection.'        '.title
endf
func! StartSlides()
  let g:oldstatusline = get(g:, 'oldstatusline', &statusline)
  let g:oldguifont = get(g:, 'oldguifont', &guifont)
  set statusline=%{SlidesStatusline()}
  set guifont=Consolas:h32 cmdheight=1 nocursorline background=light

  autocmd! BufReadPost

  hi Normal guibg=white guifg=black
  hi StatusLine guibg=#000000 guifg=#ffffff

  nmap <right> ]f:echo ''<bar>redraw<cr>
  nmap <left>  [f:echo ''<bar>redraw<cr>
  sign unplace *
  augroup vimrc_slides
    autocmd!
    autocmd BufEnter,WinEnter * set colorcolumn=54,67 textwidth=66 | silent! call sy#stop(bufnr('%'))
    autocmd SwapExists * let v:swapchoice='e'
  augroup END

  "faster ]f [f
  set noshelltemp
endf
func! EditSlides()
  cd ~/Desktop/git_slides/

  silent! let &statusline = g:oldstatusline
  silent! let &guifont = g:oldguifont
  hi SlidesSign guibg=white guifg=black ctermbg=black ctermfg=white gui=NONE cterm=NONE
  sign define limit  text== texthl=SlidesSign

  augroup vimrc_slides
    autocmd!
    autocmd BufEnter,WinEnter * set colorcolumn=54,67 textwidth=53
    autocmd TextChanged,TextChangedI * exe 'sign unplace *'
          \ |exe 'sign place 123 line=14 name=limit buffer='.bufnr('%')
          \ |exe 'sign place 124 line=17 name=limit buffer='.bufnr('%')
    autocmd User DirvishEnter map <buffer> <down> jpp<c-w>p|map <buffer> <up> kpp<c-w>p
  augroup END

  hi ColorColumn guibg=#555555 guifg=#ffffff
  set cmdheight=2

  "faster ]f [f
  set noshelltemp
endf
" }}}

set title
set titlestring=%{getcwd()}
set titleold=?

" =============================================================================
"ensure transient dirs
let s:dir = empty($XDG_DATA_HOME) ? '~/.local/share/vim' : $XDG_DATA_HOME.'/vim'
call EnsureDir(s:dir)

if isdirectory(expand(s:dir, 1))
  call EnsureDir(s:dir . '/swap/')
  call EnsureDir(s:dir . '/backup/')
  call EnsureDir(s:dir . '/undo/')

  if &directory =~# '^\.,'
    let &directory = expand(s:dir, 1) . '/swap//,' . &directory
  endif
  if &backupdir =~# '^\.,'
    let &backupdir = expand(s:dir, 1) . '/backup//,' . &backupdir
  endif
  if has("persistent_undo") && &undodir =~# '^\.\%(,\|$\)'
    let &undodir = expand(s:dir, 1) . '/undo//,' . &undodir
    set undofile
  endif
endif

" special-purpose mappings/commands ===========================================
nnoremap <leader>vft  :e ~/.vim/ftplugin<cr>
nnoremap <leader>vv   :e ~/.vimrc<cr>
command! DateInsert           norm! i<c-r>=strftime('%Y/%m/%d %H:%M:%S')<cr>
command! DateInsertYYYYMMdd   norm! i<c-r>=strftime('%Y%m%d')<cr>
command! CdNotes        tabnew<bar>exe 'e '.finddir("notes", expand('~').'/Desktop/github,'.expand('~').'/dev')<bar>lcd %
command! FindLibUV      tabnew<bar>exe 'e '.finddir(".deps/build/src/libuv", expand("~")."/neovim/**,".expand("~")."/dev/neovim/**")<bar>lcd %
command! FindNvimDeps   tabnew<bar>exe 'e '.finddir(".deps", expand("~")."/neovim/**,".expand("~")."/dev/neovim/**")<bar>lcd %
command! FindVim        tabnew<bar>exe 'e '.finddir(".vim-src", expand("~")."/neovim/**,".expand("~")."/dev/neovim/**")<bar>lcd %
command! ProfileVim     exe 'Start '.v:progpath.' --startuptime "'.expand("~/vimprofile.txt").'" -c "e ~/vimprofile.txt"'
command! NvimCtags      call jobstart("ctags", 'ctags',
      \ ['-R'
      \ , '-I', 'FUNC_ATTR_MALLOC'
      \ , '-I', 'FUNC_ATTR_ALLOC_SIZE+'
      \ , '-I', 'FUNC_ATTR_ALLOC_SIZE_PROD+'
      \ , '-I', 'FUNC_ATTR_ALLOC_ALIGN+'
      \ , '-I', 'FUNC_ATTR_PURE'
      \ , '-I', 'FUNC_ATTR_CONST'
      \ , '-I', 'FUNC_ATTR_WARN_UNUSED_RESULT'
      \ , '-I', 'FUNC_ATTR_ALWAYS_INLINE'
      \ , '-I', 'FUNC_ATTR_UNUSED'
      \ , '-I', 'FUNC_ATTR_NONNULL_ALL'
      \ , '-I', 'FUNC_ATTR_NONNULL_ARG+'
      \ , '-I', 'FUNC_ATTR_NONNULL_RET'
      \ , '.'])
command! NvimGDB      call s:tmux_run(1, 1, 'sudo gdb -q -tui $(which '.v:progpath.') '.getpid())
command! NvimTestScreenshot put =\"local Screen = require('test.functional.ui.screen')\nlocal screen = Screen.new()\nscreen:attach()\nscreen:snapshot_util({},true)\"

xnoremap <leader>{ <esc>'<A {`>o}==`<

silent! source ~/.vimrc.local
