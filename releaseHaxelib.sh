#!/bin/sh
rm -f hxnew.zip
zip -r hxnew.zip src template run.n haxelib.json readme.md
haxelib submit hxnew.zip $HAXELIB_PWD --always