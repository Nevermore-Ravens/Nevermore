package nevermore.play;

/**
* A list of chart modifiers to customize how some charts play.
**/
@:structInit
@:publicFields
class Modifiers {
	#if !NEVERMORE_NO_MODIFIERS

	/**
	* Whether sustains will be used.
	**/
	var sustains:Bool = true;

	/**
	* Whether scroll velocities will be used.
	**/
	var scrollVelocities:Bool = true;

	/**
	* If note lanes should be randomized.
	* Shuffles the lanes accordingly, so `0, 1, 2, 3`
	* can become `3, 1, 0, 2` or `2, 3, 0, 1`, and so on.
	**/
	var randomizedNotes:Bool = false;

	/**
	* Mirrors note lanes, so `0, 1, 2, 3` becomes `3, 2, 1, 0`.
	* Can work in tandem with `randomizedNotes`.
	**/
	var mirroredNotes:Bool = false;

	#else

	var sustains:Bool = true;
	var scrollVelocities:Bool = false;
	var randomizedNotes:Bool = false;
	var mirroredNotes:Bool = false;
	
	#end
}