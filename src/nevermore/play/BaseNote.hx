package nevermore.play;

import nevermore.core.timing.BaseClock;
import nevermore.modchart.ModchartManager;
import flixel.graphics.frames.FlxFrame;
import lime.system.System;

// a data-driven note class that you can build off of 
// for making your own note(field) system
// no rendering/drawing is done
class BaseNote extends NoteObject {
	public var behavior:NoteBehavior;

	public var strumline:Strumline;
	public var field:NoteField;
	public var receptor:Receptor;

	public var passedStrumline:Bool;

	public var adjustedTime(get, never):Float;
	function get_adjustedTime():Float {
		return time + Nevermore.settings.inputOffset;
	}

	public var data:NoteData;

	public var multAlpha:Float = 1;
	public var distance:Float = 0.0;
	
	public var visualTime(get, never):Float;
	function get_visualTime():Float {
		var pos:Float = data.visualTime;

		if (pos == 0) return time;
		return pos;
	}

	public var time:Float = 0.0;
	public var player:Int = 0;
	public var length:Float = 0.0;
	public var beat:Float = 0.0;
	public var missed:Bool = false;

	public var type(default, set):String;
	function set_type(v:String):String {
		return type = v;
	}

	// kind of unintentional but also could be
	// REALLY funny for some modcharts
	public var clock(get, default):BaseClock;
	function get_clock():BaseClock {
		clock ??= Conductor.clock;
		return clock;
	}

	public function getDeviation(?timestamp:Float = 0.0):Float {
		var result:Float = clock.time - adjustedTime;

		if (timestamp > 0) {
			// this doesn't seem to do much for lagspikes
			// but i'll take it
			result -= timestamp - System.getTimer();
		}

		return result / clock.rate;
	}

	public function move(clock:BaseClock):Void {}

	public function new() super();

	public var inRange(get, never):Bool;
	function get_inRange():Bool {
		return behavior.inRange(this);
	}

	public var late(get, never):Bool;
	function get_late():Bool {
		return behavior.isLate(this);
	}

	public function drawCrazy(modchart:ModchartManager, direction:ScrollDirection) {}
}