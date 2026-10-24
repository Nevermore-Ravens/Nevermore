package nevermore.play;

import nevermore.core.timing.BaseClock;
import nevermore.modchart.ModchartManager;
import flixel.graphics.frames.FlxFrame;
import lime.system.System;

/**
* A basic note class that offers the essentials for
* making your own note + notefield system.
* No (custom) rendering or updating is done here, you'll have to implement your own.
**/
class BaseNote extends NoteObject {
	/**
	* The connected behavior instance for this note.
	**/
	public var behavior:NoteBehavior;

	/**
	* The connected strumline for this note.
	**/
	public var strumline:Strumline;

	/**
	* The connected field for this note.
	**/
	public var field:BaseField;

	/**
	* The connected receptor for this note.
	**/
	public var receptor:Receptor;

	/** 
	* Whether this note passed its time point, or the "strum bar".
	**/
	public var passedStrumline:Bool;

	/**
	* The note's time, with input offset taken into account.
	**/
	public var adjustedTime(get, never):Float;
	function get_adjustedTime():Float {
		return time + Nevermore.settings.inputOffset;
	}

	/**
	* The corresponding data object for this note.
	**/
	public var data:NoteData;

	/**
	* How much to multiply this note's alpha by the receptor's alpha.
	**/
	public var multAlpha:Float = 1;

	/**
	* The distance in time between the note's time point and the song clock, in milliseconds.
	**/
	public var distance:Float = 0.0;
	
	/**
	* The visual position of this note in milliseconds that visually changes
	* what is considered 0 milliseconds, or the "strum bar".
	* Does not affect `passedStrumline`.
	*
	* Used by scroll velocities. 
	**/
	public var visualTime(get, never):Float;
	function get_visualTime():Float {
		var pos:Float = data.visualTime;

		if (pos == 0) return time;
		return pos;
	}
	
	/**
	* The time point of this note, in milliseconds.
	**/
	public var time:Float = 0.0;

	/**
	* What player this note is linked to.
	**/
	public var player:Int = 0;

	/**
	* The length of this note's sustain, in milliseconds (if it has one).
	**/
	public var length:Float = 0.0;

	/**
	* The beat point that this note is at.
	**/
	public var beat:Float = 0.0;

	/**
	* Whether this note has been missed or not.
	**/
	public var missed:Bool = false;

	/**
	* This note's corresponding type.
	**/
	public var type(default, set):String;
	function set_type(v:String):String {
		return type = v;
	}

	/**
	* This note's individual clock.
	**/
	public var clock(get, default):BaseClock;
	function get_clock():BaseClock {
		clock ??= Conductor.clock;
		return clock;
	}

	/**
	* Gets the distance between the time point of this note and the song clock.
	* Negative values mean the note is too early (not past the strumline).
	* Positive values mean it's too late (already past the strumline).
	*
	* @param timestamp The last input timestamp.
	* @return The distance of the note and the clock.
	**/
	public function getDeviation(?timestamp:Float = 0.0):Float {
		var result:Float = clock.time - adjustedTime;

		if (timestamp > 0) {
			// this doesn't seem to do much for lagspikes
			// but i'll take it
			result -= timestamp - System.getTimer();
		}

		return result / clock.rate;
	}

	/**
	* Moves the note's visual position, relative to the clock.
	* @param clock The clock to base the visuals off of.
	**/
	public function move(clock:BaseClock):Void {}

	public function new() super();

	/**
	* Whether this note is in range to be hit.
	**/
	public var inRange(get, never):Bool;
	function get_inRange():Bool {
		return behavior.inRange(this);
	}

	/**
	* Whether this note is too late, and should be missed.
	**/
	public var late(get, never):Bool;
	function get_late():Bool {
		return behavior.isLate(this);
	}

	/**
	* Custom rendering for modcharting capabilities.
	* @param modchart The current modchart manager to use.
	* @param direction What direction the note should be going.
	**/
	public function drawCrazy(modchart:ModchartManager, direction:ScrollDirection) {}
}