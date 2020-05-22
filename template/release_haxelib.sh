#!/bin/sh
rm -f $name.zip
zip -r $name.zip src *.hxml *.json *.md run.*
haxelib submit $name.zip $HAXELIB_PWD --always
