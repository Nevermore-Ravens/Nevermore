package nevermore.core;

import openfl.display.BitmapData;
import openfl.media.Sound;
import openfl.system.System;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import lime.media.AudioBuffer;
import haxe.io.Path;

/**
* Handles directing and returning asset-related objects such as images and audio.
**/
class AssetHandler {
	public var root:String = '';
	public function new(root:String = '') {
		this.root = root;
	}

	/**
	* The list of image formats this handler supports.
	**/
	public var imageFormats:Array<String> = ['png', 'jpg', 'jpeg'];

	/**
	* The list of audio formats this handler supports.
	* FLaC and MP3 are limited to Lime 8.4.0 only, as it uses
	* SDL_sound instead of their own decoders.
	**/
	public var audioFormats:Array<String> = [
		#if (lime >= version("8.4.0"))
		'ogg', 'wav', 'flac', 'mp3'
		#else
		'ogg', 'wav'
		#end
	];

	/**
	* Returns an instance of `flixel.graphics.FlxGraphic` for the file specified.
	*
	* @param key The path to the file. (ex. `images/test.png`, `images/test`)
	* @return A `FlxGraphic` instance of the file.
	**/
	public function image(key:String):FlxGraphic {
		var path:String = getPath(key, imageFormats);

		if (Assets.cache.exists(path)) {
			return switch Assets.cache.get(path).src {
				case Graphic(graphic): graphic;
				default: null;
			}
		}

		var bitmap:BitmapData = BitmapData.fromFile(path);
		final graphic:FlxGraphic = FlxGraphic.fromBitmapData(bitmap, false, path);
		graphic.persist = true;
		graphic.destroyOnNoUse = false;

		Assets.cache.set(path, {src: Graphic(graphic)});
		return graphic;
	}

	/**
	* Returns a decoded instance of `openfl.media.Sound` for the file specified.
	*
	* @param key The path to the file. (ex. `audio/test.ogg`, `audio/test`)
	* @return A `Sound` instance of the file.
	**/
	public function audio(key:String):Sound {
		var path:String = getPath(key, audioFormats);

		if (Assets.cache.exists(path)) {
			return switch Assets.cache.get(path).src {
				case Audio(sound): sound;
				default: null;
			}
		}

		var sound:Sound = Sound.fromAudioBuffer(AudioBuffer.fromFile(path));
		Assets.cache.set(path, {src: Audio(sound)});
		return sound;
	}

	/**
	* Returns a streamed instance of `openfl.media.Sound` for the file specified.
	* If the Lime version specified is anything older than `8.4.0`,
	* it will default to decoding instead.
	*
	* @param key The path to the file. (ex. `audio/test.ogg`, `audio/test`)
	* @return A `Sound` instance of the file.
	**/
	public function streamedAudio(key:String):Sound {
		#if (lime >= version("8.4.0"))
		var path:String = getPath(key, audioFormats);

		if (Assets.cache.exists(path)) {
			return switch Assets.cache.get(path).src {
				case Audio(sound): sound;
				default: null;
			}
		}

		var sound:Sound = Sound.fromAudioBuffer(AudioBuffer.fromFileStream(path));
		Assets.cache.set(path, {src: Audio(sound)});
		return sound;
		#else
		return audio(key);
		#end
	}

	/**
	* Returns the content of a file via the given file path.
	* If the file does not exist, an empty string is returned instead.
	*
	* @param key The path to the file. (ex. `data/test.txt`)
	* @return The contents of the file.
	**/
	public function text(key:String):String {
		var key:String = getPath(key);

		if (!FileSystem.exists(key)) return '';
		return sys.io.File.getContent(key);
	}

	/**
	* Returns a sparrow atlas, via the path specified.
	*
	* @param key The path to the sparrow atlas.
	* Both the `xml` and image must be named the same way
	* (`images/test.png`, `images/test.xml`) -> `images/test`
	* @return A `FlxAtlasFrames` instance for said sparrow atlas.
	**/
	public function sparrowAtlas(key:String):FlxAtlasFrames {
		var graphic:FlxGraphic = image(key);
		var xml:String = text(key + '.xml');
		return FlxAtlasFrames.fromSparrow(graphic, xml);
	}

	/**
	* Combines multiple sparrow atlases into one atlas, via a set list of paths.
	* @param keys The paths to each sparrow atlas.
	* See `sparrowAtlas()` for how to specify the path correctly.
	* @return The combined instance of `FlxAtlasFrames`.
	**/
	public function multiAtlas(keys:Array<String>):FlxAtlasFrames {
		var parentFrames = sparrowAtlas(keys[0]);
		if (keys.length == 1) return parentFrames;

		if (parentFrames == null) return null;

		for (i in 1...keys.length) {
			var extraFrames = sparrowAtlas(keys[i]);
			if (extraFrames == null) continue;
			parentFrames = parentFrames.addAtlas(extraFrames);
		}
		
		return parentFrames;
	}

	public function exists(key:String):Bool {
		return sys.FileSystem.exists(getPath(key));
	}

	/**
	* Grabs the full path of a file.
	*
	* @param key The relative path to the file.
	* For mitigating possible performance drops, I suggest appending a file extension to `key`
	* to reduce any file checking that isn't needed, depending on your scenario.
	*
	* @param extensions Any extensions/formats the handler should look out for.
	* If none are specified, it'll assume there's already a file extension applied to `key`, and 
	* will ignore it.
	*
	* @return The full path to the file, including the extension.
	**/
	public dynamic function getPath(key:String, ?extensions:Array<String>):String {
		var path = new Path('$root/$key');

		// assume there's already a file extension applied
		if (path.ext.length != 0) return path.toString();

		extensions ??= [];
		for (ext in extensions) {
			path.ext = ext;
			if (FileSystem.exists(path.toString())) break;
		}

		return path.toString();
	}
}

/**
* A global instance container for game assets, as well as
* being able to access assets specifically for Nevermore.
**/
class Assets {
	/**
	* The root directory that assets will be looked in for.
	* Change this before calling `Assets.init()` if you have a
	* different name for your assets.
	**/
	public static var rootFolder:String = 'assets';

	/**
	* The main instance for all assets.
	* Modify/use this for your game, if need be.
	**/
	public static var main:AssetHandler;

	/**
	* Made specifically for assets that Nevermore needs.
	* Don't touch this, unless you absolutely know what you're doing.
	**/
	public static var dependency:AssetHandler;

	/**
	* The global cache for all assets.
	* Both `main` and `dependency` use this, so modify it wisely.
	**/
	public static var cache:AssetCache;

	/**
	* Initializes the asset system.
	**/
	public static function init() {
		cache = new AssetCache();

		main = new AssetHandler(rootFolder);
		dependency = new AssetHandler('nevermore');
	}

	// helper functions

	public static function image(key:String):FlxGraphic {
		return main.image(key);
	}

	public static function audio(key:String):Sound {
		return main.audio(key);
	}

	public static function streamedAudio(key:String):Sound {
		return main.streamedAudio(key);
	}

	public static function text(key:String):String {
		return main.text(key);
	}

	public static function sparrowAtlas(key:String):FlxAtlasFrames {
		return main.sparrowAtlas(key);
	}

	public static function multiAtlas(keys:Array<String>):FlxAtlasFrames {
		return main.multiAtlas(keys);
	}

	public static function exists(key:String):Bool {
		return main.exists(key);
	}

	public static function getPath(key:String):String {
		return main.getPath(key);
	}
}

enum Asset {
	Graphic(g:FlxGraphic);
	Audio(s:Sound);
}

@:structInit
class AssetData {
	public var src:Asset;
}

/**
* Handles storing assets that are currently being used by the game.
**/
class AssetCache {
	var map:Map<String, AssetData>;
	var currentlyUsed:Array<String> = [];

	/**
	* Checks if a specific asset exists in the cache.
	* @param key The absolute path to the cached file. (ex. `assets/images/test.png`)
	* @return If the file is cached or not.
	**/
	public function exists(key:String):Bool {
		return map.exists(key);
	}

	/**
	* Returns the instance of the specified file in the cache.
	* @param key The absolute path to the cached file. (ex. `assets/images/test.png`)
	* @return The instance of the cached file.
	* If the file does not exist in the cache, the result is unspecified.
	**/
	public function get(key:String):AssetData {
		return map[key];
	}

	/**
	* Puts a file in the cache.
	* @param key The absolute path to the file. (ex. `assets/images/test.png`)
	* @param value The asset to be cached.
	* @return The now cached asset.
	**/
	public function set(key:String, value:AssetData):AssetData {
		if (exists(key)) return value;
		map.set(key, value);
		if (!currentlyUsed.contains(key)) currentlyUsed.push(key);

		return value;
	}

	/**
	* Clears any assets in the cache that are currently not used.
	**/
	public function clearUnused() {
		for (key => asset in map) {
			if (currentlyUsed.contains(key)) continue;	
			destroyAsset(key, asset);
		}

		System.gc();
	}

	/**
	* Clears the entire cache, as if the game just opened.
	**/
	public function clear() {
		for (key => asset in map) {
			destroyAsset(key, asset);
		}

		currentlyUsed.resize(0);
		System.gc();
	}

	/**
	* Destroys a specified asset, and automatically removes it from the cache if it exists.
	* @param key The absolute path to the cached file. (ex. `assets/images/test.png`)
	* @param asset The asset to destroy. If it is null, it will find it on its own
	* via the given `key` parameter.
	**/
	public function destroyAsset(key:String, ?asset:AssetData) {
		asset ??= map[key];
		if (asset == null) return;

		switch asset.src {
			case Graphic(graphic):
				FlxG.bitmap.remove(graphic);
				graphic = null;

			case Audio(audio):
				audio.close();
				audio = null;
		}

		asset = null;
		map.remove(key);
	}
	
	public function new() {
		map = new Map<String, AssetData>();
	}
}