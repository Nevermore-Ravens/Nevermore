package nevermore.core;

import openfl.display.BitmapData;
import openfl.media.Sound;
import openfl.system.System;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import lime.media.AudioBuffer;
import haxe.io.Path;

class AssetHandler {
	public var root:String = '';
	public function new(root:String = '') {
		this.root = root;
	}

	public var imageFormats:Array<String> = ['png', 'jpg', 'jpeg'];

	// flac/mp3 are 8.4.0 only
	// because of sdl_sound support
	public var audioFormats:Array<String> = [
		#if (lime >= version("8.4.0"))
		'ogg', 'wav', 'flac', 'mp3'
		#else
		'ogg', 'wav'
		#end
	];

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

	public function audio(key:String):Sound {
		var path:String = getPath(key, audioFormats);

		if (Assets.cache.exists(path)) {
			return switch Assets.cache.get(path).src {
				case Audio(sound): sound;
				default: null;
			}
		}

		// i hate that this is called sound
		// but this is function is called audio
		// and so is the enum
		var sound:Sound = Sound.fromAudioBuffer(AudioBuffer.fromFile(path));
		Assets.cache.set(path, {src: Audio(sound)});
		return sound;
	}

	// TODO:
	// only tested on lime develop
	// somehow figure out how to make it work for pre-8.4.0?
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

	public function text(key:String):String {
		var key:String = getPath(key);

		if (!FileSystem.exists(key)) return '';
		return sys.io.File.getContent(key);
	}

	// no need to cache something like this
	// apparently it's fast enough ????
	public function sparrowAtlas(key:String):FlxAtlasFrames {
		var graphic:FlxGraphic = image(key);
		var xml:String = text(key + '.xml');
		return FlxAtlasFrames.fromSparrow(graphic, xml);
	}

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

	// for faster access i suggest writing your paths like `assets/file.ext`
	// unless you're grabbing a file that can be multiple extensions (like a song or something)
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

// basically just a wrapper for `main`
class Assets {
	public static var rootFolder:String = 'assets';

	public static var main:AssetHandler;
	public static var dependency:AssetHandler;

	public static var cache:AssetCache;
	public static function init() {
		cache = new AssetCache();

		main = new AssetHandler(rootFolder);
		dependency = new AssetHandler('nevermore');
	}

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

class AssetCache {
	var map:Map<String, AssetData>;
	var currentlyUsed:Array<String> = [];

	public function exists(key:String) {
		return map.exists(key);
	}

	public function get(key:String):AssetData {
		return map[key];
	}

	public function set(key:String, value:AssetData):AssetData {
		if (exists(key)) return value;
		map.set(key, value);
		if (!currentlyUsed.contains(key)) currentlyUsed.push(key);

		return value;
	}

	public function clearUnused() {
		for (key => asset in map) {
			if (currentlyUsed.contains(key)) continue;	
			destroyAsset(key, asset);
		}

		System.gc();
	}

	public function clear() {
		for (key => asset in map) {
			destroyAsset(key, asset);
		}

		currentlyUsed.resize(0);
		System.gc();
	}

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