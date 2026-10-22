package nevermore.play.behaviors;

class RollBehavior extends NoteBehavior {
	override function applySkin(note:BaseNote, type:ObjectType) {
		note.strumline.skin.applyToNote(note, type == SUSTAIN ? 'roll' : 'note');
	}

	override function setup(note:BaseNote) {
		if (!(note is Sustain)) return;

		// 250 milliseconds
		// (same window from stepmania)
		cast(note, Sustain).regrabTimer = 0.25;
	}
}