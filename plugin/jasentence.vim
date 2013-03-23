" vi:set ts=8 sts=2 sw=2 tw=0:
scriptencoding utf-8

" plugin/jasentence.vim - 日本語句読点もsentence終了として扱うスクリプト。
"
" Maintainer: KIHARA Hideto <deton@m1.interq.or.jp>
" Last Change: 2013-03-23
"
" Description:
" * )(での移動時に"。．？！"も文の終わりとみなすようにします。
"   +kaoriya版の)(と同様の動作を、スクリプトで実現します。
"
" オプション:
"    'g:loaded_jasentence'
"       このプラグインを読み込みたくない場合に次のように設定する。
"         let g:loaded_jasentence = 1

if exists('g:loaded_jasentence')
  finish
endif

nnoremap <silent> <Plug>JaSentenceMoveNF :<C-U>call <SID>MoveCount('<SID>ForwardS')<CR>
nnoremap <silent> <Plug>JaSentenceMoveNB :<C-U>call <SID>MoveCount('<SID>BackwardS')<CR>
onoremap <silent> <Plug>JaSentenceMoveOF :<C-U>call <SID>MoveCount('<SID>ForwardS')<CR>
onoremap <silent> <Plug>JaSentenceMoveOB :<C-U>call <SID>MoveCount('<SID>BackwardS')<CR>

if !get(g:, 'jasentence_no_default_key_mappings', 0)
  nmap <silent> ) <Plug>JaSentenceMoveNF
  nmap <silent> ( <Plug>JaSentenceMoveNB
  omap <silent> ) <Plug>JaSentenceMoveOF
  omap <silent> ( <Plug>JaSentenceMoveOB
endif

" TODO: visual mode
" TODO: text-object

function! s:MoveCount(func)
  let cnt = v:count1
  for i in range(cnt)
    call function(a:func)()
  endfor
endfunction

function! s:ForwardS()
  let origpos = getpos('.')
  normal! )
  let enpos = getpos('.')
  call setpos('.', origpos)
  if search('[、。，．？！]\+\n\=\s*\S', 'eW', enpos[1]) == 0
    call setpos('.', enpos)
    return
  endif
  let japos = getpos('.')
  if s:pos_lt(japos, enpos)
    return
  endif
  call setpos('.', enpos)
endfunction

function! s:pos_lt(pos1, pos2)  " less than
  return a:pos1[1] < a:pos2[1] || a:pos1[1] == a:pos2[1] && a:pos1[2] < a:pos2[2]
endfunction

function! s:BackwardS()
  let origpos = getpos('.')
  normal! (
  let enpos = getpos('.')
  call setpos('.', origpos)
  if search('[、。，．？！]\+\n\=\s*\zs\S', 'bW', enpos[1]) == 0
    call setpos('.', enpos)
    return
  endif
  let japos = getpos('.')
  if s:pos_lt(enpos, japos)
    return
  endif
  call setpos('.', enpos)
endfunction
