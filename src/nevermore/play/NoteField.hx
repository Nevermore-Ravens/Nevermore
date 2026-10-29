package nevermore.play;

import flixel.group.FlxSpriteGroup;
import flixel.FlxCamera;
import nevermore.play.note.*;

/**
* A gameplay field containing notes, sustains, inputs, and modchart rendering.
* Use this for either adding custom functionality, or for making your gameplay state.
**/
class NoteField extends BaseField {
	/**
	* The strumline background for this notefield.
	**/
	public var background:FieldBackground;

	/**
	* The group of sustains to be rendered/updated.
	**/
	public var sustains:FlxTypedSpriteGroup<Sustain>;

	/**
	* The group of strumlines to render.
	**/
	public var strumlines:FlxTypedSpriteGroup<Strumline>;

	/**
	* The group of notes to be rendered/updated.
	**/
	public var notes:FlxTypedSpriteGroup<Note>;

	// whether the game will allow you to write sustain inputs like osu!mania or quaver
	// if false, it works like stepmania or etterna instead
	// (see `holdInputs()`)
	public var releaseTimings:Bool = false;

	/**
	* Callback for when a note on either strumline was hit.
	* @param strumline The corresponding strumline.
	* @param note The note that was hit.
	**/
	public dynamic function noteHit(strumline:Strumline, note:Note):Void {}

	/**
	* Callback for when a note was missed.
	* @param strumline The corresponding strumline.
	* @param note The note that was missed.
	**/
	public dynamic function noteMissed(strumline:Strumline, note:Note):Void {}

	/**
	* Callback for when a sustain on either strumline was "hit".
	* "Hit" is usually dependent on how the input system handles holds,
	* but usually means every tick that the hold is held.
	* @param strumline The corresponding strumline.
	* @param note The sustain that was hit.
	* @param mostRecent If this sustain was the most recent one to have been hit.
	**/
	public dynamic function sustainHit(strumline:Strumline, sustain:Sustain, mostRecent:Bool):Void {}

	/**
	* Callback for when a sustain on either strumline was finished/held all the way through.
	* @param strumline The corresponding strumline.
	* @param sustain The sustain that was finished.
	* @param deviation The deviation at which the strumline was released.
	* Useful for recreating release timing judgements.
	**/
	public dynamic function sustainFinished(strumline:Strumline, sustain:Sustain, deviation:Float):Void {}

	/**
	* Callback for when a sustain was dropped, not missed entirely.
	* @param strumline The corresponding strumline.
	* @param sustain The sustain that was dropped.
	**/
	public dynamic function sustainDropped(strumline:Strumline, sustain:Sustain):Void {}

	/**
	* Callback for when a tap was registered, but no note was detected/hit.
	* @param strumline The corresponding strumline.
	* @param dir The direction of the input, ranging from 0 to the key count.
	**/
	public dynamic function ghostTap(strumline:Strumline, dir:Int):Void {}

	/**
	* A pointer to the instance to the main player's strumline.
	**/
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
		autoplay = v;

		if (multiplayer) {
			for (line in strumlines.members) line.ai = v;
			return v;	
		}

		return player.ai = v;
	}

	/**
	* Whether multiple people can play at once.
	* Intended for gamepad use only, since you can only
	* have one keyboard plugged in at a time.
	**/
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
			#if NEVERMORE_NO_MODCHARTS
			var longHolds:Float = 1;
			#else
			var longHolds:Float = modchart == null ? 1 : (modchart.getLongHolds(sustain.player) + 1);
			#end
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

	/**
	* Whether a sound will play every time you're supposed to hit a note.
	* Can help with mental sync, or trying to sync up a chart properly.
	**/
	public var assistTicks:Bool = false;
	public var tickSound:FlxSound;

	override function set_keyCount(v:Int):Int {
		keyCount = v;
		input.keyCount = v;
		for (i in strumlines.members)
			i.keyCount = v;

		return v;
	}

	/**
	* Initializes a new note field.
	* @param lines The strumlines to use for this notefield.
	* @param playerID The ID that the player will be playing,
	* with is corresponding strumline.
	* @return This new notefield instance.
	**/
	public function new(?lines:Array<Strumline>, ?playerID:Int = 0) {
		background = new FieldBackground(lines);
		background.alpha = 0; // this should probably be off by default ???

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

		input = new FieldInput(this, notes, sustains);
		input.onPress.add(pressed);
		input.onRelease.add(released);

		this.playerID = playerID;

		add(sustains);
		add(strumlines);

		add(notes);

		tickSound = new FlxSound().loadEmbedded(Assets.dependency.audio('sfx/hitsound.wav'));
		tickSound.autoDestroy = false;
		FlxG.sound.list.add(tickSound);
	}

	/**
	* The amount of milliseconds the game will take after a note goes
	* past the strumline to stop rendering the note.
	**/
	var killDelay:Float = 300;
	override function update(delta:Float) {
		super.update(delta);

		background.update(0);

		var updateBehaviors:Bool = false;
		for (i in 0 ... notes.length) {
			var note:Note = notes.members[i];

			if (!note.passedStrumline) checkAssistTick(note);
			if (!note.exists) continue;

			if (note.behavior != NoteBehavior.base && !updateBehaviors) {
				updateBehaviors = true; // This makes sure that we don't do mapchecks every frame by seeing if notetypes exist.
			}

			if (note.active) note.update(delta);
			note.move(clock);

			if (note.strumline.ai) {
				input.autoplay(note.strumline, note);
			} else if (!note.missed && !note.behavior.ignore && note.late) {
				note.missed = true;
				noteMissed(note.strumline, note);
			}

			if (note.adjustedTime < clock.time - killDelay) {
				note.kill();
			}
		}

		if (updateBehaviors) {
			for (i in NoteBehavior.getList()) {
				i.update(delta, [for (n in notes.members) {if (n.behavior == i) n;}]);
			}
		}

		for (i in 0 ... sustains.length) {
			var sustain:Sustain = sustains.members[i];
			if (!sustain.exists) continue;

			if (sustain.active) sustain.update(delta);

			holdInputs(sustain);
			sustain.move(clock);

			#if NEVERMORE_NO_MODCHARTS
			var longHolds:Float = 1;
			#else
			var longHolds:Float = modchart == null ? 1 : (modchart.getLongHolds(sustain.player) + 1);
			#end
			sustain.calcHeight(sustain.strumline.speed / clock.rate * longHolds);

			if (sustain.adjustedTime + sustain.length < clock.time - killDelay) {
				sustain.kill();
			}
		}
	}

	override function destroy():Void {
		super.destroy();

		input.destroy();
		input = null;
		
		tickSound.destroy();
		FlxG.sound.list.remove(tickSound);
		tickSound = null;
	}

	function checkAssistTick(note:Note) {
		if (note.time - clock.time > 0) return;
		note.passedStrumline = true;

		if (multiplayer) {
			if (note.strumline.ai) return;
		} else if (note.player != playerID) return;
		
		if (!note.behavior.normalized) return;

		if (tickSound == null || !assistTicks) return;
		tickSound.play(true);
	}

	override function getStrumline(id:Int):Strumline {
		if (id == -1) return player;

		id = FlxMath.minInt(id, strumlines.length - 1);
		return strumlines.members[id];
	}

	/**
	* Recycles a note object belonging to a specific group.
	* @param data The corresponding data.
	* @param group The group to be recycled from.
	* @param cls The note class to be recycling.
	* @return The newly recycled note object.
	**/
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
			#if NEVERMORE_NO_MODCHARTS
			var longHolds:Float = 1;
			#else
			var longHolds:Float = modchart == null ? 1 : (modchart.getLongHolds(sustain.player) + 1);
			#end
			sustain.calcHeight(speed * longHolds);

			note.sustain = sustain;
		}
	}

	var mirrorInputs:Array<Int> = [];
	override function pressed(id:Int, direction:Int) {
		if (autoplay || (!persistentUpdate && Nevermore.paused)) return;

		if (id == -1) id = playerID;

		var strumline:Strumline = getStrumline(id);
		if (strumline.ai || strumline.held[direction]) return;
		strumline.held[direction] = true;

		var note:Note = input.tap(id, direction);
		if (note == null) {
			ghostTap(strumline, direction);
		} else {
			noteHit(strumline, note);
		}

		for (i in mirrorInputs) {
			input.tap(i, direction);
		}
	}

	override function released(id:Int, direction:Int) {
		if (autoplay) return;

		var strumline:Strumline = getStrumline(id);
		if (strumline.ai) return;

		strumline.held[direction] = false;

		function resetReceptor(strumline:Strumline) {
			strumline.members[direction].glow('standard');
		}

		resetReceptor(strumline);
		
		for (i in mirrorInputs) resetReceptor(getStrumline(i));
	}

	function holdInputs(sustain:Sustain) {
		if (!sustain.wasHit) return;

		if (releaseTimings && !sustain.isRoll) {
			input.releaseTimings(sustain.strumline, sustain);
			return;
		}

		input.regrabTimer(sustain.strumline, sustain);
	}

	#if !NEVERMORE_NO_MODCHARTS	
	var queueFramerate:Float = Nevermore.settings.notefieldFramerate;
	var queueTimer:Float = 1000; // Force draw on first frame
	
	override function draw():Void {
		if (modchart == null) {
			if (background.visible && background.alpha > 0) {
				background.draw();
			}

			super.draw();

			return;
		}

		queueTimer += FlxG.elapsed;
		if (queueTimer >= 1.0 / queueFramerate) {
			var oldDefaultCameras = null;
			@:privateAccess {
				oldDefaultCameras = FlxCamera._defaultCameras;
				if (cameras != null)
					FlxCamera._defaultCameras = cameras;
			}

			modchart.killAllQueues();
			modchart.prepare();

			// disabled because trying to deal with underlays
			// while notes are going fucking everywhere across the screen
			// is just not worth it
			//background.draw();

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
			@:privateAccess FlxCamera._defaultCameras = oldDefaultCameras;
		}

		modchart.drawQueues();
	}
	#end
}