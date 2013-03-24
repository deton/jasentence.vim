" vi:set ts=8 sts=2 sw=2 tw=0:
scriptencoding utf-8

" plugin/jasentence.vim - 日本語句読点もsentence終了として扱うスクリプト。
"
" Maintainer: KIHARA Hideto <deton@m1.interq.or.jp>
" Last Change: 2013-03-24
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

nnoremap <silent> <Plug>JaSentenceMoveNF :<C-U>call <SID>MoveCount('<SID>ForwardS', v:count1)<CR>
nnoremap <silent> <Plug>JaSentenceMoveNB :<C-U>call <SID>MoveCount('<SID>BackwardS', v:count1)<CR>
onoremap <silent> <Plug>JaSentenceMoveOF :<C-U>call <SID>MoveCount('<SID>ForwardS', v:count1)<CR>
onoremap <silent> <Plug>JaSentenceMoveOB :<C-U>call <SID>MoveCount('<SID>BackwardS', v:count1)<CR>
vnoremap <silent> <Plug>JaSentenceMoveVF <Esc>:call <SID>MoveV('<SID>ForwardS')<CR>
vnoremap <silent> <Plug>JaSentenceMoveVB <Esc>:call <SID>MoveV('<SID>BackwardS')<CR>

onoremap <silent> <Plug>JaSentenceTextObjA :<C-U>call <SID>select_function_wrapper('<SID>select_a', v:count1)<CR>
onoremap <silent> <Plug>JaSentenceTextObjI :<C-U>call <SID>select_function_wrapper('<SID>select_i', v:count1)<CR>
vnoremap <silent> <Plug>JaSentenceTextObjVA <Esc>:call <SID>select_function_wrapperv('<SID>select_a', 0)<CR>
vnoremap <silent> <Plug>JaSentenceTextObjVI <Esc>:call <SID>select_function_wrapperv('<SID>select_i', 1)<CR>

if !get(g:, 'jasentence_no_default_key_mappings', 0)
  nmap <silent> ) <Plug>JaSentenceMoveNF
  nmap <silent> ( <Plug>JaSentenceMoveNB
  omap <silent> ) <Plug>JaSentenceMoveOF
  omap <silent> ( <Plug>JaSentenceMoveOB
  xmap <silent> ) <Plug>JaSentenceMoveVF
  xmap <silent> ( <Plug>JaSentenceMoveVB
  omap <silent> as <Plug>JaSentenceTextObjA
  omap <silent> is <Plug>JaSentenceTextObjI
  xmap <silent> as <Plug>JaSentenceTextObjVA
  xmap <silent> is <Plug>JaSentenceTextObjVI
endif

" from vim-textobj-user
function! s:select_function_wrapper(function_name, count1)
  let ORIG_POS = getpos('.')
  let _ = function(a:function_name)(a:count1, 0)
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

function! s:select_function_wrapperv(function_name, inner)
  let cnt = v:prevcount
  if cnt == 0
    let cnt = 1
  endif
  " 何も選択されていない場合、textobj選択
  let pos = getpos('.')
  execute 'normal! gvo' . "\<Esc>"
  let otherpos = getpos('.')
  execute 'normal! gvo' . "\<Esc>"
  if pos == otherpos
    call s:select_function_wrapper(a:function_name, cnt)
    return
  endif

  " 選択済の場合、選択領域をextendする
  if s:pos_lt(pos, otherpos)
    " backward
    " TODO
    if a:inner
      call s:select_i_b(cnt)
    else
      call s:select_a_b(cnt)
    endif
  else
    if a:inner
      call s:select_i(cnt, 1)
    else
      call s:select_a(cnt, 1)
    endif
  endif
  let newpos = getpos('.')
  normal! gv
  call setpos('.', newpos)
endfunction

function! s:select_a(cnt, visual)
  return s:select(a:cnt, 0, a:visual)
endfunction

function! s:select_i(cnt, visual)
  return s:select(a:cnt, 1, a:visual)
endfunction

function! s:select(cnt, inner, visual)
  let origpos = getpos('.')
  let startonsp = 0
  if a:visual
    call search('.', 'W') " 繰り返しas/isした場合にextendするため
    if s:postype() == 1
      let startonsp = 1
    endif
  else
    let postype = s:postype()
    if postype == 1
      " 次のsentence直前の連続空白上の場合は、空白開始位置以降を対象にする
      call search('[^\n[:space:]　]\zs[\n[:space:]　]', 'bcW')
      let startonsp = 1
    elseif postype == 2
      " sentence途中の空白上の場合、sentence開始位置以降を対象にする
      call s:BackwardS()
    elseif postype == 4
      " sentence開始位置以降を対象にする
      call s:ForwardS() " 既にsentence先頭にいる場合用
      call s:BackwardS()
      " FIXME: バッファ末尾に1文字だけある場合、直前のsentenceが対象になる
    endif
  endif
  let st = getpos('.')
  let cnt = a:cnt
  let trimendsp = 0
  if a:inner
    " innerの場合はsentence間の空白もcountを消費する。
    " 日本語の場合はsentence間に空白が無い場合があるが、+kaoriya版と同様に消費
    if startonsp " sentence開始直前の連続空白上で開始した場合
      if a:cnt == 1 " sentence開始直前の連続空白のみを対象にする
	call s:ForwardS()
	return ['v', st, s:PrevSentEndPos()]
      endif
      let cnt = a:cnt / 2
      let cnt += 1 " sentence開始位置への移動用に1 count追加
      if a:cnt % 2 == 0
	let trimendsp = 1 " 指定されたcountが偶数ならtrimする
      else
	let trimendsp = 0
      endif
    else
      let cnt = (a:cnt + 1) / 2
      if a:cnt % 2 == 0
	let trimendsp = 0
      else
	let trimendsp = 1
      endif
    endif
  elseif startonsp
    " sentence開始直前の連続空白上だった場合、
    " sentence開始位置への移動で1 count消費するので、1 count追加
    let cnt += 1
    let trimendsp = 1
  endif
  call s:MoveCount('<SID>ForwardS', cnt)

  if trimendsp
    " 現在位置(対象文字列直後のsentence開始位置)直前の空白は含めない。
    " 現在位置がバッファ末尾かつ空白でない場合は、最後の文字が残らないように。
    if !(s:bufend() && match(getline('.'), '\%' . col('.') . 'c[[:space:]　]') == -1)
      call search('[^[:space:]　]\|^', 'bW')
    endif
    return ['v', st, getpos('.')]
  endif

  let ed = s:PrevSentEndPos()
  " "as"で対象文字列末尾が空白でない場合、開始位置直前に空白があれば含める
  if !a:visual && !a:inner && !startonsp && match(getline('.'), '\%' . col('.') . 'c[[:space:]　]') == -1
    call setpos('.', st)
    " 日本語の場合は空白無しの場合があるので開始位置前の空白以外の文字をsearch
    if search('[^\n[:space:]　]', 'bW') > 0
      call search('.', 'W')
    endif
    let st = getpos('.')
  endif
  return ['v', st, ed]
endfunction

" 現在のカーソル位置の種別を返す
function! s:postype()
  let origpos = getpos('.')
  let line = getline('.')
  if line == ''
    let ret = 0 " 空行上
  elseif match(line, '\%' . col('.') . 'c[[:space:]　]') != -1
    " カーソルが空白上の場合
    call s:ForwardS()
    let nextsent = getpos('.')
    call setpos('.', origpos)
    if search('[\n[:space:]　]\+[^\n[:space:]　]', 'ceW') > 0
      if s:pos_eq(getpos('.'), nextsent)
	let ret = 1 " 次のsentence直前の連続空白上
      else
	let ret = 2 " sentence途中の空白上
      endif
    else
      let ret = 3 " バッファ末尾の空白上
    endif
  else
    let ret = 4 " sentence内
  endif
  call setpos('.', origpos)
  return ret
endfunction

" バッファ末尾かどうか
function! s:bufend()
  if line('.') != line('$')
    return 0
  endif
  let edtmp = getpos('.')
  call s:ForwardS()
  let pos = getpos('.')
  if s:pos_eq(pos, edtmp)
    return 1
  endif
  call setpos('.', edtmp)
  return 0
endfunction

" 前のsentenceの末尾位置を返す。
" 前提条件: sentence開始位置にカーソルがある
function! s:PrevSentEndPos()
  " バッファ末尾の場合に末尾の文字だけが残ったりしないように
  if s:bufend()
    return getpos('.')
  endif
  " 次sentence直前まで
  if col('.') > 1
    call cursor(0, col('.') - 1)
  else
    call cursor(line('.') - 1, 0)
    call cursor(0, col('$'))
  endif
  return getpos('.')
endfunction

function! s:MoveCount(func, cnt)
  for i in range(a:cnt)
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
