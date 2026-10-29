package nevermore.input;

import nevermore.play.*;
import nevermore.core.timing.BaseClock;
import flixel.group.FlxSpriteGroup;

/**
* Manages inputs and process them to judge the player accordingly.
* In laymen's terms, the input system.
**/
class FieldInput extends InputManager {
	var parent:NoteField;
	var notes:FlxTypedSpriteGroup<Note>;
	var sustains:FlxTypedSpriteGroup<Sustain>;

	/**
	* How many times a second the sustain will be considered "hit".
	**/
	var sustainInterval:Float = 0.12;

	var clock(get, never):BaseClock;
	function get_clock():BaseClock {
		return parent.clock;
	}

	public function new(parent:NoteField, notes:FlxTypedSpriteGroup<Note>, sustains:FlxTypedSpriteGroup<Sustain>) {
		super();

		this.parent = parent;
		this.notes = notes;
		this.sustains = sustains;
	}

	/**
	* Finds a tap note, and then removes it.
	* Also manages rolls somewhat.
	* @param id The player/strumline ID to look out for.
	* @param direction The key direction that was pressed.
	* @return The note that was hit.
	**/
	override function tap(id:Int, direction:Int):Note {
		var strumline:Strumline = null;
		var receptor:Receptor = null;

		var rollHit:Bool = false;
		for (i in 0 ... sustains.length) {
			var sustain:Sustain = sustains.members[i];
			if (!sustain.exists || !sustain.isRoll) continue;
			if (!sustain.wasHit || sustain.player != id || sustain.lane != direction) continue;

			receptor = sustain.strumline.members[sustain.lane];

			sustain.regrabTimer = 0.25;
			parent.sustainHit(sustain.strumline, sustain, true);
			receptor.glow();

			if (sustain.luminize) {
				receptor.color = sustain.color;
				receptor.luminize = true;
			}
			
			rollHit = true;
		}

		var closestDistance:Float = Math.POSITIVE_INFINITY;
		var note:Note = null;
		for (i in 0 ... notes.length) {
			var possibleNote:Note = notes.members[i];
			if (!possibleNote.exists) continue;

			// is it on the player's strumline?
			// is it in the correct lane?
			if (possibleNote.player != id || possibleNote.lane != direction) continue;

			// is the note hittable in general?
			// is it within range?
			if (!possibleNote.behavior.hittable || !possibleNote.inRange) continue;

			// checks if the note is the closest to the judgement line
			// rather than the first available note
			// possibility of being slightly slower
			// but might be closer to the actual note you meant to hit
			var distance:Float = Math.abs(possibleNote.adjustedTime - clock.time);
			if (distance >= closestDistance) continue;

			closestDistance = distance;
			note = possibleNote;
		}

		strumline = note?.strumline ?? parent.getStrumline(id);
		receptor = strumline.members[direction];

		if (note != null) {
			receptor.glow();
			receptor.isHolding = !strumline.ai;

			note.behavior.hitsound.play(true);

			note.kill();
			var sustain:Sustain = note.sustain;
			if (sustain != null) {
				sustain.wasHit = true;
				if (sustain.isRoll) sustain.regrabTimer = 0.25;

				receptor.isHolding = true;
			}

			if (note.luminize) {
				receptor.color = note.color;
				receptor.luminize = true;
			}
		} else if (!rollHit) {
			receptor.isHolding = !strumline.ai;
			receptor.glow('pressed');
		}

		return note;
	}
	
	/**
	* Attempts to recreate the release timing hold system from osu!mania/Quaver.
	* When the player lets go of a sustain, we track the deviation of how 
	* far away they were from the end of the sustain.
	*
	* If the player released too early, and the deviation is higher than the highest window,
	* it's safe to assume the player dropped the sustain entirely.
	* Otherwise, judge the sustain accordingly.
	**/
	override function releaseTimings(strumline:Strumline, sustain:Sustain) {
		var receptor:Receptor = sustain.receptor;

		var curHolds:Array<Sustain> = strumline.curHolds;
		var held:Bool = strumline.held[sustain.lane];

		var deviation:Float = clock.time - (sustain.adjustedTime + sustain.length);

		// ai strumlines don't have to deal with release timings
		if (strumline.ai) {
			if (deviation >= 0) {
				curHolds.remove(sustain);
				sustain.kill();

				if (strumline.ai) {
					receptor.glow('standard');
					receptor.isHolding = false;
				}

				parent.sustainFinished(strumline, sustain, deviation);
				receptor.isHolding = held;
			}

		// the player probably let go of the sustain
		} else if (!held) {
			curHolds.remove(sustain);

			// if the deviation is before the window,
			// assume they dropped it
			if (deviation < -Judgement.max.window) {
				parent.sustainDropped(strumline, sustain);
				sustain.regrabAlpha = 0.2;
				sustain.wasHit = false;
			// else hit it like normal
			} else {
				parent.sustainFinished(strumline, sustain, deviation);
				sustain.kill();

				receptor.isHolding = held;
				sustain.untilTick = 0; // Hit it one last time, to make sure
			}

			return;
		}

		sustain.regrabAlpha = 1;

		// only clip if it's past the sustain
		// TODO: make this work for sv's (this DEFINITELY doesn't work with sv's)
		if (!parent.scrollVelocities)
			sustain.timeOffset = Math.max(clock.time - sustain.adjustedTime, 0);
		else if (clock.time >= sustain.adjustedTime)
			sustain.timeOffset = Math.min(clock.visualTime - sustain.visualTime, 0);
		
		sustain.forceHeightRecalc = deviation <= 0;
		receptor.isHolding = true;

		if (!curHolds.contains(sustain)) {
			// we want the most recent, but we also dont wanna prioritize super short sustains
			final idx:Int = sustain.length >= 250 ? curHolds.length : 0;
			curHolds.insert(idx, sustain);
		}

		sustain.untilTick -= FlxG.elapsed;
		if (sustain.untilTick > 0) return;

		sustain.untilTick = sustainInterval;
		if (strumline.ai || held) {
			receptor.glow();
			if (sustain.luminize) {
				receptor.color = sustain.color;
				receptor.luminize = true;
			}
		}

		parent.sustainHit(strumline, sustain, curHolds[curHolds.length - 1] == sustain);
	}

	/**
	* Judges a specific sustain and will either drop or keep holding.
	* Specifically, it attempts to recreate the "regrab" system from StepMania/Etterna.
	* Instead of immediately dropping the sustain when the player letes go,
	* give them a little bit of leeway by holding onto
	* the sustain for a *little* longer, and then finally letting the sustain go.
	*
	* This allows for relatively great-feeling sustain gameplay without it being too
	* hand-holdy (if the length of time is short enough), especially if there's a note
	* right after the end of said sustain.
	*
	* This same concept applies to rolls as well, since they heavily utilize this functionality.
	*
	* @param strumline The strumline connected to this sustain.
	* @param sustain The sustain to be judged.
	**/
	override function regrabTimer(strumline:Strumline, sustain:Sustain) {
		var receptor:Receptor = sustain.receptor;
		var clock:BaseClock = parent.clock;

		var held:Bool = !sustain.isRoll && strumline.held[sustain.lane];
		var playerHeld:Bool = (held || sustain.regrabTimer > 0);
		var heldKey:Bool = (!strumline.ai && playerHeld) || (strumline.ai && sustain.adjustedTime <= clock.time);

		final regrabLimit:Float = sustain.isRoll ? 0.25 : Judgement.max.window / 1000;

		if (sustain.regrabTimer < regrabLimit && held && !strumline.ai) { // regrab logic would never happen in botplay
			receptor.glow('standard');
		}

		final curHolds:Array<Sustain> = strumline.curHolds;
		if (!strumline.ai) {
			sustain.regrabTimer = held ? regrabLimit : sustain.regrabTimer - FlxG.elapsed;

			if (!heldKey) {
				curHolds.remove(sustain);
				sustain.regrabAlpha = 0.2;
				sustain.wasHit = false;
				parent.sustainDropped(sustain.strumline, sustain);

				return;
			}
		}

		sustain.regrabAlpha = strumline.ai ? 1 : (0.6 + 0.4 * (sustain.regrabTimer / regrabLimit));

		// only clip if it's past the sustain
		if (!parent.scrollVelocities)
			sustain.timeOffset = -Math.min(sustain.adjustedTime - clock.time, 0);
		else if (clock.time >= sustain.adjustedTime)
			sustain.timeOffset = clock.visualTime - sustain.visualTime;
		
		sustain.forceHeightRecalc = true;
		receptor.isHolding = true;

		if (!curHolds.contains(sustain)) {
			// we want the most recent, but we also dont wanna prioritize super short sustains
			final idx = sustain.length >= 250 ? curHolds.length : 0;
			curHolds.insert(idx, sustain);
		} else if (sustain.adjustedTime + sustain.length <= clock.time) {
			curHolds.remove(sustain);
			sustain.kill();
			receptor.isHolding = held;
			if (strumline.ai) {
				receptor.glow('standard');
				receptor.isHolding = false;
			}
			sustain.untilTick = 0; // Hit it one last time, to make sure

			var deviation:Float = clock.time - (sustain.adjustedTime + sustain.length);
			parent.sustainFinished(strumline, sustain, deviation);
		}

		sustain.untilTick -= FlxG.elapsed;
		if (sustain.untilTick > 0) return;

		sustain.untilTick = sustainInterval;
		if (strumline.ai || held) {
			receptor.glow();
			if (sustain.luminize) {
				receptor.color = sustain.color;
				receptor.luminize = true;
			}
		}

		parent.sustainHit(strumline, sustain, curHolds[curHolds.length - 1] == sustain);
	}

	/**
	* Automatically plays a specific note.
	* @param strumline The strumline connected to the note.
	* @param note The note to be played.
	**/
	override function autoplay(strumline:Strumline, note:Note) {
		if (!note.behavior.normalized || note.adjustedTime - clock.time > 0) return;

		var receptor:Receptor = strumline.members[note.lane];

		note.kill();
					
		if (note.sustain != null) {
			note.sustain.wasHit = true;
		}

		receptor.glow();
		receptor.isHolding = note.sustain != null;
		if (note.luminize) {
			receptor.color = note.color;
			receptor.luminize = true;
		}

		parent.noteHit(strumline, note);
		note.behavior.hitsound.play(true);
	}
}