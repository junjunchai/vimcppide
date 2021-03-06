"=============================================================================
" FILE: spell_complete.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 25 Apr 2010
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
"=============================================================================

function! neocomplcache#plugin#spell_complete#initialize()"{{{
  " Initialize.
endfunction"}}}

function! neocomplcache#plugin#spell_complete#finalize()"{{{
endfunction"}}}

function! neocomplcache#plugin#spell_complete#get_keyword_list(cur_keyword_str)"{{{
  if !&spell || neocomplcache#is_auto_complete() || len(a:cur_keyword_str) < 4
    return []
  endif

  let l:list = []
  for l:keyword in spellsuggest(a:cur_keyword_str)
    call add(l:list, { 'word' : l:keyword, 'menu' : '[Spell]', 'icase' : 1 })
  endfor

  return l:list
endfunction"}}}

" vim: foldmethod=marker
