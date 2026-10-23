package nevermore.core;

/**
* Contains data for a note object.
**/
@:structInit
@:publicFields
class NoteData {
	/**
	* The time at which this note occurs, in milliseconds.
	**/
	var time:Float = 0.0;

	/**
	* The visual position at which the note determines is
	* 0 milliseconds of deviation, or the "strum bar".
	* Used for scroll velocities.
	**/
	var visualTime:Float = 0.0;

	/**
	* What lane this note should be in.
	**/
	var lane:Int = 0;

	/**
	* What player side this note is on, in left to right order.
	**/
	var player:Int = 0;

	/**
	* The corresponding ID of the snap for this note.
	**/
	var snapID:Int = -1;

	/**
	* What beat this note occurs at.
	* Used in modcharting.
	**/
	var beat:Float = 0.0;

	/**
	* The type/behavior this note is connected to.
	**/
	var type:String = '';

	/**
	* The time at which a sustain will end, visually, in milliseconds.
	* Used for scroll velocities.
	**/
	var visualEnd:Float = 0.0;

	/**
	* How long the connected sustain will be, in milliseconds.
	**/
	var length:Float = 0.0;
}