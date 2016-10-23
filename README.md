# hxnew

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
MyProject/bin/index.html
MyProject/src/Main.hx
```

#### `haxelib run hxnew -name com.company.tool.MyProject`

This will create a js project with this directory structure:

```
MyProject/
MyProject/build.hxml
MyProject/bin/index.html
MyProject/src/com/company/tool/Main.hx
```

#### `haxelib run hxnew -name MyProject -target neko,nodejs -lib hxargs`

This will create a js project with this directory structure:

```
MyProject/
MyProject/bin/
MyProject/src/Main.hx
MyProject/build-neko.hxml
MyProject/build-nodejs.hxml
MyProject/install.hxml
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
[-lib] <lib>             : Libs used in the project
[-target | -t] <targets> : Target languages, comma separate. Default: 'js'
[-pack] <classPath>      : Package of the entry point
[--no-main]              : Don't generate a Main.hx file
```
