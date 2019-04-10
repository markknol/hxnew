package;
import haxe.Json;
import haxe.io.Path;
import hxargs.Args;
import sys.FileSystem;
import sys.io.File;
using StringTools;
using Lambda;

/**
 * @author Mark Knol
 */
class Main {
	static function main() new Main();

	private function new() {
		var haxelibVersion = Util.getHaxelibVersion();
		var doGenerate = true;
		var project = new Project();
		var argHandler = hxargs.Args.generate([
			@doc("Name of the project. required")
			["-name", "-n"] => function(name:String) project.name = name,
			
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
			
			@doc("Libs used in the project, comma separate")
			["-lib", "-libs"] => function(libs:String) for(lib in libs.split(",")) project.libs.push(lib.trim()),
			
			@doc("Target languages, comma separate. Or \"all\" for all targets. Default: 'js'")
			["-target", "-t"] => function(targets:String) 
				if (targets == "all") 
					for (target in ["js", "nodejs", "python", "swf", "as3", "lua", "php7", "neko", "hl", "php", "java", "cpp", "cs"]) project.targets.push(target)
				else
					for (target in targets.split(",")) project.targets.push(target),
			
			@doc("Package of the entry point")
			["-pack"] => function(classPath:String) project.classPath = classPath,
			
			@doc("Use Lix.pm. Assumes global available `npm` command")
			["--lix"] => function() project.doUseLix = true,
			
			@doc("Generate a makefile")
			["--makefile"] => function() project.doCreateMakeFile = true,
			
			@doc("Don't generate HaxeDevelop project files")
			["--no-haxedevelop"] => function() project.doCreateHaxeDevelopProjects = false,
			
			@doc("Don't generate a Main.hx file")
			["--no-main"] => function() project.doCreateMainClass = false,
			
			@doc("Don't generate README.md")
			["--no-readme"] => function() project.doCreateReadme = false,
			
			@doc("Don't generate .gitignore")
			["--no-gitignore"] => function() project.doCreateGitignore = false,
			
			@doc("Don't generate a haxelib.json")
			["--no-haxelib-json"] => function() project.doCreateHaxelibJson = false,
			
			@doc("Don't generate Travis files")
			["--no-travis"] => function() project.doCreateTravis = false,
			
			@doc("Log version")
			["--version", "-v"] => function() {
				Sys.println(haxelibVersion);
				doGenerate = false;
			},
			
			_ => function(value:String) {
				if (!FileSystem.exists(value)) {
					Sys.println('[error] Invalid command "$value"');
					doGenerate = false;
				}
			}
		]);
		

		var doc = 'hxnew $haxelibVersion - Create new Haxe projects in a blast!\n\n' + argHandler.getDoc();
		var args = Sys.args();
		if (args.length == 0) {
			Sys.println(doc);
		} else {
			argHandler.parse(args);
			if (project.name != null && doGenerate) {
				project.create();
			} else {
				if (doGenerate) Sys.println(doc);
			}
		}
	}
}

class Project {
	static inline var DEFAULT_TARGET:String = "js";
	static inline var NEWLINE:String = "\n";
	
	public var name:String;
	public var binPath:String = "bin";
	public var srcPath:String = "src";
	public var curPath:String = Sys.getCwd();
	public var classPath:String = "";
	public var outPath:String;
	
	public var doCreateMainClass:Bool = true;
	public var doCreateMakeFile:Bool = false;
	public var doCreateHaxelibJson:Bool = true;
	public var doCreateTravis:Bool = true;
	public var doCreateGitignore:Bool = true;
	public var doCreateReadme:Bool = true;
	public var doCreateHaxeDevelopProjects:Bool = true;
	public var doCreateVSCodeProject:Bool = false;
	public var doUseLix:Bool = false;
	
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
		
		if (!~/^[a-zA-Z0-9][a-zA-Z0-9 -_]{1,}/.match(name)) {
			throw ('[error] Invalid name "$name"');
			return;
		}
		
		if (FileSystem.exists(outPath)) {
			throw ('[error] $outPath already exist');
			return;
		}
		
		createOutPath();
		createBinPath();
		createPack();
		createMainClass();
		
		createBuildFiles();
		createRunFiles();
		createInstallFiles();
		createMakeFile();
		createHaxelibJson();
		createLixFiles();
		createTravis();
		createHaxeDevelopProjects();
		createVSCodeProject();
		createGitignore();
		createReadme();
		
		for (path in includes) {
			includeDirectory(path);
		}
		
		log("[completed] Project created: " + outPath);
	}

	private function createOutPath() {
		FileSystem.createDirectory(outPath);
	}
	
	private function createMainClass() {
		if (!doCreateMainClass) return;
		
		var main = File.getContent(Sys.getCwd() + '/template/src/Main.hx');
		main = replaceVars(main);
		var classPathDir = classPath != "" ? classPath.replace(".", "/") : "";
		File.saveContent(outPath + srcPath + classPathDir + "/Main.hx", main);
		
		log('[created] ${srcPath}${classPathDir}/Main.hx');
	}
	
	private function createInstallFiles() {
		if (doUseLix) return;
		
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
		log('[created] install.hxml');
	}
	
	private function createHaxelibJson() {
		if (!doCreateHaxelibJson) return;
		var dependencies = "";
		
		if (libs.length > 0) {
			for (lib in libs) dependencies += '    "$lib" : ""' + NEWLINE;
		}
		
		var targets_ = targets.copy();
		targets_.unshift("haxe");
		var tags = [for (target in targets_) '"$target"'].join(",");
		
		File.saveContent(outPath + "haxelib.json", replaceVars(File.getContent(Sys.getCwd() + '/template/haxelib.json')).replace("$dependencies", dependencies).replace("$tags", tags));
		log('[created] haxelib.json');
	}
	
	private function createTravis() {
		if (!doCreateTravis) return;
		
		var scripts = "";
		if (doUseLix) {
			scripts += '  - npm lix use haxe $$TRAVIS_HAXE_VERSION' + NEWLINE;
		}
		var haxeCommand = doUseLix ? "npm run haxe" : "haxe";
		if (targets.length > 1) {
			for (target in targets) {
				scripts += '  - $haxeCommand build-$target.hxml' + NEWLINE;
			} 
		} else {
			scripts += '  - $haxeCommand build.hxml' + NEWLINE;
		}
		
		File.saveContent(outPath + ".travis.yml", replaceVars(File.getContent(Sys.getCwd() + '/template/.travis.yml')).replace("$scripts", scripts));
		File.saveContent(outPath + "release_haxelib.sh", replaceVars(File.getContent(Sys.getCwd() + '/template/release_haxelib.sh')));
		log('[created] travis files');
	}
	
	private function createLixFiles() {
		if (!doUseLix) return;
		
		File.saveContent(outPath + "package.json", Json.stringify({
			name: '$name',
			version: "0.0.1",
			scripts: {
				lix: "lix",
				haxe: "haxe",
				haxelib: "haxelib",
				neko: "neko",
				postinstall: "lix download",
			}
		}));
		log('[created] package.json');

		log('[started] lix setup');
		var oldCwd = Sys.getCwd();
		Sys.setCwd(outPath);
		command("npm install lix --save-dev");
		command("npm run lix scope create");
		command("npm run lix use haxe stable");
		for (lib in libs) command("npm run lix install haxelib:" + lib);
		if (targets.has("nodejs")) command("npm run lix install haxelib:hxnodejs");
		if (targets.has("java")) command("npm run lix install haxelib:hxjava");
		if (targets.has("cpp")) command("npm run lix install haxelib:hxcpp");
		if (targets.has("cs")) command("npm run lix install haxelib:hxcs");
		
		if (doCreateHaxeDevelopProjects) command("node_modules\\.bin\\haxe.cmd --run resolve-args build.hxml > ide.hxml");
		
		Sys.setCwd(oldCwd);
		log('[completed] lix setup');
	}
	
	private function command(cmd:String) {
		log(cmd);
		Sys.command(cmd);
	}
	
	private function createVSCodeProject() {
		if (!doCreateVSCodeProject) return;
		FileSystem.createDirectory(outPath + '.vscode');
		log('[created] Visual Studio Code project files');
	}
	
	private function createHaxeDevelopProjects() {
		if (!doCreateHaxeDevelopProjects) return;
		var fullPathToMain = srcPath.replace("/","\\") + (classPath != "" ? classPath.replace(".","\\") + "\\Main.hx" : "\\Main.hx");
		
		var dependencies = "";
		if (libs.length > 0 && !doUseLix) {
			for (lib in libs) dependencies += '    <library name="$lib" />';
		}
		var lixBuildCommand = [
			'$$(ProjectDir)\\node_modules\\.bin\\haxe.cmd --run resolve-args build.hxml > ide.hxml',
			'$$(ProjectDir)\\node_modules\\.bin\\haxe.cmd build.hxml',
		].join("\r\n");
		var buildCommand = if (doUseLix) lixBuildCommand else 'cmd /c haxe $$(OutputFile)';
		
		if (targets.length > 1) {
			for (target in targets) {
				var run = getRunCommand(target) != null ? (doUseLix ? 'npm run haxe run-$target.hxml' : 'run-$target.hxml') : "";
				var projectFile = replaceVars(File.getContent(Sys.getCwd() + '/template/haxedevelop.hxproj.template'))
					.replace("$fullPathToMain", fullPathToMain)
					.replace("$build", if (doUseLix) 'ide.hxml' else 'build-$target.hxml')
					.replace("$preBuildCommand", buildCommand)
					.replace("$run", run)
					.replace("$libs", dependencies);
				File.saveContent(outPath + '${name}-${target}.hxproj', projectFile);
			}
		} else {
			var target = targets[0];
			var run = getRunCommand(target) != null ? (doUseLix ? 'npm run haxe run.hxml' : 'run.hxml') : "";
			var projectFile = replaceVars(File.getContent(Sys.getCwd() + '/template/haxedevelop.hxproj.template'))
				.replace("$fullPathToMain", fullPathToMain)
				.replace("$build", if (doUseLix) 'ide.hxml' else 'build.hxml')
				.replace("$preBuildCommand", buildCommand)
				.replace("$run", run)
				.replace("$libs", dependencies);
			File.saveContent(outPath + '${name}.hxproj', projectFile);
		}
		log('[created] HaxeDevelop project files');
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
		log('[created] makefile');
	}
	
	private function createGitignore() {
		if (!doCreateGitignore) return;
		var gitignoreFile = [binPath, ".git", "node_modules", "*.orig", ".svn", ".hg", "DS_Store", "*.orig", ".idea", "ide.hxml"].join("\n");
		File.saveContent(outPath + ".gitignore", gitignoreFile);
		log('[created] .gitignore');
	}
	
	private function createReadme() {
		if (!doCreateReadme) return;
		var readmeFile = "# " + name + NEWLINE + NEWLINE;
		
		readmeFile += "### Dependencies" + NEWLINE + NEWLINE;
		readmeFile += " * [Haxe](https://haxe.org/)" + NEWLINE;
		if (doUseLix) readmeFile += " * [Node.js](https://nodejs.org/)" + NEWLINE;
		
		// support libraries
		for (target in targets) {
			readmeFile += switch target {
				case "nodejs": ' * [hxnodejs](https://lib.haxe.org/p/hxnodejs)' + NEWLINE;
				case "cs": ' * [hxcs](https://lib.haxe.org/p/hxcs)' + NEWLINE;
				case "cpp": ' * [hxcpp](https://lib.haxe.org/p/hxcpp)' + NEWLINE;
				case "java": ' * [hxjava](https://lib.haxe.org/p/hxjava)' + NEWLINE;
				case "hl": ' * [HashLink](https://hashlink.haxe.org)' + NEWLINE;
				case "neko": ' * [Neko](https://nekovm.org)' + NEWLINE;
				default: "";
			}
		}
		
		if (libs.length > 0) {
			for (lib in libs) readmeFile += ' * [$lib](https://lib.haxe.org/p/$lib)' + NEWLINE;
		}
		
		readmeFile += NEWLINE;
		if (doUseLix) {
			readmeFile += "This project uses [lix.pm](https://github.com/lix-pm/lix.client) as Haxe package manager." + NEWLINE;
			readmeFile += "Run `npm install` to install the dependencies." + NEWLINE;
		} else {
			readmeFile += "Run `haxelib install all` to install the dependencies." + NEWLINE;
		}
		
		readmeFile += NEWLINE;
		
		var haxeCommand = doUseLix ? "npm run haxe" : "haxe";
		for (target in targets) {
			readmeFile += '### Compile ${target}' + NEWLINE + NEWLINE;
			readmeFile += '```' + NEWLINE;
			if (targets.length > 1) {
				readmeFile += '$haxeCommand build-$target.hxml' + NEWLINE;
			} else {
				readmeFile += '$haxeCommand build.hxml' + NEWLINE;
			}
			var command = getRunCommand(target);
			if (command != null) readmeFile += '$command' + NEWLINE;
			readmeFile += '```' + NEWLINE + NEWLINE;
		} 
		
		File.saveContent(outPath + "README.md", readmeFile);
		log('[created] README.md');
	}
	
	private function createBinPath() {
		FileSystem.createDirectory(outPath + binPath);
		for (target in targets) switch target {
			case "js": 
				// copy index.html
				File.saveContent(outPath + binPath + "index.html", replaceVars(File.getContent(Sys.getCwd() + '/template/bin/index.html')));
			default: 
		}
		log('[created] bin path: $outPath$binPath');
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
		log('[created] package: $classPath');
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
		
		var actualTarget = switch target {
			case "nodejs": "js";
			default: target;
		}
		hxml += '-$actualTarget ${getOutputPath(target)}' + NEWLINE;
		
		if (libs.length > 0) for (lib in libs) hxml += '-lib $lib' + NEWLINE;
		
		File.saveContent(outPath + file, hxml);
		log('[created] build file: $file');
	}
	
	private function createRunFiles() {
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
		var extension = switch target {
			case "js","nodejs": ".js";
			case "cs": "/bin/Main.exe";
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
			log('[created] run file: $file');
		}
	}
	
	private function getRunCommand(target:String) {
		var outputPath = getOutputPath(target);
		return switch target {
			case "nodejs": 'node $outputPath';
			case "python": 'python $outputPath';
			case "swf": 'run $outputPath';
			case "neko": (doUseLix ? 'npm run ' : '') + 'neko $outputPath';
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
		} catch (e:Dynamic) log('Failed to include "$dir"');
	}
	
	private inline function log(message:Message) {
		Sys.println(message.toString());
	}
}

abstract Message(String) {
	public inline function new(msg:String) this = msg;
	
	@:from public inline static function fromArray(arr:Array<Any>) {
		return new Message(arr.map(Std.string).join(", "));
	}
	
	@:from public inline static function fromString(msg:String) {
		return new Message(msg);
	}
	
	public inline function toString() return this;
}