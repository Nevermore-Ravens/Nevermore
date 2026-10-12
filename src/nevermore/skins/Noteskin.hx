package nevermore.skins;

import nevermore.play.BaseNote;
import nevermore.play.Note;
import flixel.graphics.frames.FlxFramesCollection;

class Noteskin {
	public static var cache:NoteskinCache = new NoteskinCache();

	public static function load(key:String) {
		cache.set(key);
	}

	public static function get(key:String, ?quants:Bool = false):Noteskin {
		quants = Nevermore.settings.quantization && quants;
		return cache.get(key, quants);
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

	/**
	 * Used for sharing frame collections across sections.
	 */
	private var frames:Map<String, FlxFramesCollection> = [];
	/**
	 * Whether or not noteskin section spritesheets should try to search for a -quant variant first.
	 */
	private var findQuants:Bool = false;
	public var sections:Map<String, NoteskinSection<Dynamic>> = [];

	public var spacing:Float = 160 * 0.7;
	public var scale:Float = 0.7;
	public var supportsXKeys = false;
	public var antialiasing:Bool = true;

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

	public function new(data:Dynamic, ?findQuants:Bool = false) {
		this.findQuants = findQuants;
		var instanceFields = Type.getInstanceFields(Noteskin);
		var fields = Reflect.fields(data);

		for (field in fields) {
			var obj = Reflect.field(data, field);
			if (Reflect.isObject(obj))
				sections.set(field, NoteskinSection.create(this, obj));
			else if (instanceFields.contains(field))
				Reflect.setProperty(this, field, obj);
		}

		if (!fields.contains("spacing") && fields.contains("scale"))
			spacing = 160 * scale;
	}

	public function apply(to:FlxSprite, lane:Int, section:String) {
		sections.get(section).apply(to, supportsXKeys ? lane : lane % 4);
	}
	public function applyToNote(to:BaseNote, section:String) {
		inline apply(to, to.lane, section);
		to.scale.scale(to.strumline.size * to.strumline.keyScale);
		to.updateHitbox();
	}

	public function getFrames(path:String, fallback:String->FlxFramesCollection) {
		if (frames.exists(path))
			return frames.get(path);

		var newFrames = fallback(findQuants ? path + "-quant" : path);
		if (newFrames == null && findQuants)
			newFrames = fallback(path);

		frames.set(path, newFrames);
		return newFrames;
	}
}