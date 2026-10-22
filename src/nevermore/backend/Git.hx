package nevermore.backend;

import sys.io.Process;

@:structInit
@:publicFields
class Commit {
	var shortHash:String = '';
	var longHash:String = '';
	var count:Int = 0;
}

/**
* Provides Git history about Nevermore, like the current commit (short/long) hash,
* commit count, and the branch.
*
* Requires a `.git` folder in the library's root folder,
* and for `--depth=1` to not be applied.
**/
class Git {
	public static var commit(get, never):Commit;
	static function get_commit():Commit {
		return {
			shortHash: getShortHash(),
			longHash: getLongHash(),
			count: getCommitCount()
		}
	}

	public static var branch(get, never):String;
	static function get_branch():String {
		return getBranch();
	}

	static macro function getShortHash() {
		return macro $v{gitProcess(['rev-parse', '--short', 'HEAD']) ?? '???'};
	}

	static macro function getLongHash() {
		return macro $v{gitProcess(['rev-parse', 'HEAD']) ?? '???'};
	}

	static macro function getCommitCount() {
		return macro $v{Std.parseInt(gitProcess(['rev-list', '--count', 'HEAD']) ?? '0')};
	}

	static macro function getBranch() {
		return macro $v{gitProcess(['branch', '--show-current']) ?? '???'};
	}

	// haxe i should kill you for running all macros in the project folder
	// and not where the macro originates
	static function gitProcess(args:Array<String>) {
		var lastWd:String = Sys.getCwd();

		Sys.setCwd(runProcess('haxelib', ['path', 'nevermore']));
		var result = runProcess('git', args);
		Sys.setCwd(lastWd);

		return result;
	}

	static function runProcess(name:String, ?args:Array<String>) {
		args ??= [];

		try {
			var process = new Process(name, args, false);
			var result:String = process.stdout.readLine().toString();
			process.close();
			return result;
		} catch (e:haxe.Exception) {
			Sys.println('failed process "$name" with $args: $e');
			return null;
		}
	}
}