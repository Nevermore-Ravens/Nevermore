package nevermore.skins;

import nevermore.skins.Noteskin;
import haxe.io.Path;

class NoteskinCache {
	var list:Map<String, Noteskin> = [];
	public function new() {}

	public function exists(key:String):Bool {
		return list.exists(key);
	}

	public function clear() {
		list.clear();
	}

	inline public function getMapKey(key:String, keyCount:Int, luminized:Bool) {
		return key + keyCount + "k" + (luminized ? "-luminized" : "");
	}

	public function get(key:String, ?keyCount:Int, ?luminized:Bool = false) {
		key = Path.normalize(key);
		keyCount ??= Nevermore.keyCount;

		set(key, keyCount, luminized);
		return list.get(getMapKey(key, keyCount, luminized));
	}

	public function set(key:String, ?keyCount:Int, ?luminized:Bool = false) {
		key = Path.normalize(key);
		keyCount ??= Nevermore.keyCount;
		var mapKey = getMapKey(key, keyCount, luminized); 

		if (exists(mapKey)) return;
		
		var data = getData(key, keyCount, luminized);
		if (data == null) return;
		
		list.set(mapKey, data);
	}

	public function create(key:String, keyCount:Int, luminized:Bool):Noteskin {
		key = Path.normalize(key);
		return getData(key, keyCount, luminized);
	}

	// this is what you wanna override if you have your own asset system
	// (for example like fnf's)
	public function fromJson(key:String, keyCount:Int, file:String, root:String, alreadyLuminized:Bool) {
		var jsonPath = root + file + ".json";
		var content = Assets.exists(jsonPath) ? Assets.text(jsonPath) : Assets.dependency.text(jsonPath);
		var json = haxe.Json.parse(content);
		return new Noteskin(json, root, alreadyLuminized, key, keyCount);
	}

	public function fromSparrow(key:String, keyCount:Int, luminized:Bool) {
		return Noteskin.basic(key, keyCount, luminized);
	}

	public function getData(key:String, keyCount:Int, luminized:Bool):Noteskin {
		var folder = key + (key.charCodeAt(key.length - 1) == '/'.code ? '' :  '/');

		inline function getLoadKeys(keys:Array<String>) {
			if (luminized) {
				for (i in 0...keys.length)
					keys.insert(i * 2, keys[i * 2] + "-luminized");
			}
			return keys;
		}

		var loadKeys = getLoadKeys([keyCount + "k", Path.withoutDirectory(key)]);
		for (i in 0...loadKeys.length) {
			var jsonPath = folder + loadKeys[i] + ".json";
			if (!Assets.exists(jsonPath) && !Assets.dependency.exists(jsonPath)) 
				continue;

			try {
				return fromJson(key, keyCount, loadKeys[i], folder, luminized && i % 2 == 0);
			} catch (e) {}
		}

		loadKeys = getLoadKeys([key]);
		for (i in 0...loadKeys.length) {
			if (Assets.exists(loadKeys[i] + ".xml") || Assets.dependency.exists(loadKeys[i] + ".xml"))
				return fromSparrow(loadKeys[i], keyCount, luminized && i % 2 == 0);
		}

		return null;
	}
}