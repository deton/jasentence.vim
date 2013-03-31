jasentence.vim - )(によるsentence移動時に"、。"も文の終わりとみなすスクリプト
=============================================================================

jasentence.vimは、)(によるsentence移動時に"、。"も
文の終わりとみなすスクリプトです。

+kaoriya版パッチによる)(と同様の動作を、スクリプトで実現するものです。
(なので、+kaoriya版Vimの場合はこのスクリプトは不要です)。

`)`,`(`,`as`,`is`を置き換えます。

* 通常移動(countも対応)の他に、Visual modeや、
  `d)`/`c2)`/`y(`等のOperator-pending modeも対応。
* text-objectsでsentence選択を行う`as`/`is`も置き換えます。

関連
====

* [句読点に移動するmap](https://gist.github.com/deton/5138905#ftr-1)

    f,tを使った「。、」への移動を、`f<C-J>`等にmapしておく設定例

* [jasegment.vim](https://github.com/deton/jasegment.vim)

    日本語文章でのWORD移動(W,E,B)を文節単位にするスクリプト

* [textobj-nonblankchars.vim](https://github.com/deton/textobj-nonblankchars.vim)

    日本語文字上でも、英文のWORDと同様に、
    空白文字で区切られた文字列を選択するtext-object
