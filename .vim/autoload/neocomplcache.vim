"=============================================================================
" FILE: neocomplcache.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 29 May 2010
" License: MIT license  {{{
"     Permission is hereby granted, free of charge, to any person obtaining
"     a copy of this software and associated documentation files (the
"     "Software"), to deal in the Software without restriction, including
"     without limitation the rights to use, copy, modify, merge, publish,
"     distribute, sublicense, and/or sell copies of the Software, and to
"     permit persons to whom the Software is furnished to do so, subject to
"     the following conditions:
"
"     The above copyright notice and this permission notice shall be included
"     in all copies or substantial portions of the Software.
"
"     THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
"     OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
"     MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
"     IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
"     CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
"     TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
"     SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
" }}}
" Version: 4.30, for Vim 7.0
"=============================================================================

" Check vimproc.
let s:is_vimproc = exists('*vimproc#system')

function! neocomplcache#enable() "{{{
  augroup neocomplcache "{{{
    autocmd!
    " Auto complete events
    autocmd CursorMovedI * call s:on_moved_i()
    autocmd CursorHoldI * call s:on_hold_i()
    autocmd InsertEnter * call s:on_insert_enter()
    autocmd InsertLeave * call s:on_insert_leave()
    autocmd GUIEnter * set vb t_vb=
  augroup END "}}}

  " Initialize"{{{
  let s:complete_lock = {}
  let s:complfuncs_func_table = []
  let s:global_complfuncs = {}
  let s:cur_keyword_pos = -1
  let s:cur_keyword_str = ''
  let s:complete_words = []
  let s:old_cur_keyword_pos = -1
  let s:quickmatch_keywordpos = -1
  let s:old_complete_words = []
  let s:update_time = &updatetime
  let s:prev_numbered_list = []
  let s:cur_text = ''
  let s:old_cur_text = ''
  let s:changedtick = b:changedtick
  let s:used_match_filter = 0
  "}}}

  " Initialize complfuncs table."{{{
  " Search autoload.
  let l:func_list = split(globpath(&runtimepath, 'autoload/neocomplcache/complfunc/*.vim'), '\n')
  for list in l:func_list
    let l:func_name = fnamemodify(list, ':t:r')
    if !has_key(g:NeoComplCache_DisablePluginList, l:func_name) || 
          \ g:NeoComplCache_DisablePluginList[l:func_name] == 0
      let s:global_complfuncs[l:func_name] = 'neocomplcache#complfunc#' . l:func_name . '#'
    endif
  endfor
  "}}}

  " Initialize keyword patterns."{{{
  if !exists('g:NeoComplCache_KeywordPatterns')
    let g:NeoComplCache_KeywordPatterns = {}
  endif
  call neocomplcache#set_variable_pattern('g:NeoComplCache_KeywordPatterns', 'default',
        \'\k\+')
  if has('win32') || has('win64')
    call neocomplcache#set_variable_pattern('g:NeoComplCache_KeywordPatterns', 'filename',
          \'\%(\\[^[:alnum:].-]\|[[:alnum:]:@/._+#$%~-]\)\+')
  else
    call neocomplcache#set_variable_pattern('g:NeoComplCache_KeywordPatterns', 'filename',
          \'\%(\\[^[:alnum:].-]\|[[:alnum:]@/._+#$%~-]\)\+')
  endif
  call neocomplcache#set_variable_pattern('g:NeoComplCache_KeywordPatterns', 'lisp,scheme,clojure,int-gosh,int-clisp,int-clojure', 
        \'[[:alnum:]+*@$%^&_=<>~.-]\+[!?]\?')
  call neocomplcache#set_variable_pattern('g:NeoComplCache_KeywordPatterns', 'ruby,int-irb',
        \'^=\%(b\%[egin]\|e\%[nd]\)\|\%(@@\|[:$@]\)\h\w*\|\%(\.\|\%(\h\w*::\)\+\)\?\h\w*[!?]\?\%(\s*\%(\%(()\)\?\s*\%(do\|{\)\%(\s*|\)\?\|()\?\)\)\?')
  call neocomplcache#set_variable_pattern('g:NeoComplCache_KeywordPatterns', 'eruby',
        \'\v\</?%([[:alnum:]_-]+\s*)?%(/?\>)?|%(\@\@|[:$@])\h\w*|%(\.|%(\h\w*::)+)?\h\w*[!?]?%(\s*%(%(\(\))?\s*%(do|\{)%(\s*\|)?|\(\)?))?')
  call neocomplcache#set_variable_pattern('g:NeoComplCache_KeywordPatterns', 'php',
        \'</\?\%(\h[[:alnum:]_-]*\s*\)\?\%(/\?>\)\?\|\$\h\w*\|->\(\h\w*\%(\s*()\?\)\?\)\?\|\%(\h\w*::\)*\h\w*\%(\s*()\?\)\?')
  call neocomplcache#set_variable_pattern('g:NeoComplCache_KeywordPatterns', 'perl,int-perlsh',
        \'<\h\w*>\?\|[$@%&*]\h\w*\|\h\w*\%(::\h\w*\)*\%(\s*()\?\)\?\|->\h\w*')
  call neocomplcache#set_variable_pattern('g:NeoComplCache_KeywordPatterns', 'perl6,int-perl6',
        \'<\h\w*>\?\|[$@%&][!.*?]\?\h\w*\|\h\w*\%(::\h\w*\)*\%(\s*()\?\)\?\|\.\h\w*\%(()\?\)\?')
  call neocomplcache#set_variable_pattern('g:NeoComplCache_KeywordPatterns', 'vim,help',
        \'\[:\%(\h\w*:\]\)\?\|&\h[[:alnum:]_:]*\|\$\h\w*\|-\h\w*=\?\|<\h[[:alnum:]_-]*>\?\|\.\h\w*\%(()\?\)\?\|\h[[:alnum:]_:#]*\%(!\|()\?\)\?')
  call neocomplcache#set_variable_pattern('g:NeoComplCache_KeywordPatterns', 'tex',
        \'\\\a{\a\{1,2}}\|\\[[:alpha:]@][[:alnum:]@]*\%({\%([[:alnum:]:]\+\*\?}\?\)\?\)\?\|\a[[:alnum:]:]*\*\?')
  call neocomplcache#set_variable_pattern('g:NeoComplCache_KeywordPatterns', 'sh,zsh,int-zsh,int-bash,int-sh',
        \'\v\$\w+|[[:alpha:]_.-][[:alnum:]_.-]*%(\s*\[|\s*\(\)?)?')
  call neocomplcache#set_variable_pattern('g:NeoComplCache_KeywordPatterns', 'vimshell',
        \'\v\$\$?\w*|[[:alpha:]_.-][[:alnum:]_.-]*|\d+%(\.\d+)+')
  call neocomplcache#set_variable_pattern('g:NeoComplCache_KeywordPatterns', 'ps1,int-powershell',
        \'\v\[\h%([[:alnum:]_.]*\]::)?|[$%@.]?[[:alpha:]_.:-][[:alnum:]_.:-]*%(\s*\(\)?)?')
  call neocomplcache#set_variable_pattern('g:NeoComplCache_KeywordPatterns', 'c',
        \'\v^\s*#\s*\h\w*|%(\.|-\>)?\h\w*%(\s*\(\)?)?')
  call neocomplcache#set_variable_pattern('g:NeoComplCache_KeywordPatterns', 'cpp',
        \'\v^\s*#\s*\h\w*|%(\.|-\>|%(\h\w*::)+)?\h\w*%(\s*\(\)?|\<\>?)?')
  call neocomplcache#set_variable_pattern('g:NeoComplCache_KeywordPatterns', 'objc',
        \'\v^\s*#\s*\h\w*|%(\.|-\>)?\h\w*%(\s*\(\)?|\<\>?|:)?|\@\h\w*%(\s*\(\)?)?|\(\h\w*\s*\*?\)?')
  call neocomplcache#set_variable_pattern('g:NeoComplCache_KeywordPatterns', 'objcpp',
        \'\v^\s*#\s*\h\w*|%(\.|-\>|%(\h\w*::)+)?\h\w*%(\s*\(\)?|\<\>?|:)?|\@\h\w*%(\s*\(\)?)?|\(\s*\h\w*\s*\*?\s*\)?')
  call neocomplcache#set_variable_pattern('g:NeoComplCache_KeywordPatterns', 'd',
        \'\v[.]?\h\w*%(!?\s*\(\)?)?')
  call neocomplcache#set_variable_pattern('g:NeoComplCache_KeywordPatterns', 'python,int-python,int-ipython',
        \'\v[.]?\h\w*%(\s*\(\)?)?')
  call neocomplcache#set_variable_pattern('g:NeoComplCache_KeywordPatterns', 'cs',
        \'\v[.]?\h\w*%(\s*%(\(\)?|\<))?')
  call neocomplcache#set_variable_pattern('g:NeoComplCache_KeywordPatterns', 'java',
        \'\v[@.]?\h\w*%(\s*%(\(\)?|\<))?')
  call neocomplcache#set_variable_pattern('g:NeoComplCache_KeywordPatterns', 'javascript,actionscript',
        \'\v[.]?\h\w*%(\s*\(\)?)?')
  call neocomplcache#set_variable_pattern('g:NeoComplCache_KeywordPatterns', 'awk',
        \'\v\h\w*%(\s*\(\)?)?')
  call neocomplcache#set_variable_pattern('g:NeoComplCache_KeywordPatterns', 'haskell,int-ghci',
        \'[[:alpha:]_''][[:alnum:]_'']*')
  call neocomplcache#set_variable_pattern('g:NeoComplCache_KeywordPatterns', 'ml,ocaml,int-ocaml,int-sml,int-smlsharp',
        \'[''`#.]\?\h[[:alnum:]_'']*')
  call neocomplcache#set_variable_pattern('g:NeoComplCache_KeywordPatterns', 'erlang,int-erl',
        \'\v^\s*-\h\w*[(]?|\h\w*%(:\h\w*)*%(\.|\(\)?)?')
  call neocomplcache#set_variable_pattern('g:NeoComplCache_KeywordPatterns', 'html,xhtml,xml,markdown',
        \'</\?\%([[:alnum:]_:-]\+\s*\)\?\%(/\?>\)\?\|&\h\%(\w*;\)\?\|\h[[:alnum:]_-]*="\%([^"]*"\?\)\?\|\h[[:alnum:]_:-]*')
  call neocomplcache#set_variable_pattern('g:NeoComplCache_KeywordPatterns', 'css',
        \'\v[[:alpha:]_-][[:alnum:]_-]*[:(]?|[@#:.][[:alpha:]_-][[:alnum:]_-]*')
  call neocomplcache#set_variable_pattern('g:NeoComplCache_KeywordPatterns', 'tags',
        \'\v^[^!][^/[:blank:]]*')
  call neocomplcache#set_variable_pattern('g:NeoComplCache_KeywordPatterns', 'pic',
        \'\v^\s*#\h\w*|\h\w*')
  call neocomplcache#set_variable_pattern('g:NeoComplCache_KeywordPatterns', 'masm',
        \'\v\.\h\w*|[[:alpha:]_@?$][[:alnum:]_@?$]*')
  call neocomplcache#set_variable_pattern('g:NeoComplCache_KeywordPatterns', 'nasm',
        \'\v^\s*\[\h\w*|[%.]?\h\w*|%(\.\.\@?|\%[%$!])%(\h\w*)?')
  call neocomplcache#set_variable_pattern('g:NeoComplCache_KeywordPatterns', 'asm',
        \'\v[%$.]?\h\w*%(\$\h\w*)?')
  call neocomplcache#set_variable_pattern('g:NeoComplCache_KeywordPatterns', 'make',
        \'\v[[:alpha:]_.-][[:alnum:]_.-]*')
  call neocomplcache#set_variable_pattern('g:NeoComplCache_KeywordPatterns', 'scala',
        \'\v[.]?\h\w*%(\s*\(\)?|\[)?')
  call neocomplcache#set_variable_pattern('g:NeoComplCache_KeywordPatterns', 'int-termtter',
        \'\h[[:alnum:]_-]*\|@[[:alnum:]_+-]\+\|\$\a\+\|#\h\w*')
  call neocomplcache#set_variable_pattern('g:NeoComplCache_KeywordPatterns', 'dosbatch,int-cmdproxy',
        \'\$\w+\|[[:alpha:]_./-][[:alnum:]_.-]*')
  call neocomplcache#set_variable_pattern('g:NeoComplCache_KeywordPatterns', 'vb',
        \'[.]\?\a[[:alnum:]]*\%(()\?\)\?\|#\a[[:alnum:]]*')
  "}}}

  " Initialize next keyword patterns."{{{
  if !exists('g:NeoComplCache_NextKeywordPatterns')
    let g:NeoComplCache_NextKeywordPatterns = {}
  endif
  call neocomplcache#set_variable_pattern('g:NeoComplCache_NextKeywordPatterns', 'perl',
        \'\h\w*>')
  call neocomplcache#set_variable_pattern('g:NeoComplCache_NextKeywordPatterns', 'perl6',
        \'\h\w*>')
  call neocomplcache#set_variable_pattern('g:NeoComplCache_NextKeywordPatterns', 'vim,help',
        \'\h\w*:\]\|\h\w*=\|[[:alnum:]_-]*>')
  call neocomplcache#set_variable_pattern('g:NeoComplCache_NextKeywordPatterns', 'tex',
        \'\h\w*\*\?[*[{}]')
  call neocomplcache#set_variable_pattern('g:NeoComplCache_NextKeywordPatterns', 'html,xhtml,xml,mkd',
        \'[[:alnum:]_:-]*>\|[^"]*"')
  "}}}

  " Initialize same file type lists."{{{
  if !exists('g:NeoComplCache_SameFileTypeLists')
    let g:NeoComplCache_SameFileTypeLists = {}
  endif
  call neocomplcache#set_variable_pattern('g:NeoComplCache_SameFileTypeLists', 'c', 'cpp')
  call neocomplcache#set_variable_pattern('g:NeoComplCache_SameFileTypeLists', 'cpp', 'c')
  call neocomplcache#set_variable_pattern('g:NeoComplCache_SameFileTypeLists', 'erb', 'ruby,html,xhtml')
  call neocomplcache#set_variable_pattern('g:NeoComplCache_SameFileTypeLists', 'html,xml', 'xhtml')
  call neocomplcache#set_variable_pattern('g:NeoComplCache_SameFileTypeLists', 'xhtml', 'html,xml')
  call neocomplcache#set_variable_pattern('g:NeoComplCache_SameFileTypeLists', 'help', 'vim')
  call neocomplcache#set_variable_pattern('g:NeoComplCache_SameFileTypeLists', 'lingr-say', 'lingr-messages,lingr-members')

  " Interactive filetypes.
  call neocomplcache#set_variable_pattern('g:NeoComplCache_SameFileTypeLists', 'int-irb', 'ruby')
  call neocomplcache#set_variable_pattern('g:NeoComplCache_SameFileTypeLists', 'int-ghci,int-hugs', 'haskell')
  call neocomplcache#set_variable_pattern('g:NeoComplCache_SameFileTypeLists', 'int-python,int-ipython', 'python')
  call neocomplcache#set_variable_pattern('g:NeoComplCache_SameFileTypeLists', 'int-gosh', 'scheme')
  call neocomplcache#set_variable_pattern('g:NeoComplCache_SameFileTypeLists', 'int-clisp', 'lisp')
  call neocomplcache#set_variable_pattern('g:NeoComplCache_SameFileTypeLists', 'int-erl', 'erlang')
  call neocomplcache#set_variable_pattern('g:NeoComplCache_SameFileTypeLists', 'int-zsh', 'zsh')
  call neocomplcache#set_variable_pattern('g:NeoComplCache_SameFileTypeLists', 'int-bash', 'bash')
  call neocomplcache#set_variable_pattern('g:NeoComplCache_SameFileTypeLists', 'int-sh', 'sh')
  call neocomplcache#set_variable_pattern('g:NeoComplCache_SameFileTypeLists', 'int-cmdproxy', 'dosbatch')
  call neocomplcache#set_variable_pattern('g:NeoComplCache_SameFileTypeLists', 'int-powershell', 'powershell')
  call neocomplcache#set_variable_pattern('g:NeoComplCache_SameFileTypeLists', 'int-perlsh', 'perl')
  call neocomplcache#set_variable_pattern('g:NeoComplCache_SameFileTypeLists', 'int-perl6', 'perl6')
  call neocomplcache#set_variable_pattern('g:NeoComplCache_SameFileTypeLists', 'int-ocaml', 'ocaml')
  call neocomplcache#set_variable_pattern('g:NeoComplCache_SameFileTypeLists', 'int-clojure', 'clojure')
  call neocomplcache#set_variable_pattern('g:NeoComplCache_SameFileTypeLists', 'int-sml,int-smlsharp', 'sml')
  "}}}

  " Initialize member prefix patterns."{{{
  if !exists('g:NeoComplCache_MemberPrefixPatterns')
    let g:NeoComplCache_MemberPrefixPatterns = {}
  endif
  call neocomplcache#set_variable_pattern('g:NeoComplCache_MemberPrefixPatterns', 'c,cpp,objc,objcpp', '^\.\|^->')
  call neocomplcache#set_variable_pattern('g:NeoComplCache_MemberPrefixPatterns', 'perl,php', '^->')
  call neocomplcache#set_variable_pattern('g:NeoComplCache_MemberPrefixPatterns', 'java,javascript,d,vim,ruby', '^\.')
  "}}}

  " Initialize ctags arguments."{{{
  if !exists('g:NeoComplCache_CtagsArgumentsList')
    let g:NeoComplCache_CtagsArgumentsList = {}
  endif
  call neocomplcache#set_variable_pattern('g:NeoComplCache_CtagsArgumentsList', 'default', '')
  call neocomplcache#set_variable_pattern('g:NeoComplCache_CtagsArgumentsList', 'vim',
        \"--extra=fq --fields=afmiKlnsStz --regex-vim='/function!? ([a-z#:_0-9A-Z]+)/\\1/function/'")
  call neocomplcache#set_variable_pattern('g:NeoComplCache_CtagsArgumentsList', 'cpp',
        \'--c++-kinds=+p --fields=+iaS --extra=+q')
  "}}}

  " Initialize quick match patterns."{{{
  if !exists('g:NeoComplCache_QuickMatchPatterns')
    let g:NeoComplCache_QuickMatchPatterns = {}
  endif
  call neocomplcache#set_variable_pattern('g:NeoComplCache_QuickMatchPatterns', 'default', '-')
  "}}}

  " Initialize tags filter patterns."{{{
  if !exists('g:NeoComplCache_TagsFilterPatterns')
    let g:NeoComplCache_TagsFilterPatterns = {}
  endif
  call neocomplcache#set_variable_pattern('g:NeoComplCache_TagsFilterPatterns', 'c,cpp', 
        \'v:val.word !~ ''^[~_]''')
  "}}}

  " Initialize plugin completion length."{{{
  if !exists('g:NeoComplCache_PluginCompletionLength')
    let g:NeoComplCache_PluginCompletionLength = {}
  endif
  "}}}

  " Add commands."{{{
  command! -nargs=0 NeoComplCacheDisable call neocomplcache#disable()
  command! -nargs=0 Neco call s:display_neco()
  command! -nargs=0 NeoComplCacheLock call s:lock()
  command! -nargs=0 NeoComplCacheUnlock call s:unlock()
  command! -nargs=0 NeoComplCacheToggle call s:toggle()
  command! -nargs=1 NeoComplCacheAutoCompletionLength let g:NeoComplCache_KeywordCompletionStartLength = <args>
  "}}}

  " Must g:NeoComplCache_StartCharLength > 1.
  if g:NeoComplCache_KeywordCompletionStartLength < 1
    let g:NeoComplCache_KeywordCompletionStartLength = 1
  endif
  " Must g:NeoComplCache_MinKeywordLength > 1.
  if g:NeoComplCache_MinKeywordLength < 1
    let g:NeoComplCache_MinKeywordLength = 1
  endif

  " Save options.
  let s:completefunc_save = &completefunc
  let s:completeopt_save = &completeopt

  " Set completefunc.
  let &completefunc = 'neocomplcache#manual_complete'
  let &l:completefunc = 'neocomplcache#manual_complete'

  " Set options.
  set completeopt-=menu
  set completeopt-=longest
  set completeopt+=menuone

  " Disable bell.
  set vb t_vb=
  
  " Initialize.
  for l:complfunc_name in keys(s:global_complfuncs)
    call call(s:global_complfuncs[l:complfunc_name] . 'initialize', [])
  endfor
endfunction"}}}

function! neocomplcache#disable()"{{{
  " Restore options.
  let &completefunc = s:completefunc_save
  let &completeopt = s:completeopt_save

  augroup neocomplcache
    autocmd!
  augroup END

  delcommand NeoComplCacheDisable
  delcommand Neco
  delcommand NeoComplCacheLock
  delcommand NeoComplCacheUnlock
  delcommand NeoComplCacheToggle
  delcommand NeoComplCacheAutoCompletionLength

  for l:complfunc_name in keys(s:global_complfuncs)
    call call(s:global_complfuncs[l:complfunc_name] . 'finalize', [])
  endfor
endfunction"}}}

function! neocomplcache#manual_complete(findstart, base)"{{{
  if a:findstart
    " Clear flag.
    let s:used_match_filter = 0
    
    let [l:cur_keyword_pos, l:cur_keyword_str, l:complete_words] = s:integrate_completion(s:get_complete_result(s:get_cur_text()))
    if empty(l:complete_words)
      return -1
    endif
    let s:complete_words = l:complete_words

    return l:cur_keyword_pos
  else
    return s:complete_words
  endif
endfunction"}}}

function! neocomplcache#auto_complete(findstart, base)"{{{
  if a:findstart
    " Check text was changed.
    let l:cached_text = s:cur_text
    if s:get_cur_text() != l:cached_text
      " Text was changed.
      
      " Restore options.
      let s:cur_keyword_pos = -1
      let &l:completefunc = 'neocomplcache#manual_complete'
      let s:old_complete_words = s:complete_words
      let s:complete_words = []
      
      return -1
    endif
    
    let s:old_cur_keyword_pos = s:cur_keyword_pos
    let s:cur_keyword_pos = -1
    return s:old_cur_keyword_pos
  else
    " Restore option.
    let &l:completefunc = 'neocomplcache#manual_complete'
    let s:old_complete_words = s:complete_words
    let s:complete_words = []

    return s:old_complete_words
  endif
endfunction"}}}

" Plugin helper."{{{
function! neocomplcache#keyword_escape(cur_keyword_str)"{{{
  " Escape."{{{
  let l:keyword_escape = escape(a:cur_keyword_str, '~" \.^$[]')
  if g:NeoComplCache_EnableWildCard
    let l:keyword_escape = substitute(substitute(l:keyword_escape, '.\zs\*', '.*', 'g'), '\%(^\|\*\)\zs\*', '\\*', 'g')
    if '-' !~ '\k'
      let l:keyword_escape = substitute(l:keyword_escape, '.\zs-', '.\\+', 'g')
    endif
  else
    let l:keyword_escape = escape(a:cur_keyword_str, '*')
  endif"}}}

  " Underbar completion."{{{
  if g:NeoComplCache_EnableUnderbarCompletion && l:keyword_escape =~ '_'
    let l:keyword_escape = substitute(l:keyword_escape, '[^_]\zs_', '[^_]*_', 'g')
  endif
  if g:NeoComplCache_EnableUnderbarCompletion && '-' =~ '\k' && l:keyword_escape =~ '-'
    let l:keyword_escape = substitute(l:keyword_escape, '[^-]\zs-', '[^-]*-', 'g')
  endif
  "}}}
  " Camel case completion."{{{
  if g:NeoComplCache_EnableCamelCaseCompletion && l:keyword_escape =~ '\u'
    let l:keyword_escape = substitute(l:keyword_escape, '\u\?\zs\U*', '\\%(\0\\l*\\|\U\0\E\\u*_\\?\\)', 'g')
  endif
  "}}}

  "echo l:keyword_escape
  return l:keyword_escape
endfunction"}}}
function! neocomplcache#keyword_filter(list, cur_keyword_str)"{{{
  if a:cur_keyword_str == ''
    return a:list
  elseif neocomplcache#check_match_filter(a:cur_keyword_str)
    let s:used_match_filter = 1
    " Match filter.
    return filter(a:list, printf("v:val.word =~ %s", 
          \string('^' . neocomplcache#keyword_escape(a:cur_keyword_str))))
  else
    " Use fast filter.
    return neocomplcache#head_filter(a:list, a:cur_keyword_str)
  endif
endfunction"}}}
function! neocomplcache#check_match_filter(cur_keyword_str, ...)"{{{
  return neocomplcache#keyword_escape(
        \empty(a:000)? a:cur_keyword_str : a:cur_keyword_str[ : a:1-1]) =~ '[^\\]\*\|\\+'
endfunction"}}}
function! neocomplcache#head_filter(list, cur_keyword_str)"{{{
  let l:cur_keyword = substitute(a:cur_keyword_str, '\\\zs.', '\0', 'g')

  let l:cur_max = len(l:cur_keyword) - 1
  let l:ret = []
  for keyword in a:list
    if l:cur_keyword == keyword.word[: l:cur_max] 
      call add(l:ret, keyword)
    endif
  endfor

  return ret
endfunction"}}}
function! neocomplcache#fuzzy_filter(list, cur_keyword_str)"{{{
  let l:ret = []
  
  let l:cur_keyword_str = a:cur_keyword_str[2:]
  let l:max_str2 = len(l:cur_keyword_str)
  let l:len = len(a:cur_keyword_str)
  let m = range(l:max_str2+1)
  for keyword in filter(a:list, 'len(v:val.word) >= '.l:max_str2)
    let l:str1 = keyword.word[2 : l:len-1]
    
    let i = 0
    while i <= l:max_str2+1
      let m[i] = range(l:max_str2+1)
      
      let i += 1
    endwhile
    let i = 0
    while i <= l:max_str2+1
      let m[i][0] = i
      let m[0][i] = i
      
      let i += 1
    endwhile
    
    let i = 1
    let l:max = l:max_str2 + 1
    while i < l:max
      let j = 1
      while j < l:max
        let m[i][j] = min([m[i-1][j]+1, m[i][j-1]+1, m[i-1][j-1]+(l:str1[i-1] != l:cur_keyword_str[j-1])])

        let j += 1
      endwhile

      let i += 1
    endwhile
    if m[-1][-1] <= 2
      call add(l:ret, keyword)
    endif
  endfor

  return ret
endfunction"}}}
function! neocomplcache#member_filter(list, cur_keyword_str)"{{{
  let l:ft = &filetype
  if l:ft == ''
    let l:ft = 'nothing'
  endif

  if has_key(g:NeoComplCache_MemberPrefixPatterns, l:ft) && a:cur_keyword_str =~ g:NeoComplCache_MemberPrefixPatterns[l:ft]
    let l:prefix = matchstr(a:cur_keyword_str, g:NeoComplCache_MemberPrefixPatterns[l:ft])
    let l:cur_keyword_str = a:cur_keyword_str[len(l:prefix) :]

    let l:ret = deepcopy(neocomplcache#keyword_filter(filter(a:list, 
          \'(has_key(v:val, "kind") && v:val.kind ==# "m") || (has_key(v:val, "class") && v:val.class != "")'), l:cur_keyword_str))
    for l:keyword in l:ret
      let l:keyword.word = l:prefix . l:keyword.word
    endfor

    return ret
  else
    return neocomplcache#keyword_filter(a:list, a:cur_keyword_str)
  endif
endfunction"}}}
function! neocomplcache#dictionary_filter(dictionary, cur_keyword_str, completion_length)"{{{
  if len(a:cur_keyword_str) < a:completion_length ||
        \neocomplcache#check_match_filter(a:cur_keyword_str, a:completion_length)
    return neocomplcache#keyword_filter(neocomplcache#unpack_dictionary(a:dictionary), a:cur_keyword_str)
  else
    let l:key = tolower(a:cur_keyword_str[: a:completion_length-1])

    if !has_key(a:dictionary, l:key)
      return []
    endif

    return (len(a:cur_keyword_str) == a:completion_length && &ignorecase)?
          \ a:dictionary[l:key] : neocomplcache#keyword_filter(copy(a:dictionary[l:key]), a:cur_keyword_str)
  endif
endfunction"}}}
function! neocomplcache#unpack_dictionary(dict)"{{{
  let l:ret = []
  for l in values(a:dict)
    let l:ret += l
  endfor

  return l:ret
endfunction"}}}
function! neocomplcache#unpack_dictionary_dictionary(dict)"{{{
  let l:ret = []
  for l in values(a:dict)
    let l:ret += values(l)
  endfor

  return l:ret
endfunction"}}}
function! neocomplcache#add_dictionaries(dictionaries)"{{{
  if empty(a:dictionaries)
    return {}
  endif

  let l:ret = a:dictionaries[0]
  for l:dict in a:dictionaries[1:]
    for [l:key, l:value] in items(l:dict)
      if has_key(l:ret, l:key)
        let l:ret[l:key] += l:value
      else
        let l:ret[l:key] = l:value
      endif
    endfor
  endfor

  return l:ret
endfunction"}}}
function! neocomplcache#used_match_filter()"{{{
  let s:used_match_filter = 1
endfunction"}}}

" RankOrder."{{{
function! neocomplcache#compare_rank(i1, i2)
  return a:i1.rank < a:i2.rank ? 1 : a:i1.rank == a:i2.rank ? 0 : -1
endfunction"}}}
" PreviousRankOrder."{{{
function! neocomplcache#compare_prev_rank(i1, i2)
  return a:i1.rank+a:i1.prev_rank < a:i2.rank+a:i2.prev_rank ? 1 :
        \a:i1.rank+a:i1.prev_rank == a:i2.rank+a:i2.prev_rank ? 0 : -1
endfunction"}}}
" AlphabeticalOrder."{{{
function! neocomplcache#compare_words(i1, i2)
  return a:i1.word > a:i2.word ? 1 : a:i1.word == a:i2.word ? 0 : -1
endfunction"}}}

function! neocomplcache#rand(max)"{{{
  let l:time = reltime()[1]
  return (l:time < 0 ? -l:time : l:time)% (a:max + 1)
endfunction"}}}
function! neocomplcache#system(str, ...)"{{{
  let l:command = a:str
  let l:input = join(a:000)
  if &termencoding != '' && &termencoding != &encoding
    let l:command = iconv(l:command, &encoding, &termencoding)
    let l:input = iconv(l:input, &encoding, &termencoding)
  endif
  let l:output = s:is_vimproc ? (a:0 == 0 ? vimproc#system(l:command) : vimproc#system(l:command, l:input))
        \: (a:0 == 0 ? system(l:command) : system(l:command, l:input))
  if &termencoding != '' && &termencoding != &encoding
    let l:output = iconv(l:output, &termencoding, &encoding)
  endif
  return l:output
endfunction"}}}

function! neocomplcache#caching_percent()"{{{
  return neocomplcache#plugin#buffer_complete#caching_percent('')
endfunction"}}}

function! neocomplcache#get_cur_text()"{{{
  " Return cached text.
  return neocomplcache#is_auto_complete()? s:cur_text : s:get_cur_text()
endfunction"}}}
function! neocomplcache#get_completion_length(plugin_name)"{{{
  if has_key(g:NeoComplCache_PluginCompletionLength, a:plugin_name)
    return g:NeoComplCache_PluginCompletionLength[a:plugin_name]
  elseif a:plugin_name == 'omni_complete' || a:plugin_name == 'vim_complete' || a:plugin_name == 'completefunc_complete'
    return 0
  else
    return g:NeoComplCache_KeywordCompletionStartLength
  endif
endfunction"}}}
function! neocomplcache#get_keyword_pattern(...)"{{{
  if a:0 == 0
    let l:filetype = (&filetype == '')?  'nothing' : &filetype
  else
    let l:filetype = a:000[0]
  endif

  let l:keyword_patterns = []
  for l:ft in split(l:filetype, '\.')
    call add(l:keyword_patterns, has_key(g:NeoComplCache_KeywordPatterns, l:ft) ?
          \ g:NeoComplCache_KeywordPatterns[l:ft] : g:NeoComplCache_KeywordPatterns['default'])
  endfor

  return join(l:keyword_patterns, '\m\|')
endfunction"}}}
function! neocomplcache#get_next_keyword_pattern(...)"{{{
  if empty(a:000)
    let l:filetype = (&filetype == '')?  'nothing' : &filetype
  else
    let l:filetype = a:000[0]
  endif

  if has_key(g:NeoComplCache_NextKeywordPatterns, l:filetype)
    return g:NeoComplCache_NextKeywordPatterns[l:filetype] . '\m\|' . neocomplcache#get_keyword_pattern(l:filetype)
  else
    return neocomplcache#get_keyword_pattern(l:filetype)
  endif
endfunction"}}}
function! neocomplcache#get_keyword_pattern_end(...)"{{{
  if empty(a:000)
    let l:filetype = (&filetype == '')?  'nothing' : &filetype
  else
    let l:filetype = a:000[0]
  endif

  return '\%('.neocomplcache#get_keyword_pattern(l:filetype).'\m\)$'
endfunction"}}}
function! neocomplcache#get_prev_word(cur_keyword_str)"{{{
  let l:keyword_pattern = neocomplcache#get_keyword_pattern()
  let l:line_part = neocomplcache#get_cur_text()[: -1-len(a:cur_keyword_str)]
  let l:prev_word_end = matchend(l:line_part, l:keyword_pattern)
  if l:prev_word_end > 0
    let l:word_end = matchend(l:line_part, l:keyword_pattern, l:prev_word_end)
    if l:word_end >= 0
      while l:word_end >= 0
        let l:prev_word_end = l:word_end
        let l:word_end = matchend(l:line_part, l:keyword_pattern, l:prev_word_end)
      endwhile
    endif

    let l:prev_word = matchstr(l:line_part[: l:prev_word_end-1], l:keyword_pattern . '$')
  else
    let l:prev_word = '^'
  endif

  return l:prev_word
endfunction"}}}
function! neocomplcache#match_word(cur_text)"{{{
  return matchstr(a:cur_text, neocomplcache#get_keyword_pattern_end())
endfunction"}}}
function! neocomplcache#match_wildcard(cur_text, pattern, cur_keyword_pos)"{{{
  let l:cur_keyword_pos = a:cur_keyword_pos

  while l:cur_keyword_pos > 1 && a:cur_text[l:cur_keyword_pos - 1] == '*'
    let l:left_text = a:cur_text[: l:cur_keyword_pos - 2]
    if l:left_text == '' || l:left_text !~ a:pattern
      break
    endif

    let l:cur_keyword_pos = match(l:left_text, a:pattern)
  endwhile

  return l:cur_keyword_pos
endfunction"}}}
function! neocomplcache#is_auto_complete()"{{{
  return &l:completefunc == 'neocomplcache#auto_complete'
endfunction"}}}
function! neocomplcache#print_caching(string)"{{{
  if g:NeoComplCache_CachingPercentInStatusline
    let &l:statusline = a:string
    redrawstatus
  else
    redraw
    echo a:string
  endif
endfunction"}}}
function! neocomplcache#print_error(string)"{{{
  echohl Error | echo a:string | echohl None
endfunction"}}}
function! neocomplcache#trunk_string(string, max)"{{{
  return printf('%.' . a:max-10 . 's..%%s', a:string, a:string[-8:])
endfunction"}}}
function! neocomplcache#head_match(checkstr, headstr)"{{{
  return a:headstr == '' || a:checkstr ==# a:headstr
        \|| a:checkstr[: len(a:headstr)-1] ==# a:headstr
endfunction"}}}
function! neocomplcache#get_source_filetypes(filetype)"{{{
  let l:filetype = a:filetype == ''? 'nothing' : a:filetype

  let l:filetype_dict = {}

  let l:filetypes = [l:filetype]
  if l:filetype =~ '\.'
    " Set compound filetype.
    let l:filetypes += split(l:filetype, '\.')
  endif

  for l:ft in l:filetypes
    let l:filetype_dict[l:ft] = 1

    " Set same filetype.
    if has_key(g:NeoComplCache_SameFileTypeLists, l:ft)
      for l:same_ft in split(g:NeoComplCache_SameFileTypeLists[l:ft], ',')
        let l:filetype_dict[l:same_ft] = 1
      endfor
    endif
  endfor

  return l:filetype_dict
endfunction"}}}
function! neocomplcache#get_sources_list(dictionary, filetype)"{{{
  let l:list = []
  for l:filetype in keys(neocomplcache#get_source_filetypes(a:filetype))
    if has_key(a:dictionary, l:filetype)
      call add(l:list, a:dictionary[l:filetype])
    endif
  endfor

  return l:list
endfunction"}}}
function! neocomplcache#escape_match(str)"{{{
  return escape(a:str, '~" \.^$[]')
endfunction"}}}

" Set pattern helper.
function! neocomplcache#set_variable_pattern(variable, filetype, pattern)"{{{
  for ft in split(a:filetype, ',')
    if !has_key({a:variable}, ft) 
      let {a:variable}[ft] = a:pattern
    endif
  endfor
endfunction"}}}

" Complete filetype helper.
function! neocomplcache#filetype_complete(arglead, cmdline, cursorpos)"{{{
  let l:list = split(globpath(&runtimepath, 'snippets/*.snip*'), '\n') +
        \split(globpath(&runtimepath, 'autoload/neocomplcache/plugin/snippets_complete/*.snip*'), '\n')
  if exists('g:NeoComplCache_SnippetsDir')
    for l:dir in split(g:NeoComplCache_SnippetsDir, ',')
      let l:dir = expand(l:dir)
      if isdirectory(l:dir)
        let l:list += split(globpath(l:dir, '*.snip*'), '\n')
      endif
    endfor
  endif
  let l:items = map(l:list, 'fnamemodify(v:val, ":t:r")')

  " Dup check.
  let l:ret = {}
  for l:item in l:items
    if !has_key(l:ret, l:item) && l:item =~ '^'.a:arglead
      let l:ret[l:item] = 1
    endif
  endfor

  return sort(keys(l:ret))
endfunction"}}}
"}}}

" Command functions."{{{
function! s:toggle()"{{{
  if !has_key(s:complete_lock, bufnr('%')) || !s:complete_lock[bufnr('%')]
    call s:lock()
  else
    call s:unlock()
  endif
endfunction"}}}
function! s:lock()"{{{
  let s:complete_lock[bufnr('%')] = 1
endfunction"}}}
function! s:unlock()"{{{
  let s:complete_lock[bufnr('%')] = 0
endfunction"}}}
function! s:display_neco()"{{{
  let l:animation = [
        \["   A A", 
        \ "~(-'_'-)"], 
        \["      A A", 
        \ "   ~(-'_'-)"], 
        \["        A A", 
        \ "     ~(-'_'-)"], 
        \["          A A  ", 
        \ "       ~(-'_'-)"], 
        \["             A A", 
        \ "          ~(-^_^-)"],
        \]

  for l:anim in l:animation
    echo ''
    redraw
    echo l:anim[0] . "\n" . l:anim[1]
    sleep 150m
  endfor
endfunction"}}}
"}}}

" Key mapping functions."{{{
" Obsolute.
function! neocomplcache#close_popup()"{{{
  return "\<C-y>"
endfunction
"}}}
function! neocomplcache#cancel_popup()"{{{
  return "\<C-e>"
endfunction"}}}

" Wrapper functions.
function! neocomplcache#manual_filename_complete()"{{{
  return neocomplcache#start_manual_complete('filename_complete')
endfunction"}}}
function! neocomplcache#manual_omni_complete()"{{{
  return neocomplcache#start_manual_complete('omni_complete')
endfunction"}}}
function! neocomplcache#manual_keyword_complete()"{{{
  return neocomplcache#start_manual_complete('keyword_complete')
endfunction"}}}

" Manual complete wrapper.
function! neocomplcache#start_manual_complete(complfunc_name)"{{{
  let l:cur_text = s:get_cur_text()
  
  " Clear flag.
  let s:used_match_filter = 0

  " Set function.
  let &l:completefunc = 'neocomplcache#manual_complete'

  if !has_key(s:global_complfuncs, a:complfunc_name)
    let l:cur_keyword_pos = neocomplcache#complfunc#keyword_complete#get_keyword_pos(l:cur_text)
    let l:cur_keyword_str = l:cur_text[l:cur_keyword_pos :]
    let l:complete_words = neocomplcache#complfunc#keyword_complete#get_manual_complete_list(a:complfunc_name)

    if empty(l:complete_words)
      return ''
    endif
  else
    let l:complfunc = s:global_complfuncs[a:complfunc_name]

    let l:cur_keyword_pos = call(l:complfunc . 'get_keyword_pos', [l:cur_text])
    if l:cur_keyword_pos < 0
      " Try append 'a'.
      let l:cur_keyword_pos = call(l:complfunc . 'get_keyword_pos', [l:cur_text.'a'])
    endif

    let l:cur_keyword_str = l:cur_text[l:cur_keyword_pos :]
    if l:cur_keyword_pos < 0 || len(l:cur_keyword_str) < g:NeoComplCache_ManualCompletionStartLength
      return ''
    endif

    " Save options.
    let l:ignorecase_save = &ignorecase

    if g:NeoComplCache_SmartCase && l:cur_keyword_str =~ '\u'
      let &ignorecase = 0
    else
      let &ignorecase = g:NeoComplCache_IgnoreCase
    endif

    let l:complete_words = s:remove_next_keyword(a:complfunc_name, deepcopy(
          \call(l:complfunc . 'get_complete_words', [l:cur_keyword_pos, l:cur_keyword_str])[: g:NeoComplCache_MaxList]))

    let &ignorecase = l:ignorecase_save
  endif

  let [s:cur_keyword_pos, s:cur_keyword_str, s:complete_words] = 
        \[l:cur_keyword_pos, l:cur_keyword_str, l:complete_words]

  " Set function.
  let &l:completefunc = 'neocomplcache#auto_complete'

  " Start complete.
  return "\<C-x>\<C-u>\<C-p>"
endfunction"}}}
function! neocomplcache#start_manual_complete_list(cur_keyword_pos, cur_keyword_str, complete_words)"{{{
  let [s:cur_keyword_pos, s:cur_keyword_str, s:complete_words] = [a:cur_keyword_pos, a:cur_keyword_str, a:complete_words]

  " Set function.
  let &l:completefunc = 'neocomplcache#auto_complete'

  " Start complete.
  return "\<C-x>\<C-u>\<C-p>"
endfunction"}}}

function! neocomplcache#undo_completion()"{{{
  if !exists(':NeoComplCacheDisable')
    return ''
  endif

  " Get cursor word.
  let l:cur_keyword_str = neocomplcache#match_word(s:get_cur_text())
  let l:old_keyword_str = s:cur_keyword_str
  let s:cur_keyword_str = l:cur_keyword_str

  return (pumvisible() ? "\<C-e>" : '')
        \ . repeat("\<BS>", len(l:cur_keyword_str)) . l:old_keyword_str
endfunction"}}}

function! neocomplcache#complete_common_string()"{{{
  if !exists(':NeoComplCacheDisable')
    return ''
  endif

  " Get cursor word.
  let l:cur_keyword_str = neocomplcache#match_word(s:get_cur_text())

  " Save options.
  let l:ignorecase_save = &ignorecase

  if g:NeoComplCache_SmartCase && l:cur_keyword_str =~ '\u'
    let &ignorecase = 0
  else
    let &ignorecase = g:NeoComplCache_IgnoreCase
  endif

  let l:complete_words = neocomplcache#keyword_filter(copy(s:old_complete_words), l:cur_keyword_str)
  if empty(l:complete_words)
    return ''
  endif

  let l:common_str = l:complete_words[0].word
  for keyword in l:complete_words[1:]
    while !neocomplcache#head_match(keyword.word, l:common_str) 
      let l:common_str = l:common_str[: -2]
    endwhile
  endfor
  if &ignorecase
    let l:common_str = tolower(l:common_str)
  endif

  let &ignorecase = l:ignorecase_save

  return (pumvisible() ? "\<C-e>" : '')
        \ . repeat("\<BS>", len(l:cur_keyword_str)) . l:common_str
endfunction"}}}
"}}}

" Event functions."{{{
function! s:on_hold_i()"{{{
  if g:NeoComplCache_EnableCursorHoldI
    call s:do_complete(0)
  endif
endfunction"}}}
function! s:on_moved_i()"{{{
  call s:do_complete(1)
endfunction"}}}
function! s:do_complete(is_moved)"{{{
  " Detect global completefunc.
  if &g:completefunc != 'neocomplcache#manual_complete' && &g:completefunc != 'neocomplcache#auto_complete'
    99verbose set completefunc
    echohl Error | echoerr 'Other plugin Use completefunc! Disabled neocomplcache.' | echohl None
    return
  endif

  " Detect AutoComplPop.
  if exists('g:acp_enableAtStartup') && g:acp_enableAtStartup
    echohl Error | echoerr 'Detected enabled AutoComplPop! Disabled neocomplcache.' | echohl None
    return
  endif
  
  if (&buftype !~ 'nofile\|nowrite' && b:changedtick == s:changedtick) || &paste
        \|| (has_key(s:complete_lock, bufnr('%')) && s:complete_lock[bufnr('%')])
        \|| g:NeoComplCache_DisableAutoComplete
        \|| (&l:completefunc != 'neocomplcache#manual_complete' && &l:completefunc != 'neocomplcache#auto_complete')
    return
  endif

  " Get cursor word.
  let l:cur_text = s:get_cur_text()
  " Prevent infinity loop.
  " Not complete multi byte character for ATOK X3.
  if l:cur_text == ''
        \ || (exists('&iminsert') && &l:iminsert)
        \ || l:cur_text == s:old_cur_text
    let s:complete_words = []
    let s:old_complete_words = []
    return
  endif

  let l:quickmatch_pattern = s:get_quickmatch_pattern()
  if g:NeoComplCache_EnableQuickMatch && l:cur_text =~ l:quickmatch_pattern.'[a-z0-9;,./]$'
    " Select quickmatch list.
    let l:complete_words = s:select_quickmatch_list(l:cur_text[-1:])
    let s:prev_numbered_list = []

    if !empty(l:complete_words)
      let s:complete_words = l:complete_words
      let s:cur_keyword_pos = s:old_cur_keyword_pos

      " Set function.
      let &l:completefunc = 'neocomplcache#auto_complete'
      call feedkeys("\<C-x>\<C-u>", 'n')
      let s:old_cur_text = l:cur_text
      return 
    endif
  elseif g:NeoComplCache_EnableQuickMatch 
        \&& !empty(s:old_complete_words)
        \&& l:cur_text =~ l:quickmatch_pattern.'$'
        \&& l:cur_text !~ l:quickmatch_pattern . l:quickmatch_pattern.'$'

    " Print quickmatch list.
    let s:cur_keyword_pos = s:old_cur_keyword_pos
    let l:cur_keyword_str = neocomplcache#match_word(l:cur_text[: -len(matchstr(l:cur_text, l:quickmatch_pattern.'$'))-1])
    let s:complete_words = s:make_quickmatch_list(s:old_complete_words, l:cur_keyword_str) 

    let &l:completefunc = 'neocomplcache#auto_complete'
    call feedkeys("\<C-x>\<C-u>\<C-p>", 'n')
    let s:old_cur_text = l:cur_text
    return
  elseif a:is_moved && g:NeoComplCache_EnableCursorHoldI
        \&& !s:used_match_filter
    " Dummy cursor move.
    call feedkeys("\<C-g>u", 'n')
    return
  endif

  let s:old_cur_text = l:cur_text
  
  " Clear flag.
  let s:used_match_filter = 0

  let l:is_quickmatch_list = 0
  let s:prev_numbered_list = []
  let s:complete_words = []
  let s:old_complete_words = []
  let s:changedtick = b:changedtick

  " Set function.
  let &l:completefunc = 'neocomplcache#auto_complete'

  " Get complete result.
  let [l:cur_keyword_pos, l:cur_keyword_str, l:complete_words] = s:integrate_completion(s:get_complete_result(l:cur_text))

  if empty(l:complete_words)
    let &l:completefunc = 'neocomplcache#manual_complete'
    let s:changedtick = b:changedtick
    let s:used_match_filter = 0
    return
  endif

  let [s:cur_keyword_pos, s:cur_keyword_str, s:complete_words] = 
        \[l:cur_keyword_pos, l:cur_keyword_str, filter(l:complete_words, 'len(v:val.word) > '.len(l:cur_keyword_str))]

  " Start auto complete.
  if g:NeoComplCache_EnableAutoSelect
    call feedkeys("\<C-x>\<C-u>\<C-p>\<Down>", 'n')
  else
    call feedkeys("\<C-x>\<C-u>\<C-p>", 'n')
  endif
  let s:changedtick = b:changedtick
endfunction"}}}
function! s:get_complete_result(cur_text)"{{{
  " Try complfuncs completion."{{{
  let l:complete_result = {}
  for [l:complfunc_name, l:complfunc] in items(s:global_complfuncs)
    let l:cur_keyword_pos = call(l:complfunc . 'get_keyword_pos', [a:cur_text])

    if !neocomplcache#is_auto_complete() && l:cur_keyword_pos < 0
      " Try append 'a'.
      let l:cur_keyword_pos = call(l:complfunc . 'get_keyword_pos', [a:cur_text.'a'])
    endif
    
    if l:cur_keyword_pos >= 0
      let l:cur_keyword_str = a:cur_text[l:cur_keyword_pos :]
      if len(l:cur_keyword_str) < neocomplcache#get_completion_length(l:complfunc_name)
        " Skip.
        continue
      endif

      " Save options.
      let l:ignorecase_save = &ignorecase

      if g:NeoComplCache_SmartCase && l:cur_keyword_str =~ '\u'
        let &ignorecase = 0
      else
        let &ignorecase = g:NeoComplCache_IgnoreCase
      endif

      let l:words = call(l:complfunc . 'get_complete_words', [l:cur_keyword_pos, l:cur_keyword_str])

      let &ignorecase = l:ignorecase_save

      if !empty(l:words)
        let l:complete_result[l:complfunc_name] = {
              \'complete_words' : l:words, 
              \'cur_keyword_pos' : l:cur_keyword_pos, 
              \'cur_keyword_str' : l:cur_keyword_str, 
              \'rank' : call(l:complfunc . 'get_rank', [])
              \}
      endif
    endif
  endfor
  "}}}
  
  return l:complete_result
endfunction"}}}
function! s:integrate_completion(complete_result)"{{{
  if empty(a:complete_result)
    return [-1, '', []]
  endif

  let l:cur_keyword_pos = col('.')
  for l:result in values(a:complete_result)
    if l:cur_keyword_pos > l:result.cur_keyword_pos
      let l:cur_keyword_pos = l:result.cur_keyword_pos
    endif
  endfor
  let l:cur_text = neocomplcache#get_cur_text()
  let l:cur_keyword_str = l:cur_text[l:cur_keyword_pos :]

  let l:frequencies = neocomplcache#plugin#buffer_complete#get_frequencies()
  let l:prev_frequencies = neocomplcache#plugin#buffer_complete#get_prev_frequencies()

  " Append prefix.
  let l:complete_words = []
  for [l:complfunc_name, l:result] in items(a:complete_result)
    let l:result.complete_words = deepcopy(l:result.complete_words)
    if l:result.cur_keyword_pos > l:cur_keyword_pos
      let l:prefix = l:cur_keyword_str[: l:result.cur_keyword_pos - l:cur_keyword_pos - 1]

      for keyword in l:result.complete_words
        let keyword.word = l:prefix . keyword.word
      endfor
    endif

    if !g:NeoComplCache_AlphabeticalOrder
      let l:rank = l:result.rank
      for l:keyword in l:result.complete_words
        let l:word = l:keyword.word
        let l:keyword.rank = has_key(l:frequencies, l:word)? l:rank * l:frequencies[l:word] : l:rank
        let l:keyword.prev_rank = has_key(l:prev_frequencies, l:word)? l:rank * l:prev_frequencies[l:word] : l:rank
      endfor
    endif

    let l:complete_words += s:remove_next_keyword(l:complfunc_name, l:result.complete_words)
  endfor

  " Sort.
  if (has_key(g:NeoComplCache_DisablePluginList, 'buffer_complete') && g:NeoComplCache_DisablePluginList['buffer_complete'])
        \|| g:NeoComplCache_AlphabeticalOrder
    let l:func = 'neocomplcache#compare_words'
  else
    let l:func = 'neocomplcache#compare_prev_rank'
  endif

  let l:complete_words = sort(filter(l:complete_words, 'len(v:val.word) > '.len(l:cur_keyword_str)),
        \ l:func)[: g:NeoComplCache_MaxList]
  
  if !g:NeoComplCache_IgnoreCase || 
        \(g:NeoComplCache_SmartCase && l:cur_keyword_str =~ '\u')
    " Set no-icase.
    for l:keyword in l:complete_words
      let l:keyword.icase = 0
    endfor
  endif
  
  " Abbr check.
  let l:abbr_pattern = printf('%%.%ds..%%s', g:NeoComplCache_MaxKeywordWidth-10)
  for l:keyword in l:complete_words
    if len(l:keyword.abbr) > g:NeoComplCache_MaxKeywordWidth
      let l:keyword.abbr = printf(l:abbr_pattern, l:keyword.abbr, l:keyword.abbr[-8:])
    endif
  endfor
  
  return [l:cur_keyword_pos, l:cur_keyword_str, l:complete_words]
endfunction"}}}
function! s:on_insert_enter()"{{{
  let s:update_time_save = &updatetime
  let &updatetime = g:NeoComplCache_CursorHoldITime
endfunction"}}}
function! s:on_insert_leave()"{{{
  let s:cur_keyword_pos = -1
  let s:cur_keyword_str = ''
  let s:complete_words = []
  let &updatetime = s:update_time_save
  let s:used_match_filter = 0
endfunction"}}}
function! s:remove_next_keyword(plugin_name, list)"{{{
  let l:list = a:list
  " Remove next keyword."{{{
  if a:plugin_name  == 'filename_complete'
    let l:pattern = '^\%(' . neocomplcache#get_next_keyword_pattern('filename') . '\m\)'
  else
    let l:pattern = '^\%(' . neocomplcache#get_next_keyword_pattern() . '\m\)'
  endif

  let l:next_keyword_str = matchstr('a'.getline('.')[col('.') - 1 :], l:pattern)[1:]
  if l:next_keyword_str != ''
    let l:next_keyword_str = substitute(escape(l:next_keyword_str, '~" \.^$*[]'), "'", "''", 'g').'$'

    " No ignorecase.
    let l:save_ignorecase = &ignorecase
    let &ignorecase = 0

    for r in l:list
      if r.word =~ l:next_keyword_str
        let r.word = r.word[: match(r.word, l:next_keyword_str)-1]
      endif
    endfor

    let &ignorecase = l:save_ignorecase
  endif"}}}

  return l:list
endfunction"}}}

let s:quickmatch_table = {
      \'a' : 0, 's' : 1, 'd' : 2, 'f' : 3, 'g' : 4, 'h' : 5, 'j' : 6, 'k' : 7, 'l' : 8, ';' : 9,
      \'q' : 10, 'w' : 11, 'e' : 12, 'r' : 13, 't' : 14, 'y' : 15, 'u' : 16, 'i' : 17, 'o' : 18, 'p' : 19, 
      \'z' : 20, 'x' : 21, 'c' : 22, 'v' : 23, 'b' : 24, 'n' : 25, 'm' : 26, ',' : 27, '.' : 28, '/' : 29,
      \'1' : 30, '2' : 31, '3' : 32, '4' : 33, '5' : 34, '6' : 35, '7' : 36, '8' : 37, '9' : 38, '0' : 39
      \}
function! s:make_quickmatch_list(list, cur_keyword_str)"{{{
  " Check dup.
  let l:dup_check = {}
  let l:num = 0
  let l:qlist = []
  let l:key = 
        \'asdfghjkl;'.
        \'qwertyuiop'.
        \'zxcvbnm,./'.
        \'1234567890'

  " Save options.
  let l:ignorecase_save = &ignorecase

  if g:NeoComplCache_SmartCase && a:cur_keyword_str =~ '\u'
    let &ignorecase = 0
  else
    let &ignorecase = g:NeoComplCache_IgnoreCase
  endif

  for keyword in a:list
    if keyword.word != '' && 
          \(keyword.word == a:cur_keyword_str || keyword.word[: len(a:cur_keyword_str)-1] == a:cur_keyword_str)
          \&& (!has_key(l:dup_check, keyword.word) || (has_key(keyword, 'dup') && keyword.dup))
      let l:dup_check[keyword.word] = 1
      let l:keyword = deepcopy(l:keyword)
      let keyword.abbr = printf('%s: %s', l:key[l:num], keyword.abbr)

      call add(l:qlist, keyword)
      let l:num += 1
    endif
  endfor
  
  let &ignorecase = l:ignorecase_save
  
  " Trunk too many items.
  let l:qlist = l:qlist[: len(s:quickmatch_table)]

  " Save numbered lists.
  let s:prev_numbered_list = l:qlist

  return l:qlist
endfunction"}}}
function! s:select_quickmatch_list(key)"{{{
  if !has_key(s:quickmatch_table, a:key)
    return []
  endif
  let l:numbered = get(s:prev_numbered_list, s:quickmatch_table[a:key])
  if type(l:numbered) == type({})
    return [l:numbered]
  endif

  return []
endfunction"}}}
function! s:get_quickmatch_pattern()"{{{
  let l:filetype = (&filetype == '')?   'nothing' : &filetype

  let l:pattern = has_key(g:NeoComplCache_QuickMatchPatterns, l:filetype)?  
        \ g:NeoComplCache_QuickMatchPatterns[l:filetype] : g:NeoComplCache_QuickMatchPatterns['default']

  return l:pattern
endfunction"}}}
function! s:get_cur_text()"{{{
  let l:pos = mode() ==# 'i' ? 2 : 1

  let l:cur_text = col('.') < l:pos ? '' : getline('.')[: col('.') - l:pos]

  if l:cur_text != '' && char2nr(l:cur_text[-1:]) >= 0x80
    let l:len = len(getline('.'))

    " Skip multibyte
    let l:pos -= 1
    let l:cur_text = getline('.')[: col('.') - l:pos]
    let l:fchar = char2nr(l:cur_text[-1:])
    while col('.')-l:pos+1 < l:len && l:fchar >= 0x80
      let l:pos -= 1

      let l:cur_text = getline('.')[: col('.') - l:pos]
      let l:fchar = char2nr(l:cur_text[-1:])
    endwhile
  endif

  " Save cur_text.
  let s:cur_text = l:cur_text
  return l:cur_text
endfunction"}}}

" vim: foldmethod=marker
