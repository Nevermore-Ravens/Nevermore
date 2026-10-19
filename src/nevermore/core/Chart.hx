package nevermore.core;

import nevermore.core.timing.ScrollVelocity;
import nevermore.core.timing.TimingPoint;
import nevermore.core.NoteData;

@:structInit 
@:publicFields
class ChartEvent {
    var name:String = '';
    var time:Float = 0.0;
    var args:Array<Dynamic> = [];

	function toString():String {
		return 'Name: $name | Time: $time | Arguments: $args';
	}
}

@:structInit
@:publicFields
class Chart {
	var title:String = 'Unknown';
	var timingPoints:Array<TimingPoint>;
	var scrollVelocities:Array<ScrollVelocity> = [];
	var notes:Array<NoteData> = [];
	var speed:Float = 1;
	var offset:Float = 0;
	var keyCount:Int = 4;
	var events:Array<ChartEvent> = [];

	var meta:Dynamic = null;

	/*
		some formats (like quaver) reset quant
		on a new bpm change
		so we use this.
	*/
	var snapRelativeToChanges:Bool = true;

	// gets the amount of chords in the chart
	// this does NOT work like etterna !!! it is ROW based
	// which means quads will not count as 2 jumps
	// hands don't count as a jump
	// ecetera
	// for clarification
	// length == 2 / jumps
	// length == 3 / hands
	// length == 4 / quads 
	function getChordCount(?playerID:Int = 0, ?length:Int = 2):Int {
		length = Std.int(Math.max(length, 2)); // Stops the compiler from whining

		var count:Int = 0;
		var chordLength:Int = 1; // at least 1 note per now

		var lastTime:Float = 0.0;

		for (i in 0 ... notes.length) {
			var data = notes[i];

			// skip any notes that aren't on the side we want
			if (data.player != playerID) continue;
		
			if (data.type.length != 0) {
				if (!NoteBehavior.get(data.type).normalized) continue;
			}

			if (i == 0) {
				lastTime = data.time;
				continue;
			}

			// we found a chord
			if (data.time == lastTime) chordLength++;

			// this was not a chord
			// or we either just passed one
			else if (chordLength != 1) {
				if (chordLength == length) count++;
				chordLength = 1;
			}

			lastTime = data.time;
		}

		return count;
	}

	function getHoldCount(?playerID:Int = 0):Int {
		var count:Int = 0;
		for (i in 0 ... notes.length) {
			var data = notes[i];
			if (data.player != playerID) continue;
			if (data.length == 0) continue;

			count++;
		}

		return count;
	}

	function getTypeCount(?playerID:Int = 0, type:String = ''):Int {
		if (type.length == 0) return getNoteCount(playerID);

		var count:Int = 0;
		for (i in 0 ... notes.length) {
			var data:NoteData = notes[i];
			if (data.player != playerID) continue;
			if (data.type != type) continue;

			count++;
		}

		return count;
	}

	// counts all notes in the chart as long as the note is hittable, excluding fakes
	// includes mines as they aren't meant to be hit, but can
	function getNoteCount(?playerID:Int = 0, ?ignoreTypes:Bool = false):Int {
		var count:Int = 0;
		for (i in 0 ... notes.length) {
			var data:NoteData = notes[i];
			if (data.player != playerID) continue;
			if (!ignoreTypes && data.type.length != 0) {
				if (!NoteBehavior.get(data.type).hittable) continue;
			}

			count++;
		}

		return count;
	}

	// counts all notes in the chart are supposed to be hit, excluding fakes
	// does NOT include mines, as they aren't meant to be hit
	function getNormalizedNoteCount(?playerID:Int = 0, ?ignoreTypes:Bool = false):Int {
		var count:Int = 0;
		for (i in 0 ... notes.length) {
			var data:NoteData = notes[i];
			if (data.player != playerID) continue;

			if (!ignoreTypes && data.type.length != 0) {
				if (!NoteBehavior.get(data.type).normalized) continue;
			}

			count++;
		}

		return count;
	}

	function sortNotes() {
		notes.sort((a, b) -> return Std.int(a.time - b.time));
	}

	function sortTimingPoints() {
		timingPoints.sort((a, b) -> return Std.int(a.time - b.time));
	}

	function sortScrollVelocities() {
		scrollVelocities.sort((a, b) -> return Std.int(a.time - b.time));
	}
}