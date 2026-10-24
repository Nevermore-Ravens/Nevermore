package nevermore.play.behaviors;

/**
* Custom behavior for fakes, from StepMania 4+.
* Fakes are transparent notes that aren't hittable,
* and don't count as an actual note: hence "Fake" note.
**/
class FakeBehavior extends NoteBehavior {
	public function new() {
		super();
		ignore = true;
		hittable = false;
	}

	override function setupData(data:NoteData) {
		data.length = 0;
	}

	override function setup(note:BaseNote) {
		note.multAlpha = 0.4;
	}
}