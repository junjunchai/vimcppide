" Buffer的位置和大小
winpos 300 100
set lines=28
set columns=90

" 因为设定为不换行，所以要显示底部滚动条，不显示左右滚动条和工具栏
set guioptions-=b
set guioptions-=r
set guioptions-=l
set guioptions-=T

" 设定颜色方案和字体
" 英文用Consolas显示，中文用微软雅黑
set guifont=Monaco:h18
set guifontset=STHeiti:h18
colorscheme inkpot
highlight PmenuSel ctermbg=7 guibg=DarkBlue guifg=White
highlight PmenuSbar ctermbg=7 guibg=DarkGray
highlight PmenuThumb guibg=Black
highlight Pmenu guifg=#333333 guibg=lightblue ctermbg=13
highlight StatusLine guifg=lightblue guibg=#333333
highlight StatusLineNC guifg=Gray guibg=White

" 用浅色高亮当前行
autocmd InsertLeave * se nocul
autocmd InsertEnter * se cul

if has("autocmd")
	autocmd FileType text,xml,html,perl,shell,bash,python,vim,php,ruby color blackboard
endif " has("autocmd")

autocmd BufWinEnter *.tex imap <F9> <Esc>:silent !lss &<cr>a

"字典
"set keywordprg=~/Apps/dicty
:inoremap <C-f> <esc>:!~/.vim/Apps/dictygui <cWORD><cr>
