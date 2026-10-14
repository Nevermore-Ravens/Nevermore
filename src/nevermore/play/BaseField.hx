package nevermore.play;

import flixel.group.FlxSpriteGroup;
import nevermore.core.timing.BaseClock;
import nevermore.core.timing.TimingMap;
import nevermore.modchart.ModchartManager;
import nevermore.core.Chart;

// a base class for any fields for you to build off of
// gives you mostly everything you'd need to make your own notefield
class BaseField extends FlxSpriteGroup {
	public var clock(get, default):BaseClock;
	function get_clock():BaseClock {
		clock ??= Conductor.clock;
		return clock;
	}

	public var keyCount(default, set):Int = 4;
	function set_keyCount(v:Int):Int {
		keyCount = v;
		input.keyCount = v;
		return v;
	}

	// works like FlxState.persistentUpdate
	public var persistentUpdate:Bool = false;

	// the note count per strumline
	// noteCount[0] would be the amount of notes on strumline 0
	// same for 1 and 2 etc
	public var noteCount:Array<Int> = [];

	public var playerID(default, set):Int = 0;
	function set_playerID(v:Int):Int {
		return playerID = v;
	}

	public var scrollSpeed(default, set):Float;
	function set_scrollSpeed(v:Float):Float {
		return scrollSpeed = v;
	}

	public var scrollDirection(default, set):ScrollDirection;
	function set_scrollDirection(v:ScrollDirection):ScrollDirection {
		return scrollDirection = v;
	}

	public var autoplay(default, set):Bool = false;
	function set_autoplay(v:Bool):Bool {
		return autoplay = v;
	}

	public var scrollVelocities:Bool = true;

	public var spawner:NoteSpawner;
	#if !NEVERMORE_NO_MODCHARTS
	public var modchart:ModchartManager;
	#end

	public var input:InputManager;

	public function getStrumline(id:Int):Strumline {
		return null;
	}

	public var unspawnedNotes(get, never):Array<NoteData>;
	function get_unspawnedNotes():Array<NoteData> return spawner.list;

	public function new() {
		super();

		input = new InputManager();
		spawner = new NoteSpawner();

		input.onPress.add(pressed);
		input.onRelease.add(released);

		scrollSpeed = 1.0;
		scrollDirection = UP;
	}

	override function update(delta:Float) {
		// inline super.update()
		// because calling super is costly
		var i:Int = 0;
		var obj:flixel.FlxBasic = null;

		while (i < length) {
			obj = members[i++];
			if (obj == null || !obj.exists || !obj.active) continue;

			obj.update(delta);
		}

		#if !NEVERMORE_NO_MODCHARTS
		if (modchart != null) modchart.update();
		#end

		spawner.update(clock);
	}

	override function destroy():Void {
		super.destroy();

		input.destroy();
		spawner.destroy();

		spawner = null;
		input = null;
	}

	public function load(chart:Chart, ?modifiers:GameplayModifiers) {
		modifiers ??= {};
		if (chart.scrollVelocities.length <= 1) {
			modifiers.scrollVelocities = false;
		}

		keyCount = chart.keyCount;
		
		scrollVelocities = modifiers.scrollVelocities;

		clock.reset(chart);
		clock.offset = chart.offset;

		applyModifiers(chart, modifiers);

		var map:TimingMap = clock.timingMap;
		var list:Array<NoteData> = [];
		for (i => note in chart.notes) {
			note.beat = map.getBeat(note.time);
			note.snapID = Util.getSnapID(note.time, map, chart.snapRelativeToChanges);
			list.push(note);
		}
		
		spawner.load(list);
		spawner.triggered = noteSpawned;
	}

	function applyModifiers(chart:Chart, modifiers:GameplayModifiers) {
		var keySeq = [for (i in 0...keyCount) i];
		if (modifiers.mirroredNotes) keySeq.reverse();
		var lanes:Array<Int> = keySeq;
		if (modifiers.randomizedNotes) FlxG.random.shuffle(lanes);

		for (note in chart.notes) {
			note.lane = lanes[note.lane];
			if (!modifiers.sustains) note.length = 0;
			if (!modifiers.scrollVelocities) continue;

			note.visualTime = clock.velocityMap.getPosition(note.time);
			if (note.length > 0) {
				var endTime = note.time + note.length;
				note.visualEnd = clock.velocityMap.getPosition(endTime);
			}
		}
	}

	function noteSpawned(data:NoteData) {}

	function pressed(id:Int, direction:Int) {}
	function released(id:Int, direction:Int) {}
}