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

/**
* A universal chart format that contains notes, timing points, scroll velocities, and more.
**/
@:structInit
@:publicFields
class Chart {
	/**
	* The song name for this chart.
	* Not the ID/internal name, but what shows up on your playfield/HUD.
	**/
	var title:String = 'Unknown';

	/**
	* The list of timing points (or "BPM Changes") for this chart.
	**/
	var timingPoints:Array<TimingPoint>;

	/**
	* The list of scroll velocities for this chart.
	**/
	var scrollVelocities:Array<ScrollVelocity> = [];

	/**
	* The list of notes available for this chart.
	**/
	var notes:Array<NoteData> = [];

	/**
	* The scroll speed for this chart.
	**/
	var speed:Float = 1;

	/**
	* The audio offset for this chart, in milliseconds.
	**/
	var offset:Float = 0;

	/**
	* The amount of keys per strumline this chart uses.
	**/
	var keyCount:Int = 4;

	/**
	* The list of events parsed for this chart.
	**/
	var events:Array<ChartEvent> = [];

	var meta:Dynamic = null;

	/**
	* Whether this chart will affect how snaps are calculated.
	* If true, snaps are calculated relative to where the nearest timing point is.
	* Else, snaps will reset for every new timing point change.
	* This is exceptionally useful for files like osu!mania or Quaver, where they don't have offset
	* and instead bake it directly into the notes/timing points instead.
	**/
	var snapRelativeToChanges:Bool = true;

	/**
	* Finds the amount of chords in this chart instance.
	* Will not count quads as 2 jumps, or hands as one jump.
	* 
	* @param playerID Which side/strumline to check for.
	* @param length The threshold of what chords are allowed to be detected at.
	* If the chord length is over or under this value, it will not add it towards
	* the overall chord amount.
	* If this value is `0`, it will count any chord with a length over 1.
	*
	* @return The amount of specified chords in this chart.
	**/
	function getChordCount(?playerID:Int = 0, ?length:Int = 2):Int {
		if (length != 0) {
			length = Std.int(Math.max(length, 2));
		}

		var count:Int = 0;
		var chordLength:Int = 1; // at least 1 note per row

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
				if (length == 0 || chordLength == length) count++;
				chordLength = 1;
			}

			lastTime = data.time;
		}

		return count;
	}

	/**
	* Finds the amount of holds that are hittable in this chart.
	* @param playerID What side/strumline to check for.
	* @return The hold count for this chart.
	**/
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

	/**
	* Finds the amount of times a certain note type appears in this chart.
	* @param playerID The side/strumline to check for.
	* @param type What type to look out for.
	* If this value is blank, it will default to `getNoteCount()`.
	*
	* @return The amount of times `type` has appeared in this chart.
	**/
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

	/**
	* Finds the amount of hittable notes in this chart.
	* That includes types that you should be avoiding, such as mines.
	*
	* @param playerID What side/strumline to look for.
	* @param ignoreTypes Whether the function will ignore checking for types.
	* If true, it will count any note it sees, no matter what.
	*
	* @return The amount of notes in this chart.
	**/
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

	/**
	* Finds the amount of normalized notes in this chart.
	* This does not include types that you need to avoid, like mines.
	*
	* @param playerID What side/strumline to look for.
	* @param ignoreTypes Whether the function will ignore checking for types.
	* If true, it will count any note it sees, no matter what.
	*
	* @return The amount of notes in this chart.
	**/
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

	/**
	* Clears any possible stacked notes in the chart.
	* Most charts don't have this problem, but it can be very common in
	* games like osu! or Friday Night Funkin', where the chart editor will
	* sometimes place a note in the same spot twice.
	**/
	function clearStackedNotes() {
		sortNotes(); // sort it before in case we miss a stacked note by accident

		var cleanedNotes:Array<NoteData> = [];
		for (i => note in notes) {
			if (i != 0) {
				for (evilNote in cleanedNotes) {
					if (note == evilNote) continue;

					var matches:Bool = note.player == evilNote.player && note.lane == evilNote.lane;
					if (!matches || Math.abs(note.time - evilNote.time) > 2.0) continue;

					cleanedNotes.remove(evilNote);
					break;
				}
			}

			cleanedNotes.push(note);
			if (note.type.length != 0) {
				NoteBehavior.get(note.type).setupData(note);
			}
		}

		notes = cleanedNotes.filter(function(note:NoteData) return note != null);
	}

	/**
	* Sorts all notes in this chart, from earliest to latest.
	**/
	function sortNotes() {
		notes.sort((a, b) -> return Std.int(a.time - b.time));
	}

	/**
	* Sorts all timing points in this chart, from earliest to latest.
	**/
	function sortTimingPoints() {
		timingPoints.sort((a, b) -> return Std.int(a.time - b.time));
	}

	/**
	* Sorts all scroll velocities in this chart, from earliest to latest.
	**/
	function sortScrollVelocities() {
		scrollVelocities.sort((a, b) -> return Std.int(a.time - b.time));
	}
}