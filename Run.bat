@echo off
cd bin
haxelib run hxnew -name com.website.MyProject1
haxelib run hxnew -name my.project.MyProject2 -target neko,nodejs,js -cp ../../issue -lib hxargs -include baseproject
pause