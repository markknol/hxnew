@echo off
cd bin
haxelib run haxeproj -name MyProject1
haxelib run haxeproj -name MyProject2 -target neko -target nodejs -target js -pack my.project -cp ../../issue -lib hxargs -include baseproject
pause