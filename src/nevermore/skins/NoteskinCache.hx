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

	inline public function getMapKey(key:String, keyCount:Int, quants:Bool = false) {
		return key + keyCount + "k" + (quants ? "-quant" : "");
	}

	public function get(key:String, ?keyCount:Int, ?quants:Bool = false) {
		key = Path.normalize(key);
		keyCount ??= Nevermore.keyCount;

		set(key, keyCount, quants);
		return list.get(getMapKey(key, keyCount, quants));
	}

	public function set(key:String, ?keyCount:Int, ?quants:Bool = false) {
		key = Path.normalize(key);
		keyCount ??= Nevermore.keyCount;
		var mapKey = getMapKey(key, keyCount, quants); 

		if (exists(mapKey)) return;
		
		var data = getData(key, keyCount, quants);
		if (data == null) return;
		
		list.set(mapKey, data);
	}

	public function create(key:String, keyCount:Int, quants:Bool):Noteskin {
		key = Path.normalize(key);
		return getData(key, keyCount, quants);
	}

	// this is what you wanna override if you have your own asset system
	// (for example like fnf's)
	public function fromJson(key:String, keyCount:Int, file:String, root:String, findQuants:Bool) {
		var jsonPath = root + file + ".json";
		var content = Assets.exists(jsonPath) ? Assets.text(jsonPath) : Assets.dependency.text(jsonPath);
		var json = haxe.Json.parse(content);
		return new Noteskin(json, root, findQuants, key, keyCount);
	}

	public function fromSparrow(key:String, keyCount:Int, file:String) {
		return Noteskin.basic(file, key, keyCount);
	}

	public function getData(key:String, keyCount:Int, quants:Bool):Noteskin {
		var folder = key + (key.charCodeAt(key.length - 1) == '/'.code ? '' :  '/');

		inline function getLoadKeys(keys:Array<String>) {
			if (quants) {
				for (i in 0...keys.length)
					keys.insert(i * 2, keys[i * 2] + "-quant");
			}
			return keys;
		}

		var loadKeys = getLoadKeys([keyCount + "k", Path.withoutDirectory(key)]);
		for (i in 0...loadKeys.length) {
			var jsonPath = folder + loadKeys[i] + ".json";
			if (!Assets.exists(jsonPath) && !Assets.dependency.exists(jsonPath)) 
				continue;

			try {
				return fromJson(key, keyCount, loadKeys[i], folder, quants && i % 2 == 0);
			} catch (e) {}
		}

		for (loadKey in getLoadKeys([key])) {
			if (Assets.exists(loadKey + ".xml") || Assets.dependency.exists(loadKey + ".xml"))
				return fromSparrow(key, keyCount, loadKey);
		}

		return null;
	}
}