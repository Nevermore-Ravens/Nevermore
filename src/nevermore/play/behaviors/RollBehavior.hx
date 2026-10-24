package nevermore.play.behaviors;

/**
* Custom behavior for rolls from StepMania 4+.
* Rolls are a different type of sustain that- instead of holding them
* all the way through, you repeatedly tap them over and over, until the sustain is finished.
**/
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