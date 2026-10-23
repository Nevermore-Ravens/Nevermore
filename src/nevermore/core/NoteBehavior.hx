package nevermore.core;

import nevermore.play.Note;
import nevermore.play.BaseNote;

enum abstract ObjectType(Int) {
	var NOTE;
	var SUSTAIN;
	var RECEPTOR;
} 

/**
* Allows for modifying how a specific type of note should behave.
* Also acts as an instanced object, much like `Judgement`.
*
* ```hx
* var mineType:NoteBehavior = NoteBehavior.get('Mine');
* trace(mineType.normalized);
* trace(mineType.punishable);
* ```
*
* To make/add your own behaviors, extend this class and call `register()`
* with the name of your behavior.
* (see `play/behaviors/MineBehavior` and `play/behaviors/FakeBehavior`)
* ```hx
* NoteBehavior.register('Instakill Note', InstakillNoteBehavior);
* ```
**/
class NoteBehavior {
	/**
	* The list of behaviors that Nevermore knows of.
	* To write to this, use `register()`.
	* To read this, use either `getList()` or `get()`.
	**/
	static var _list:Map<String, NoteBehavior> = [];

	public static var base:NoteBehavior = new NoteBehavior();

	/**
	* Returns a list of what behaviors are currently registered.
	**/
	public static function getList():Array<NoteBehavior> {
		return [for (k in _list) k];
	}

	/**
	* Registers a behavior for Nevermore to use.
	* Also allows for overriding behaviors that Nevermore already uses.
	* @param name The name of the behavior. Must be the same name that is in
	* the chart, otherwise it will not recognize it.
	* @param cls The static class of the behavior.
	**/
	public static function register(name:String, cls:Class<NoteBehavior>) {
/*		if (_list.exists(name)) {
			var behavior:NoteBehavior = _list[name];

			FlxG.sound.list.remove(behavior.hitsound);
			behavior.hitsound.destroy();
			behavior.hitsound = null;
		}*/

		_list.set(name, Type.createInstance(cls, []));
	}

	/**
	* Returns an instance of a behavior via name.
	* @param name The name of the behavior to look for.
	* @return The instance of the behavior.
	* If `name` is either blank, or the behavior does not exist,
	* it will return a base behavior instance instead.
	**/
	public static function get(name:String):NoteBehavior {
		if (name.length == 0 || !_list.exists(name)) {
			return base;
		}
		
		return _list[name];
	}

	/**
	* Whether this behavior should make the corresponding note
	* missable or not. If this is true, the note will do
	* nothing when it is in the miss window.
	**/
	public var ignore:Bool = false;

	/**
	* If this behavior should make the corresponding note able to
	* be registered hittable at all.
	**/
	public var hittable:Bool = true;

	/**
	* The padding window to allow for missing, in milliseconds.
	**/
	public var missPadding:Float = 25;

	/**
	* The amount of health this behavior will give to the player upon being hit.
	* If null, it utilizes the judgement's health instead.
	**/
	public var hitHealth:Null<Float>;

	/**
	* The amount of health this behavior will give to the player upon being missed.
	* If null, it utilizes the judgement's health instead.
	**/
	public var missHealth:Null<Float>;

	/**
	* How much this behavior will multiply either `missHealth` or `hitHealth`.
	**/
	public var healthMult:Float = 1;

	/**
	* If this behavior allows for assigning a judgement to the player.
	**/
	public var judgemental:Bool = true; // my feelings :(

	/**
	* Whether this behavior will punish the player upon hitting it.
	**/
	public var punishable:Bool = false;

	/**
	* If `this` behavior doesn't affect how the corresponding note can be judged.
	* This means the corresponding note behaves much like a normal note, but can have/add 
	* additional behavior of its own.
	**/
	public var normalized(get, never):Bool;
	function get_normalized():Bool return hittable && !punishable;

	/**
	* The connected hitsound of this behavior that will play upon being hit.
	* Make sure that when adding this to your own behaviors, you set `persist = true;`,
	* otherwise HaxeFlixel will destroy it upon changing `FlxState`'s.
	**/
	public var hitsound:FlxSound = new FlxSound();

	public function new() {}

	/**
	* Applies a skin to a specific note/behavior.
	* @param note The note object to modify/apply.
	* @param type The type of object given.
	**/
	public function applySkin(note:BaseNote, type:ObjectType) {
		note.strumline.skin.applyToNote(note, type == NOTE ? "note" : "sustain");
	}

	/**
	* Setup the corresponding note data for this behavior.
	* Is called when parsing chart files, not when
	* the chart is being loaded into a field.
	* @param data The corresponding note data.
	**/
	public function setupData(data:NoteData) {}

	/**
	* Setup the note for this behavior.
	* Is called when a note is spawned in a field.
	* @param note The corresponding note object.
	**/
	public function setup(note:BaseNote) {}

	/**
	* Updates this behavior.
	* Is called every frame, only when there are unique behaviors being used/rendered.
	* @param elapsed The delta time between frames.
	* @param notes The list of notes that are using this specific behavior.
	**/
	public function update(elapsed:Float, notes:Array<Note>) {}

	/**
	* If this behavior registers a note in the hittable window.
	* @param note The note to be checked for.
	* @return If the note is in the range to be hittable.
	**/
	public function inRange(note:BaseNote):Bool {
		var maxWindow:Float = Judgement.max.window;

		var early:Bool = note.adjustedTime < note.clock.time + maxWindow;
		var late:Bool = note.adjustedTime > note.clock.time - maxWindow;
		return early && late;
	}

	/**
	* If this behavior registers a note to be in the miss window.
	* @param note The note to be checked for.
	* @return If the note is in the missable window.
	**/
	public function isLate(note:BaseNote):Bool {
		return note.getDeviation() > (Judgement.max.window + missPadding);
	}
}