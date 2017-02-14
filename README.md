# hxnew

[![Build Status](https://travis-ci.org/markknol/hxnew.svg?branch=master)](https://travis-ci.org/markknol/hxnew)

> Create new Haxe projects in a blast!  
> This tool is ment to run once to create an initial plain Haxe project structure.

## Installation

Currently there is no haxelib, you can use the git version to test the tool:

```
haxelib git hxnew https://github.com/markknol/hxnew.git
```

## How to use 

#### `haxelib run hxnew -name MyProject`

This will create a js project with this directory structure:

```
MyProject/
MyProject/build.hxml
MyProject/haxelib.json
MyProject/makefile
MyProject/bin/index.html
MyProject/src/Main.hx
```

#### `haxelib run hxnew -name MyProject -pack com.company.tool`

This will create a js project with this directory structure:

```
MyProject/
MyProject/build.hxml
MyProject/haxelib.json
MyProject/makefile
MyProject/bin/index.html
MyProject/src/com/company/tool/Main.hx
```

#### `haxelib run hxnew -name MyProject -target neko,nodejs -lib hxargs,format`

This will create a neko + nodejs project with this directory structure:

```
MyProject/
MyProject/bin/
MyProject/src/Main.hx
MyProject/build-neko.hxml
MyProject/build-nodejs.hxml
MyProject/haxelib.json
MyProject/install.hxml
MyProject/makefile
MyProject/run-neko.hxml
MyProject/run-nodejs.hxml
```

* When providing a lib, a install.hxml is created. Run this to install the project dependencies.
* The run files start the process to run the code


## Command line help

```
[-name | -n] <name>      : Name of the project. required
[-include | -i] <path>   : Folder to include in project
[-out] <path>            : Project out folder. default: same as name
[-src] <path>            : Class path source folder. default: 'src'
[-cp] <path>             : Additional class path
[-bin] <path>            : Output folder. default: 'bin'
[-lib] <lib>             : Libs used in the project, comma separate
[-target | -t] <targets> : Target languages, comma separate. Default: 'js'
[-pack] <classPath>      : Package of the entry point
[--no-main]              : Don't generate a Main.hx file
[--no-makefile]          : Don't generate a makefile
[--no-haxelib-json]      : Don't generate a haxelib.json
```
