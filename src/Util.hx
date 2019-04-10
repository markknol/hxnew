package;

/**
 * @author Mark Knol
 */
class Util {
	public static macro function getHaxelibVersion() {
		var haxelib:{ version:String } = haxe.Json.parse(sys.io.File.getContent("haxelib.json"));
		return macro $v{haxelib.version};
	}
}