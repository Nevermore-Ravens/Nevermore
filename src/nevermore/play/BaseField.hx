package nevermore.play;

import flixel.group.FlxSpriteGroup;
import nevermore.core.timing.BaseClock;
import nevermore.core.timing.TimingMap;
import nevermore.modchart.ModchartManager;
import nevermore.core.Chart;

/**
* A class that handles the general gameplay of a rhythm game.
* Offers the essentials to make your own notefield, if need be.
**/
class BaseField extends FlxSpriteGroup {
	/**
	* The song clock for this field.
	**/
	public var clock(get, default):BaseClock;
	function get_clock():BaseClock {
		clock ??= Conductor.clock;
		return clock;
	}

	/**
	* The amount of keys this field will be using.
	**/
	public var keyCount(default, set):Int = 4;
	function set_keyCount(v:Int):Int {
		keyCount = v;
		if (input != null) input.keyCount = v;
		return v;
	}

	/**
	* Works like `FlxState.persistentUpdate` in the context for inputs.
	**/
	public var persistentUpdate:Bool = false;

	/**
	* The note count per each strumline, from left to right.
	**/
	public var noteCount:Array<Int> = [];

	/**
	* The player's ID for a specific strumline.
	**/
	public var playerID(default, set):Int = 0;
	function set_playerID(v:Int):Int {
		return playerID = v;
	}

	/**
	* The scroll speed for this field.
	**/
	public var scrollSpeed(default, set):Float;
	function set_scrollSpeed(v:Float):Float {
		return scrollSpeed = v;
	}

	/**
	* The scroll direction for this field.
	**/
	public var scrollDirection(default, set):ScrollDirection;
	function set_scrollDirection(v:ScrollDirection):ScrollDirection {
		return scrollDirection = v;
	}

	/**
	* Whether this field will play by itself or not.
	**/
	public var autoplay(default, set):Bool = false;
	function set_autoplay(v:Bool):Bool {
		return autoplay = v;
	}

	/**
	* Whether this field will try rendering scroll velocities.
	**/
	public var scrollVelocities:Bool = true;

	/**
	* Handles note spawning callbacks for this field.
	**/
	public var spawner:NoteSpawner;

	/**
	* This field's modchart.
	* If this is null, it will use normal HaxeFlixel rendering.
	**/
	#if !NEVERMORE_NO_MODCHARTS
	public var modchart:ModchartManager;
	#end

	/**
	* The input system for this field.
	* Initialize this for making your own input system.
	**/
	public var input:InputManager;

	/**
	* Gets a strumline instance.
	* @param id The ID for the wanted strumline.
	* @return The corresponding strumline.
	**/
	public function getStrumline(id:Int):Strumline {
		return null;
	}

	/**
	* The list of notes used for this field, from the chart file.
	**/
	public var unspawnedNotes(get, never):Array<NoteData>;
	function get_unspawnedNotes():Array<NoteData> return spawner.list;

	public function new() {
		super();

		spawner = new NoteSpawner();

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

		spawner.destroy();
		spawner = null;
	}

	/**
	* Loads a chart into the field.
	* @param chart The chart instance to load.
	* @param modifiers Any custom modifiers to use for this field.
	* (see `play/Modifiers`)
	**/
	public function load(chart:Chart, ?modifiers:Modifiers) {
		modifiers ??= {};
		if (chart.scrollVelocities.length <= 1) {
			modifiers.scrollVelocities = false;
		}
	
		scrollVelocities = modifiers.scrollVelocities;
		keyCount = chart.keyCount;
		
		if (!scrollVelocities) chart.scrollVelocities.resize(0);

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

	/**
	* Applies modifiers to a given chart.
	* @param chart The chart to modify.
	* @param modifiers The modifiers to be used.
	**/
	function applyModifiers(chart:Chart, modifiers:Modifiers) {
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

	/**
	* Is called whenever an action was pressed.
	* Add this to `input.onPress`.
	**/
	function pressed(id:Int, direction:Int) {}

	/**
	* Is called whenever an action was released.
	* Add this to `input.onRelease`.
	**/
	function released(id:Int, direction:Int) {}
}