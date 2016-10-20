@echo off
cd bin
neko haxeproj.n -name MyProject1
neko haxeproj.n -name MyProject2 -target neko -target nodejs -target js -pack my.project -cp ../../issue -lib hxargs -include baseproject
pause