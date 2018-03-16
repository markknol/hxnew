#!/bin/sh
rm -f hxnew.zip
zip -r hxnew.zip src template run.n haxelib.json README.md
haxelib submit hxnew.zip $HAXELIB_PWD --always