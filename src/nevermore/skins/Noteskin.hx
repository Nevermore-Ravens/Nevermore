package nevermore.skins;

import nevermore.play.BaseNote;
import nevermore.play.NoteObject;
import nevermore.play.Note;
import flixel.graphics.frames.FlxFramesCollection;

class Noteskin {
	public static var cache:NoteskinCache = new NoteskinCache();

	public static function load(key:String, keyCount:Int = 0) {
		cache.set(key, keyCount);
	}

	public static function get(key:String, keyCount:Int, ?quants:Bool = false):Noteskin {
		quants = Nevermore.settings.quantization && quants; // i may remove this
		return cache.get(key, keyCount, quants);
	}

	public static function clear() {
		cache.clear();
	}

	/**
	 * The scale to use for `Noteskin.basic`.
	 */
	public static var basicScale:Float = 0.7;
	/**
	 * Loads a skin using only a sparrow atlas.
	 *
	 * @param key Which sparrow atlas to load.
	 */
	public static function basic(key:String) {
		return new Noteskin({
			scale: basicScale, // Use a static variable so people don't have to edit `NoteskinCache.getData`.

			receptor: {
				style: "sparrow", // this one actually isnt necessary but....
				spritesheet: key,
				animations: [
					{
						name: "standard",
						prefixes: [for (dir in Note.directions) 'arrow${dir.toUpperCase()}'],
						looped: true
					},
					{
						name: "pressed",
						prefixes: [for (dir in Note.directions) '$dir press']
					},
					{
						name: "glow",
						prefixes: [for (dir in Note.directions) '$dir confirm']
					},
				]
			},

			note: {
				style: "sparrow",
				spritesheet: key,
				animations: [{
					name: "standard",
					prefixes: [for (col in Note.colors) '${col}0'],
					looped: true
				}]
			},

			sustain: {
				style: "sparrow",
				spritesheet: key,
				animations: [
					{
						name: "piece",
						prefixes: [for (col in Note.colors) '${col} hold piece'],
						looped: true
					},
					{
						name: "tail",
						prefixes: [for (col in Note.colors) '${col} hold end'],
						looped: true
					}
				]
			},

			roll: {
				style: "sparrow",
				spritesheet: key,
				animations: [
					{
						name: "piece",
						prefixes: [for (col in Note.colors) '${col} roll piece'],
						looped: true
					},
					{
						name: "tail",
						prefixes: [for (col in Note.colors) '${col} roll end'],
						looped: true
					}
				]
			}
		});
	}

	public static dynamic function findFallback(from:Noteskin, skin:String) {
		try {
			return Noteskin.cache.fromJson(skin, from.root, from.findQuants);
		} catch(e) {
			return null;
		}
	}

	/**
	 * Used for sharing frame collections across sections.
	 */
	private var frames:Map<String, FlxFramesCollection> = [];
	/**
	 * Whether or not noteskin section spritesheets should try to search for a -quant variant first.
	 */
	private var findQuants:Bool = false;
	public var sections:Map<String, NoteskinSection<Dynamic>> = [];

	public var root:String = "";
	public var spacing:Float = 160 * 0.7;
	public var scale:Float = 0.7;
	public var antialiasing:Bool = true;

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

	public function new(data:Dynamic, ?root:String = "", ?findQuants:Bool = false) {
		this.root = root + (root.length == 0 || root.charCodeAt(root.length - 1) == '/'.code ? '' :  '/');
		this.findQuants = findQuants;
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
	public function apply(to:FlxSprite, lane:Int, section:String):Bool {
		if (sections.exists(section)) {
			sections.get(section).apply(to, lane);
			return true;
		}
		// try the fallback if existant, otherwise false
		return fallback != null && fallback.apply(to, lane, section);
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

	public function getFrames(path:String, fallback:String->FlxFramesCollection) {
		if (frames.exists(path))
			return frames.get(path);

		var newFrames = fallback(root + (findQuants ? path + "-quant" : path));
		if (newFrames == null && findQuants)
			newFrames = fallback(root + path);

		frames.set(path, newFrames);
		return newFrames;
	}
}