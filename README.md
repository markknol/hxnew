# hxnew

[![Build Status](https://travis-ci.org/markknol/hxnew.svg?branch=master)](https://travis-ci.org/markknol/hxnew)
[![Haxelib Version](https://img.shields.io/github/tag/markknol/hxnew.svg?label=haxelib)](http://lib.haxe.org/p/hxnew)

> Create new Haxe projects in a blast!  
> This tool is meant to create a plain Haxe project. Run it once.

## Installation

Install using [haxelib](http://lib.haxe.org/p/hxnew):

```
haxelib install hxnew
```

## How to use 

#### `haxelib run hxnew -name MyProject`

This will create a js project with this directory structure:

```
MyProject/bin/index.html
MyProject/src/Main.hx
MyProject/.gitignore
MyProject/.travis.yml
MyProject/build.hxml
MyProject/haxelib.json
MyProject/makefile
MyProject/README.md
MyProject/release_haxelib.sh
MyProject/MyProject.hxproj
```

#### `haxelib run hxnew -name MyProject -pack com.company.tool`

This will create a js project with same directory structure as above but the Main class located in the com.company.tool package. 

```
MyProject/src/com/company/tool/Main.hx
```

#### `haxelib run hxnew -name MyProject -target neko,nodejs -lib hxargs,format`

This will create a neko + nodejs project with this directory structure:

```
MyProject/bin/
MyProject/src/Main.hx
MyProject/.gitignore
MyProject/.travis.yml
MyProject/build-neko.hxml
MyProject/build-nodejs.hxml
MyProject/haxelib.json
MyProject/install.hxml
MyProject/makefile
MyProject/README.md
MyProject/run-neko.hxml
MyProject/run-nodejs.hxml
MyProject/release_haxelib.sh
MyProject/MyProject.hxproj
```

#### `haxelib run hxnew -name MyProject --lix`

This will create a [lix.pm](https://github.com/lix-pm/lix.client) project. It creates a package.json and requires all libraries using lix!

> Notes:
> * When providing a lib, an install.hxml is created. Run this to install the project dependencies.
> * The run files start the process to run the code

## Command line help

```
[-name | -n] <name>      : Name of the project. required
[-include | -i] <path>   : Folder to include in project
[-out] <path>            : Project out folder. default: same as name
[-src] <path>            : Class path source folder. default: 'src'
[-cp] <path>             : Additional class path
[-bin] <path>            : Output folder. default: 'bin'
[-lib | -libs] <libs>    : Libs used in the project, comma separate
[-target | -t] <targets> : Target languages, comma separate. Or "all" for all targets. Default: 'js'
[-pack] <classPath>      : Package of the entry point
[--lix]                  : Use Lix.pm. Assumes global available `npm` command
[--makefile]             : Generate a makefile
[--no-haxedevelop]       : Don't generate HaxeDevelop project files
[--no-main]              : Don't generate a Main.hx file
[--no-readme]            : Don't generate README.md
[--no-gitignore]         : Don't generate .gitignore
[--no-haxelib-json]      : Don't generate a haxelib.json
[--no-travis]            : Don't generate Travis files
[--version | -v]         : Log version
```
