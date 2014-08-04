SaySound-Lite-Lite-Edition
==========================

SourceMod / SayCommand plugin.

説明
--

http://casko.adam.ne.jp/script.html のSaysoundLEのもっと軽量化したバージョン


cfgフォーマット
---------

機能の削減により記述可能な物は下記のみです。sayで音を鳴らす機能のみに絞られています。  
ファイルのダウンロード指定は行えません。全てのファイルのダウンロードを試みます。

 - "file"		ファイルパスの指定。csgo\soundフォルダからの相対パスを記述する

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
    }
