#!/bin/sh
rm -f $name.zip
zip -r $name.zip .
haxelib submit $name.zip $HAXELIB_PWD --always