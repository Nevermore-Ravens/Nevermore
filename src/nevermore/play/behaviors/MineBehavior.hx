package nevermore.play.behaviors;

import nevermore.core.timing.BaseClock;
import nevermore.skins.Noteskin;

class MineBehavior extends NoteBehavior {
	public function new() {
		super();

		ignore = true;
		punishable = true;
		missHealth = -10;

		hitsound = new FlxSound().loadEmbedded(Assets.dependency.audio('sfx/mine.wav'));
		hitsound.persist = true;
		hitsound.autoDestroy = false;
		FlxG.sound.list.add(hitsound);
	}

	override function applySkin(note:BaseNote, type:ObjectType) {
		Noteskin.get("mine").applyToNote(note, "note");
		note.offset.set(-22, -22); // updateHitbox() is stinky
	}

	override function setupData(data:NoteData) {
		data.length = 0;
	}

	override function update(delta:Float, notes:Array<Note>) {
		for (i in 0...notes.length) {
			var note:Note = notes[i];

			var timeDist:Float = note.visualTime - note.clock.time;
			note.angle = timeDist * (Util.crotchet(note.clock.timingMap.tempo) * 0.001);
		}
	}

	override function setup(note:BaseNote) {
		note.active = true;
		note.luminize = false;
		note.color = 0xFFFFFFFF;
	}
}