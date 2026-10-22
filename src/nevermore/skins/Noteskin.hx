package nevermore.skins;

import nevermore.play.BaseNote;
import nevermore.play.NoteObject;
import nevermore.play.Note;
import flixel.graphics.frames.FlxFramesCollection;
import haxe.io.Path;

class Noteskin {
	public static var cache:NoteskinCache = new NoteskinCache();

	public static function load(key:String, ?keyCount:Int) {
		cache.set(key, keyCount);
	}

	public static function get(key:String, ?keyCount:Int, ?quants:Bool = false):Noteskin {
		quants = Nevermore.settings.quantization && quants; // i may remove this
		return cache.get(key, keyCount, quants);
	}

	public static function clear() {
		cache.clear();
	}

	public static dynamic function findFallback(from:Noteskin, skin:Dynamic) {
		try {
			// do NOT, return itself.
			inline function doubleCheck(result:Noteskin)
				return result == from ? null : result;

			if (Reflect.isObject(skin)) {
				skin.keyCount = skin.keyCount != null && skin.keyCount is Int ? skin.keyCount : from.loadKeyCount;
				skin.luminized = skin.luminized != null && skin.luminized is Bool ? skin.luminized : from.alreadyLuminized;

				if (skin.key != null && skin.key is String)
					return doubleCheck(get(Path.join([from.loadKey, skin.key]), skin.keyCount, skin.luminized));
				return doubleCheck(from.findRelative(skin.keyCount, skin.luminized));
			}

			if (skin is Int)
				return doubleCheck(from.findRelative(cast skin));
			if (skin is Bool)
				return doubleCheck(from.findRelative(from.loadKeyCount, cast skin));

			// it's interesting since this seems like the most typical option but ends up being one of the worst
			var path:String = cast skin;
			return Noteskin.cache.fromJson(Path.join([from.loadKey, Path.directory(path)]), from.loadKeyCount, path, from.root, from.alreadyLuminized);
		} catch(e) {
			return null;
		}
	}

	/**
	 * Used for sharing frame collections across sections.
	 */
	private var frames:Map<String, FlxFramesCollection> = [];
	/**
	 * Whether or not noteskin section spritesheets should try to search for a -luminized variant first.
	 */
	public var alreadyLuminized:Bool = false;
	public var sections:Map<String, NoteskinSection<Dynamic>> = [];

	public var root:String = "";
	public var spacing:Float = 160 * 0.7;
	public var scale:Float = 0.7;
	public var antialiasing:Bool = true;

	public var loadKey:String;
	public var loadKeyCount:Int;
	public var fallback:Noteskin;

	/**
	 * Self-explainitory, goes through all the sections and modifies their scale.
	 *
	 * @param factor The amount to multiply by, or set if `set` is true.
	 * @param set If the scale should directly be set to `factor` instead of multiplying, leaving no influence from the original value.
	 */
	public function scaleAllSections(factor:Float, ?set:Bool = false) {
		var ogScale = scale;
		scale = factor * (set ? 1 : scale);
		spacing *= scale / ogScale;
		for (sect in sections)
			sect.scale = factor * (set ? 1 : sect.scale);
	}

	public function findRelative(?keyCount:Int, ?luminized:Bool) {
		keyCount ??= loadKeyCount;
		luminized ??= alreadyLuminized;
		if (keyCount == loadKeyCount && luminized == alreadyLuminized)
			return this;
		return get(loadKey, keyCount, alreadyLuminized);
	}

	public function new(data:Dynamic, ?root:String = "", ?alreadyLuminized:Bool = false, ?loadKey:String = "", ?loadKeyCount:Int = 0) {
		this.root = root + (root.length == 0 || root.charCodeAt(root.length - 1) == '/'.code ? '' :  '/');
		this.alreadyLuminized = alreadyLuminized;
		this.loadKey = loadKey;
		this.loadKeyCount = loadKeyCount;

		var instanceFields = Type.getInstanceFields(Noteskin);
		var fields = Reflect.fields(data);

		for (field in fields) {
			if (field == "fallback")
				continue;

			var obj = Reflect.field(data, field);
			if (Reflect.isObject(obj))
				sections.set(field, NoteskinSection.create(this, obj));
			else if (instanceFields.contains(field))
				Reflect.setProperty(this, field, obj);
		}

		if (!fields.contains("spacing") && fields.contains("scale"))
			spacing = 160 * scale;
		if (fields.contains("fallback"))
			fallback = findFallback(this, data.fallback);
	}

	public function hasSection(section:String) {
		return sections.exists(section) || (fallback != null && fallback.hasSection(section));
	}
	public function apply(to:FlxSprite, lane:Int, luminized:Bool, section:String):Bool {
		if (sections.exists(section)) {
			sections.get(section).apply(to, lane, luminized);
			return true;
		}
		// try the fallback if existant, otherwise false
		return fallback != null && fallback.apply(to, lane, luminized, section);
	}
	public function applyNoteObject(to:NoteObject, section:String) {
		if (sections.exists(section)) {
			sections.get(section).applyNoteObject(to);
			return true;
		}
		// try the fallback if existant, otherwise false
		return fallback != null && fallback.applyNoteObject(to, section);
	}
	public function applyToNote(to:BaseNote, section:String) {
		var result = inline applyNoteObject(to, section);
		to.scale.scale(to.strumline.size * to.strumline.keyScale);
		to.updateHitbox();
		return result;
	}

	public function append(data:Dynamic) {
		var fields = Reflect.fields(data);

		for (field in fields) {
			var obj = Reflect.field(data, field);
			if (Reflect.isObject(obj))
				sections.set(field, NoteskinSection.create(this, obj));
		}
	}

	public function getFrames(path:String, fallback:String->FlxFramesCollection, ?luminized:Bool = false) {
		var luminFrames = luminized ? getFrames(path + "-luminized", fallback) : null;
		if (luminFrames != null)
			return luminFrames;

		if (frames.exists(path))
			return frames.get(path);

		var newFrames = fallback(root + path);
		frames.set(path, newFrames);
		return newFrames;
	}
}