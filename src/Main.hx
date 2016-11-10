package;
import haxe.io.Path;
import hxargs.Args;
import sys.FileSystem;
import sys.io.File;
using StringTools;

/**
 * @author Mark Knol
 */
class Main 
{
	static function main() new Main();

	private function new()
	{
		var project = new Project();
		var argHandler = hxargs.Args.generate([
			@doc("Name of the project. required")
			["-name", "-n"] => function(name:String) {
				var path = name.split(".");
				project.name = path.pop();
				if (path.length > 0) project.classPath = path.join(".");
			},
			
			@doc("Folder to include in project")
			["-include", "-i"] => function(path:String) project.includes.push(path),
			
			@doc("Project out folder. default: same as name")
			["-out"] => function(path:String) project.outPath = path,
			
			@doc("Class path source folder. default: 'src'")
			["-src"] => function(path:String) project.srcPath = path,
			
			@doc("Additional class path")
			["-cp"] => function(path:String) project.classPaths.push(path),
			
			@doc("Output folder. default: 'bin'")
			["-bin"] => function(path:String) project.binPath = path,
			
			@doc("Libs used in the project")
			["-lib"] => function(libs:String) for(lib in libs.split(",")) project.libs.push(lib),
			
			@doc("Target languages, comma separate. Default: 'js'")
			["-target", "-t"] => function(targets:String) for(target in targets.split(",")) project.targets.push(target),
			
			@doc("Package of the entry point")
			["-pack"] => function(classPath:String) project.classPath = classPath,
			
			@doc("Don't generate a Main.hx file")
			["--no-main"] => function() project.doCreateMainClass = false,
			
			@doc("Don't generate a makefile")
			["--no-makefile"] => function() project.doCreateMakeFile = false,
			
			@doc("Don't generate a haxelib.json")
			["--no-haxelib-json"] => function() project.doCreateHaxelibJson = false,
			
			_ => function(value:String) 
				if (FileSystem.isDirectory(value)) project.curPath = value 
				else throw 'Cannot parse arg $value',
		]);

		var args = Sys.args();
		if (args.length == 0) {
			Sys.println(argHandler.getDoc());
		} else  {
			argHandler.parse(args);
			if (project.name != null) {
				project.create();
			} else {
				Sys.println(argHandler.getDoc());
			}
		}
	}
}

class Project
{
	static inline var DEFAULT_TARGET:String = "js";
	static inline var NEWLINE:String = "\n";
	
	public var name:String;
	public var binPath:String = "bin";
	public var srcPath:String = "src";
	public var curPath:String;
	public var classPath:String = "";
	public var outPath:String;
	
	public var doCreateMainClass:Bool = true;
	public var doCreateMakeFile:Bool = true;
	public var doCreateHaxelibJson:Bool = true;
	
	public var includes:Array<String> = [];
	public var libs:Array<String> = [];
	public var targets:Array<String> = [];
	public var classPaths:Array<String> = [];
	
	public function new() {
		
	}
	
	public function create() {
		if (outPath == null || outPath.length == 0) outPath = curPath + '$name/';
		else outPath = curPath + outPath;
		outPath = Path.normalize(outPath);
		
		if (!outPath.endsWith("/")) outPath += "/";
		if (!binPath.endsWith("/")) binPath += "/";
		if (!srcPath.endsWith("/")) srcPath += "/";
		if (!curPath.endsWith("/")) curPath += "/";
		
		if (targets.length == 0) targets.push(DEFAULT_TARGET);
		
		createOutPath();
		createBinPath();
		createPack();
		createMainClass();
		
		createBuildFiles();
		createRunFiles();
		createInstallFiles();
		createMakeFile();
		createHaxelibJson();
		
		for (path in includes) {
			includeDirectory(path);
		}
		
		Sys.println("Project created: " + outPath);
	}
	
	private function createOutPath() {
		FileSystem.createDirectory(outPath);
	}
	
	private function createMainClass() {
		if (doCreateMainClass) {
			var main = File.getContent(Sys.getCwd() + '/template/src/Main.hx');
			main = replaceVars(main);
			var classPathDir = classPath != "" ? classPath.replace(".", "/") : "";
			File.saveContent(outPath + srcPath + classPathDir + "/Main.hx", main);
		}
	}
	
	private function createInstallFiles() {
		if (libs.length > 0) {
			var hxml = '';
			if (targets.length > 1) {
				for (i in 0...targets.length) {
					var target = targets[i];
					hxml += '-cmd haxelib install build-${target}.hxml --always ' + NEWLINE;
					if (i != targets.length - 1) hxml += '--next' + NEWLINE;
				}
			} else {
				hxml += '-cmd haxelib install build.hxml --always ' + NEWLINE;
			}
			File.saveContent(outPath + "install.hxml", hxml);
		}
	}
	
	private function createHaxelibJson() {
		if (!doCreateHaxelibJson) return;
		var json = "";
		var dependencies = "";
		
		if (libs.length > 0) {
			for (lib in libs) dependencies += '    "$lib" : ""' + NEWLINE;
		}
		
		var targets_ = targets.copy();
		targets_.unshift("haxe");
		var tags = [for (target in targets_) '"$target"'].join(",");
		
		File.saveContent(outPath + "haxelib.json", replaceVars(File.getContent(Sys.getCwd() + '/template/haxelib.json')).replace("$dependencies",dependencies).replace("$tags",tags));
	}
	
	private function createMakeFile() {
		if (!doCreateMakeFile) return;
		var makefile = "";
		makefile += 'clean:' + NEWLINE;
		makefile += '    rm $binPath' + NEWLINE;
		makefile += NEWLINE;
		
		if (targets.length > 1) {
			for (target in targets) {
				makefile += 'test-${target}:' + NEWLINE;
				makefile += '    haxe build-$target.hxml' + NEWLINE;
				var command = getRunCommand(target);
				if (command != null) makefile += '    $command' + NEWLINE;
				makefile += NEWLINE;
			} 
		} else {
			var target = targets[0];
			makefile += 'test:' + NEWLINE;
			makefile += '    haxe build.hxml' + NEWLINE;
			var command = getRunCommand(target);
			if (command != null) makefile += '    $command' + NEWLINE;
			makefile += NEWLINE;
		}
		
		if (libs.length > 0) {
			makefile += 'install:' + NEWLINE;
			if (targets.length > 1) {
				for (target in targets) makefile += '    haxelib install build-${target}.hxml' + NEWLINE;
			} else {
				makefile += '    haxelib install build.hxml' + NEWLINE;
			}
			makefile += NEWLINE;
		}
		
		File.saveContent(outPath + "makefile", makefile);
	}
	
	private function createBinPath() {
		FileSystem.createDirectory(outPath + binPath);
		for (target in targets) switch(target) {
			case "js": 
				// copy index.html
				File.saveContent(outPath + binPath + "index.html", replaceVars(File.getContent(Sys.getCwd() + '/template/bin/index.html')));
			default: 
		}
	}
	
	private function replaceVars(value:String) {
		return value
			.replace("$outPath", outPath)
			.replace("$binPath", binPath)
			.replace("$srcPath", srcPath)
			.replace("$curPath", curPath)
			.replace("$classPath", classPath)
			.replace("$name", name);
	}
	
	private function createPack() {
		if (classPath != "") {
			if (classPath.endsWith(".")) classPath = classPath.substr(0, classPath.length - 1);
			FileSystem.createDirectory(outPath + srcPath + classPath.replace(".", "/") + "/");
		} else {
			FileSystem.createDirectory(outPath + srcPath);
		}
	}
	
	private function createBuildFiles() {
		if (targets.length == 1) {
			createBuildFile(targets[0], 'build.hxml');
		} else {
			for (target in targets) {
				createBuildFile(target, 'build-$target.hxml');
			}
		}
	}
	
	private function createBuildFile(target:String, file:String) {
		var hxml = '';
		var pack = classPath != "" ? classPath + "." : "";
		if (doCreateMainClass) hxml += '-main ${pack}Main' + NEWLINE;
		hxml += '-cp $srcPath' + NEWLINE;
		for(cp in classPaths) hxml += '-cp $cp' + NEWLINE;
		
		var actualTarget = switch(target) {
			case "nodejs": "js";
			default: target;
		}
		hxml += '-$actualTarget ${getOutputPath(target)}' + NEWLINE;
		
		if (target == "nodejs") hxml += '-lib hxnodejs' + NEWLINE;
		if (libs.length > 0) for (lib in libs) hxml += '-lib $lib' + NEWLINE;
		
		File.saveContent(outPath + file, hxml);
	}
	
	private function createRunFiles() {
		trace(targets, targets.length);
		if (targets.length > 0) {
			if (targets.length == 1) {
				createRunFile(targets[0], 'run.hxml');
			} else {
				for (target in targets) {
					createRunFile(target, 'run-$target.hxml');
				}
			}
		}
	}
	
	private function getOutputPath(target:String) {
		var extension = switch(target) {
			case "js","nodejs": ".js";
			case "python": ".py";
			case "swf": ".swf";
			case "lua": ".lua";
			case "neko": ".n";
			case "hl": ".hl";
			case "java": ".jar";
			default: "";
		}
		return binPath + '$name$extension';
	}
	
	private function createRunFile(target:String, file:String) {
		var hxml = '';
		var command = getRunCommand(target);
		if (command != null) {
			hxml += '-cmd $command' + NEWLINE;
			File.saveContent(outPath + file, hxml);
		}
	}
	
	private function getRunCommand(target:String) {
		var outputPath = getOutputPath(target);
		return switch(target) {
			case "nodejs": 'node $outputPath';
			case "python": 'python $outputPath';
			case "swf": 'run $outputPath';
			case "neko": 'neko $outputPath';
			case "hl": 'hl $outputPath';
			case "php": 'php $outputPath';
			case "java": 'java -jar $outputPath';
			case "cs": '$outputPath.exe';
			default: null;
		}
	}
	
	public function includeDirectory(dir:String, base:String = null) {
		if (!dir.endsWith("/")) dir += "/";
		if (base == null) base = dir;
		try {
			var files = FileSystem.readDirectory(dir);
			if (files != null) {
				for (file in files) {
					var path = '$dir/$file';
					if (FileSystem.isDirectory(path)) {
						FileSystem.createDirectory(outPath + path.substr(base.length, path.length));
						includeDirectory(path, base);
					} else {
						File.copy(path, outPath + path.substr(base.length, path.length));
					}
				}
			}
		} catch (e:Dynamic) trace('Failed to include "$dir"');
	}
}