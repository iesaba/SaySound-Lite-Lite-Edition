SaySound-Lite-Lite-Edition
==========================

SourceMod / SayCommand plugin.

説明
--

http://casko.adam.ne.jp/script.html のSaysoundLEのもっと軽量化したバージョン

チャットコマンド
--------

!saycommand

cfgフォーマット
---------

機能の削減により記述可能な物は下記のみです。sayで音を鳴らす機能のみに絞られています。  
ファイルのダウンロード指定は行えません。全てのファイルのダウンロードを試みます。

 - "file"		ファイルパスの指定。csgo\soundフォルダからの相対パスを記述する
 - "count"		複数ファイル指定時のファイル数

cfgサンプル
-------

    "Sound Combinations"
    {
    	"foo"
    	{
    		"file"	"misc/test/foo.mp3"
    	}
    	"foobar"
    	{
    		"file"	"misc/test/bar.mp3"
    	}
    	"foobar"
    	{
    		"file1"	"misc/test/foo.mp3"
    		"file2"	"misc/test/bar.mp3"
    		"count"	"2"
    	}
    }
