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
vnoremap <silent> <Plug>JaSentenceMoveVF <Esc>:call <SID>MoveV('<SID>ForwardS')<CR>
vnoremap <silent> <Plug>JaSentenceMoveVB <Esc>:call <SID>MoveV('<SID>BackwardS')<CR>

onoremap <silent> <Plug>JaSentenceTextObjA :<C-U>call <SID>select_function_wrapper('<SID>select_a')<CR>

if !get(g:, 'jasentence_no_default_key_mappings', 0)
  nmap <silent> ) <Plug>JaSentenceMoveNF
  nmap <silent> ( <Plug>JaSentenceMoveNB
  omap <silent> ) <Plug>JaSentenceMoveOF
  omap <silent> ( <Plug>JaSentenceMoveOB
  xmap <silent> ) <Plug>JaSentenceMoveVF
  xmap <silent> ( <Plug>JaSentenceMoveVB
  omap <silent> as <Plug>JaSentenceTextObjA
endif

" TODO: text-object inner sentence
" TODO: text-object in visual mode

" from vim-textobj-user
function! s:select_function_wrapper(function_name)
  let ORIG_POS = getpos('.')
  let _ = function(a:function_name)()
  if _ is 0
    call setpos('.', ORIG_POS)
    return
  endif
  let [motion_type, start_position, end_position] = _
  execute 'normal!' motion_type
  call setpos('.', start_position)
  normal! o
  call setpos('.', end_position)
endfunction

function! s:select_a()
  let origpos = getpos('.')
  let spincluded = 0
  let line = getline('.')
  if line == ''
  elseif match(line, '\%' . col('.') . 'c[[:space:]　]') != -1
    " カーソルが空白上の場合
    call s:ForwardS()
    let nextsent = getpos('.')
    call setpos('.', origpos)
    if search('[\n[:space:]　]\+[^\n[:space:]　]', 'ce') > 0
      if s:pos_eq(getpos('.'), nextsent)
	" 次のsentence直前の連続空白上の場合は、空白開始位置以降を対象にする
	call setpos('.', origpos)
	call search('[^\n[:space:]　]\zs[\n[:space:]　]', 'bc')
	let spincluded = 1
      else
	" sentence途中の空白上の場合、sentence開始位置以降を対象にする
	call setpos('.', origpos)
	call s:BackwardS()
      endif
    endif
  else
    " sentence開始位置以降を対象にする
    " (s:BackwardS()だけだと、既にsentence先頭にいる場合に問題あり)
    call s:ForwardS()
    call s:BackwardS()
  endif
  let st = getpos('.')
  call s:MoveCount('<SID>ForwardS')

  " origposがsentence開始直前の空白上だった場合、
  if spincluded
    " 最初のForwardS()で1 count消費してるので、追加で1 count分移動
    call s:ForwardS()
    " 次sentence直前の空白は含めない
    call search('[^[:space:]　]\|^', 'b')
    return ['v', st, getpos('.')]
  endif

  if line('.') == line('$')
    let edtmp = getpos('.')
    call s:ForwardS()
    if s:pos_eq(getpos('.'), edtmp)
      " バッファ末尾
      return ['v', st, edtmp]
    endif
    call setpos('.', edtmp)
  endif
  " 次sentence直前まで
  if col('.') > 1
    call cursor(0, col('.') - 1)
  else
    call cursor(line('.') - 1, 0)
    call cursor(0, col('$'))
  endif
  return ['v', st, getpos('.')]
endfunction

function! s:MoveCount(func)
  let cnt = v:count1
  for i in range(cnt)
    call function(a:func)()
  endfor
endfunction

" Forward{S,B}をVisual modeに対応させるためのラッパ
function! s:MoveV(func)
  let cnt = v:prevcount
  if cnt == 0
    let cnt = 1
  endif
  for i in range(cnt)
    call function(a:func)()
  endfor
  let pos = getpos('.')
  normal! gv
  call cursor(pos[1], pos[2])
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

function! s:pos_eq(pos1, pos2)  " equal
  return a:pos1[1] == a:pos2[1] && a:pos1[2] == a:pos2[2]
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
