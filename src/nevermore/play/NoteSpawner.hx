package nevermore.play;

import nevermore.core.NoteData;
import nevermore.core.timing.BaseClock;

/**
* A class that dispatches whenever a note should be spawned.
**/
class NoteSpawner {
	/**
	* The amount of objects this spawner contains.
	**/
	public var count:Int;
	public function new(?list:Array<NoteData>) {
		if (list != null) load(list);
	}

	/**
	* Loads this spawner with a set list of note data.
	* @param list The list of data to spawn.
	**/
	public function load(list:Array<NoteData>) {
		this.list = list;
		list.sort((a, b) -> return Std.int(a.time - b.time));

		count = list.length;
	}

	/**
	* Destroys the instance of this spawner.
	**/
	public function destroy() {
		triggered = function(_) {}
		list.resize(0);
		index = 0;
		count = 0;
	}

	/**
	* What data index this spawner is currently on.
	**/
	public var index:Int = 0;

	/**
	* The amount of time in milliseconds this spawner will 
	* offset the spawn time for each note.
	*
	* Positive values mean it will spawn them earlier,
	* causing notes to render more often.
	* Negative values mean it will spawn notes sooner,
	* causing them to appear in the middle of gameplay.
	**/
	public var delay:Float = 1500;

	/**
	* The list of notes this spawner is pulling from.
	**/
	public var list:Array<NoteData>;

	/**
	* Callback for when a note spawn has been triggered.
	**/
	public dynamic function triggered(note:NoteData) {}

	/**
	* Updates this spawner's instance.
	* @param clock The clock to use as reference.
	**/
	public function update(clock:BaseClock) {
		while (index < count) {
			var data:NoteData = list[index];

			var adjustedTime:Float = (data.time + Nevermore.settings.inputOffset);
			var deviation:Float = adjustedTime - clock.time;
			if (deviation > delay) break;

			triggered(data);
			index++;
		}
	}
}