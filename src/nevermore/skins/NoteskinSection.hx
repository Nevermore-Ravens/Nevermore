package nevermore.skins;

import nevermore.play.BaseNote;
import nevermore.play.NoteObject;
import flixel.graphics.frames.FlxFramesCollection;

@:structInit
@:publicFields
class NoteskinAnim<T> {
	var name:String;
	var prefixes:Array<T>;
	var framerate:Float = 24;
	var looped:Bool = false;
}
typedef NoteskinAnimStruct<T> = {
	var ?name:String;
	var ?prefixes:Array<T>;
	var ?framerate:Float;
	var ?looped:Bool;
}

abstract class NoteskinSection<T> {
	static var _list:Map<String, Class<NoteskinSection<Any>>> = [];

	public static function register(name:String, cls:Class<NoteskinSection<Any>>) {
		_list.set(name, cls);
	}

	public static function create(parent:Noteskin, data:Dynamic) {
		var style:String = data.style ?? "sparrow";
		style = style.toLowerCase();
		
		var cls:Class<NoteskinSection<Any>> = SparrowSection;
		if (_list.exists(style))
			cls = _list.get(style);

		return Type.createInstance(cls, [parent, data]);
	}

	/**
	 * To be given in `NoteskinSection.new` (and preferably only there), a reference to the Noteskin instance holding this section.
	 */
	private var parent:Noteskin = null;
	/**
	 * To be loaded in `NoteskinSection.new`, a reference to the frames used for this section.
	 */
	private var frames:FlxFramesCollection = null;
	// later on, there may be a `luminFrames`, so noteskins dont need an entire `-quant` variant.
	// just throw in a `luminized` param in `apply` and `basicApply`.	

	/**
	 * Since NoteskinSection is abstract, this variable determines which extension to use.
	 *
	 * Typically "sparrow", but allows potential for other animation styles such as "grid".
	 */
	public var style:String = "sparrow";
	public var spritesheet:String;
	public var animations:Array<NoteskinAnim<T>>;
	public var scale:Float = 0.7;
	public var antialiasing:Bool = true;

	public var angles:Array<Float> = null;
	public var luminize:Array<Bool> = null;
	public var colors:Array<Int> = null;
	
	abstract public function apply(to:FlxSprite, lane:Int):Void;

	abstract function loadFrames(path:String):FlxFramesCollection;
	abstract function getBackupAnim():NoteskinAnim<T>;

	public function applyNoteObject(to:NoteObject) {
		apply(to, to.lane);

		if (colors != null)
			to.color = colors[to.lane % colors.length] ?? to.color;
		if (luminize != null)
			to.luminize = luminize[to.lane % luminize.length] ?? to.luminize;
	}
	function basicApply(to:FlxSprite, lane:Int) {
		if (to.frames != frames)
			to.frames = frames;
		to.antialiasing = antialiasing;
		to.scale.set(scale, scale);

		if (angles != null)
			to.angle = angles[lane % angles.length];
	}

	function loadAnimsFromData(data:Array<Dynamic>):Array<NoteskinAnim<T>> {
		var result:Array<NoteskinAnim<T>> = [];

		for (a in data) {
			var anim:NoteskinAnimStruct<T> = a;
			if (anim.name == null || anim.prefixes == null)
				continue;

			result.push({
				name: anim.name,
				prefixes: anim.prefixes,
				framerate: anim.framerate ?? 24,
				looped: anim.looped ?? false
			});
		}

		if (result.length == 0)
			result.push(getBackupAnim());
		return result;
	}

	// i may have to figure out a better way for this, there's a lot of parameters
	public function new(style:String, parent:Noteskin, spritesheet:String, animations:Array<NoteskinAnim<T>>, ?scale:Float, ?antialiasing:Bool, ?angles:Array<Float>, ?colors:Array<Int>, ?luminize:Array<Bool>) {
		this.style = style;
		this.spritesheet = spritesheet;
		this.animations = animations;
		this.scale = scale ?? parent.scale;
		this.antialiasing = antialiasing ?? parent.antialiasing;
		
		this.angles = angles;
		this.colors = colors;
		this.luminize = luminize;

		this.frames = parent.getFrames(spritesheet, loadFrames);
	}
}