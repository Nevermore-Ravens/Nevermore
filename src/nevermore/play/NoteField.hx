package nevermore.play;

import flixel.group.FlxSpriteGroup;
import flixel.FlxCamera;
import nevermore.play.note.*;

class NoteField extends BaseField {
	public var underlays:UnderlayGroup;
	public var sustains:FlxTypedSpriteGroup<Sustain>;
	public var strumlines:FlxTypedSpriteGroup<Strumline>;
	public var notes:FlxTypedSpriteGroup<Note>;

	public dynamic function noteHit(strumline:Strumline, note:Note):Void {}
	public dynamic function noteMissed(strumline:Strumline, note:Note):Void {}
	public dynamic function sustainHit(strumline:Strumline, sustain:Sustain, mostRecent:Bool):Void {}
	public dynamic function sustainDropped(strumline:Strumline, sustain:Sustain):Void {}
	public dynamic function ghostTap(strumline:Strumline, dir:Int):Void {}

	public var player:Strumline;
	override function set_playerID(v:Int):Int {
		v = FlxMath.minInt(v, strumlines.length - 1);

		for (i => line in strumlines.members) {
			if (multiplayer) line.ai = autoplay;
			else line.ai = (v == i) ? autoplay : true;
		}

		player = getStrumline(v);
		return playerID = v;
	}

	override function set_autoplay(v:Bool):Bool {
		return autoplay = getStrumline(playerID).ai = v;
	}

	public var multiplayer(default, set):Bool = false;
	function set_multiplayer(v:Bool):Bool {
		for (i => line in strumlines.members) {
			if (v) line.ai = autoplay;
			else line.ai = (playerID == i) ? autoplay : true;
		}

		return multiplayer = v;
	}

	override function set_scrollSpeed(v:Float):Float {
		for (line in strumlines.members) {
			line.speed = v;
		}

		for (sustain in sustains.members) {
			sustain.forceHeightRecalc = true;

			var speed:Float = v / clock.rate;
			var longHolds:Float = modchart == null ? 1 : (modchart.get('longholds', sustain.player) + 1);
			sustain.calcHeight(speed * longHolds);
		}

		return scrollSpeed = v;
	}

	override function set_scrollDirection(v:ScrollDirection):ScrollDirection {
		for (line in strumlines.members) {
			line.direction = v;
		}

		return scrollDirection = v;
	}

	public var assistTicks:Bool = false;
	public var tickSound:FlxSound;
	override function set_keyCount(v:Int):Int {
		keyCount = v;
		input.keyCount = v;
		for (i in strumlines.members)
			i.keyCount = v;

		return v;
	}

	public function new(?lines:Array<Strumline>, ?playerID:Int = 0) {
		underlays = new UnderlayGroup(lines);
		underlays.color = FlxColor.BLACK;
		underlays.alpha = 0; // this should probably be off by default ???

		sustains = new FlxTypedSpriteGroup<Sustain>();
		sustains.active = false;

		strumlines = new FlxTypedSpriteGroup<Strumline>();

		notes = new FlxTypedSpriteGroup<Note>();
		notes.active = false;

		for (line in lines ?? []) {
			line.field = this;
			strumlines.add(line);
		}

		super();

		this.playerID = playerID;

		add(underlays);

		add(sustains);
		add(strumlines);

		add(notes);

		tickSound = FlxG.sound.load(Assets.dependency.audio('sfx/hitsound.wav'));
	}

	var killDelay:Float = 300;
	override function update(delta:Float) {
		super.update(delta);

		for (i => underlay in underlays.members) {
			underlay.alpha = strumlines.members[i].alpha * underlays.alpha;
			underlay.visible = strumlines.members[i].visible;
		}

		var updateBehaviors = false;
		for (i in 0 ... notes.length) {
			var note:Note = notes.members[i];

			if (!note.passedStrumline) checkAssistTick(note);
			if (!note.exists) continue;

			if (note.behavior != NoteBehavior.base && !updateBehaviors) {
				updateBehaviors = true; // This makes sure that we don't do mapchecks every frame by seeing if notetypes exist.
			}

			if (note.active) note.update(delta);
			note.move(clock);

			// should probably move this to a separate function later
			if (note.strumline.ai) {
				if (!note.behavior.punishable && note.adjustedTime - clock.time <= 0) {
					note.kill();
					if (note.sustain != null) {
						note.sustain.wasHit = true;
					}

					note.receptor.glow();
					if (note.luminize) {
						note.receptor.color = note.color;
						note.receptor.luminize = true;
					}
					noteHit(note.strumline, note);
				}
			} else if (!note.missed && !note.behavior.ignore && note.late) {
				note.missed = true;
				noteMissed(note.strumline, note);
			}

			if (note.adjustedTime < clock.time - killDelay) {
				note.kill();
			}
		}

		if (updateBehaviors) {
			for (i in NoteBehavior.getListOfBehaviours()) {
				i.update(delta, [for (n in notes.members) {if (n.behavior == i) n;}]);
			}
		}

		for (i in 0 ... sustains.length) {
			var sustain:Sustain = sustains.members[i];
			if (!sustain.exists) continue;

			if (sustain.active) sustain.update(delta);

			holdInputs(sustain);
			sustain.move(clock);
			sustain.calcHeight(sustain.strumline.speed / clock.rate);

			if (sustain.adjustedTime + sustain.length < clock.time - killDelay) {
				sustain.kill();
			}
		}
	}

	function checkAssistTick(note:Note) {
		if (note.time - clock.time > 0) return;
		note.passedStrumline = true;

		if (note.player != playerID) return;
		if (!note.behavior.hittable || note.behavior.punishable) return;

		if (tickSound == null || !assistTicks) return;
		tickSound.play(true);
	}

	override function getStrumline(id:Int):Strumline {
		id = FlxMath.minInt(id, strumlines.length - 1);
		return strumlines.members[id];
	}

	function addNote<T:Note>(data:NoteData, group:FlxTypedSpriteGroup<T>, cls:Class<T>):T {
		var obj:T = group.recycle(cls);
		group.remove(obj, true); // keep ordering
		group.add(cast obj.setup(getStrumline(data.player), data));

		return obj;
	}

	override function noteSpawned(data:NoteData) {
		if (data.player >= strumlines.length) return;

		var note = addNote(data, notes, Note);
		if (data.length > 0) {
			var sustain = addNote(data, sustains, Sustain);

			var speed:Float = sustain.strumline.speed / clock.rate;
			var longHolds:Float = modchart == null ? 1 : (modchart.get('longholds', data.player) + 1);
			sustain.calcHeight(speed * longHolds);

			note.sustain = sustain;
		}
	}

	var mirrorInputs:Array<Int> = [];
	override function pressed(id:Int, direction:Int) {
		if (autoplay || (!persistentUpdate && Nevermore.paused)) return;

		var strumline:Strumline = player;
		if (id == -1) id = playerID;
		if (multiplayer) {
			strumline = getStrumline(id);
		}

		if (strumline.held[direction]) return;
		strumline.held[direction] = true;

		var note:Note = tapInputs(direction, id);
		if (note == null) {
			ghostTap(strumline, direction);
		} else {
			noteHit(note.strumline, note);
		}

		for (i in mirrorInputs) tapInputs(direction, i);
	}

	override function released(id:Int, direction:Int) {
		if (autoplay) return;

		var strumline:Strumline = player;
		if (id == -1) id = playerID;
		if (multiplayer) {
			strumline = getStrumline(id);
		}

		strumline.held[direction] = false;

		function resetReceptor(strumline:Strumline) {
			strumline.members[direction].glow('standard');
		}

		resetReceptor(strumline);
		
		for (i in mirrorInputs) resetReceptor(getStrumline(i));
	}

	// you don't have to do inputs like this
	// a simple sort and then list[0] should do the job 
	// but for something this caliber it needs to handle it a bit more accurately
	function tapInputs(direction:Int, ?id:Int):Note {
		id ??= playerID;

		var strumline = getStrumline(id);
		var receptor:Receptor = strumline.members[direction];

		var rollHit:Bool = false;
		for (sustain in sustains.members) {
			if (!sustain.exists || !sustain.isRoll) continue;
			if (!sustain.wasHit || sustain.player != id || sustain.lane != direction) continue;

			sustain.regrabTimer = 0.25;
			sustainHit(strumline, sustain, true);
			receptor.glow();

			if (sustain.luminize) {
				receptor.color = sustain.color;
				receptor.luminize = true;
			}
			
			rollHit = true;
		}

		var closestDistance:Float = Math.POSITIVE_INFINITY;
		var noteToHit:Note = null;
		for (i in 0 ... notes.length) {
			var note:Note = notes.members[i];
			if (!note.exists) continue;

			// is it on the player's strumline?
			// is it in the correct lane?
			if (note.player != id || note.lane != direction) continue;

			// is the note hittable in general?
			// is it within range?
			if (!note.behavior.hittable || !note.inRange) continue;

			// checks if the note is the closest to the judgement line
			// rather than the first available note
			// possibility of being slightly slower
			// but might be closer to the actual note you meant to hit
			var distance:Float = Math.abs(note.adjustedTime - clock.time);
			if (distance >= closestDistance) continue;

			closestDistance = distance;
			noteToHit = note;
		}

		if (noteToHit != null) {
			receptor.glow();

			noteToHit.kill();
			var sustain:Sustain = noteToHit.sustain;
			if (sustain != null) {
				sustain.wasHit = true;
				if (sustain.isRoll) sustain.regrabTimer = 0.25;

				receptor.isHolding = true;
			}

			if (noteToHit.luminize) {
				receptor.color = noteToHit.color;
				receptor.luminize = true;
			}
		} else if (!rollHit) {
			receptor.isHolding = true;
			receptor.glow('pressed');
		}

		return noteToHit;
	}

	// attempts to recreate the "regrab" system from stepmania/etterna
	// instead of immediately dropping the sustain when the player lets go,
	// we give them a little bit of leeway by holding onto the sustain for a *little* longer,
	// and then finally letting the sustain go
	//
	// this allows for relatively great-feeling sustain gameplay
	// without it being too hand-holdy (if the length of time is short enough),
	// especially if there's a note right after the end of a sustain
	//
	// this same concept applies to rolls as well, since they heavily utilize this functionality
	var sustainInterval:Float = 0.12;
	function holdInputs(sustain:Sustain) {
		if (!sustain.wasHit) return;

		var strumline:Strumline = sustain.strumline;
		var receptor:Receptor = sustain.receptor;

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
				if (!strumline.ai) {
					curHolds.remove(sustain);
					sustain.regrabAlpha = 0.2;
					sustain.wasHit = false;
					sustainDropped(sustain.strumline, sustain);
				}

				return;
			}
		}

		sustain.regrabAlpha = strumline.ai ? 1 : (0.6 + 0.4 * (sustain.regrabTimer / regrabLimit));

		// only clip if it's past the sustain
		if (!scrollVelocities)
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

		sustainHit(strumline, sustain, curHolds[curHolds.length - 1] == sustain);
	}

	
	var queueFramerate:Float = Nevermore.settings.notefieldFramerate;
	var queueTimer:Float = 1000; // Force draw on first frame
	
	override function draw():Void {
		if (modchart == null) {
			super.draw();
			return;
		}

		queueTimer += FlxG.elapsed;
		if (queueTimer >= 1.0/queueFramerate) {
			modchart.killAllQueues();
			modchart.prepare();

			// disabled because trying to deal with underlays
			// while notes are going fucking everywhere across the screen
			// is just not worth it
			//underlays.draw();

			for (i => strumline in strumlines.members) {
				if (!strumline.visible) continue;

				for (strum in strumline.members) {
					if (!strum.visible) continue;
					strum.preDrawCrazy(modchart, i, strumline.direction);
				}
			}

			for (sustain in sustains.members) {
				if (!sustain.exists || !sustain.visible) continue;

				sustain.drawCrazy(modchart, sustain.strumline.direction);
			}

			for (i => strumline in strumlines.members) {
				if (!strumline.visible) continue;

				for (strum in strumline.members) {
					if (!strum.visible) continue;
					strum.drawCrazy(modchart, i, strumline.direction);
				}
			}

			for (note in notes.members) {
				if (!note.exists || !note.visible) continue;

				note.drawCrazy(modchart, note.strumline.direction);
			}
			queueTimer = 0;
		}

		var oldDefaultCameras = null;
		@:privateAccess {
			oldDefaultCameras = FlxCamera._defaultCameras;
			if (cameras != null)
				FlxCamera._defaultCameras = cameras;
		}

		modchart.drawQueues();
		@:privateAccess FlxCamera._defaultCameras = oldDefaultCameras;
	}
}