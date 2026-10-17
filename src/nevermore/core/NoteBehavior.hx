package nevermore.core;

import nevermore.play.Note;
import nevermore.play.BaseNote;

enum abstract ObjectType(Int) {
	var NOTE;
	var SUSTAIN;
	var RECEPTOR;
} 

class NoteBehavior {
	static var _list:Map<String, NoteBehavior> = [];
	
	// because map access on EVERY note instead of unique ones
	// sounds like an extremely bad idea
	public static var base:NoteBehavior = new NoteBehavior();

	public static function getList():Array<NoteBehavior> {
		return [for (k in _list) k];
	}

	public static function register(name:String, cls:Class<NoteBehavior>) {
		_list.set(name, Type.createInstance(cls, []));
	}

	public static function get(name:String):NoteBehavior {
		if (name.length == 0 || !_list.exists(name)) {
			return base;
		}
		
		return _list[name];
	}

	public var ignore:Bool = false;
	public var hittable:Bool = true;
	public var missPadding:Float = 25;
	public var hitHealth:Float = 1;
	public var missHealth:Float = -1;
	public var judgemental:Bool = true; // my feelings :(
	public var punishable:Bool = false;

	public function new() {}
	public function applySkin(note:BaseNote, type:ObjectType) {
		note.strumline.skin.applyToNote(note, type == NOTE ? "note" : "sustain");
	}
	public function setupData(data:NoteData) {}
	public function setup(note:BaseNote) {}

	// Not a basenote since this intentionally only affects notes
	public function update(elapsed, note:Array<Note>) {}

	public function inRange(note:BaseNote):Bool {
		var maxWindow:Float = Judgement.max.window;

		var early:Bool = note.adjustedTime < note.clock.time + maxWindow;
		var late:Bool = note.adjustedTime > note.clock.time - maxWindow;
		return early && late;
	}

	public function isLate(note:BaseNote):Bool {
		return note.getDeviation() > (Judgement.max.window + missPadding);
	}
}