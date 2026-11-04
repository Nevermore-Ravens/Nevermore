package nevermore.core.timing;

@:structInit
@:publicFields
class ScrollVelocity {
	/**
	The time at which this scroll velocity occurs,
	relative to the audio position.
	**/
	var time:Float = 0.0;

	/**
	How much this velocity's scroll speed should be modified by.
	*/
	var multiplier:Float = 1.0;

	/**
	The scroll velocity's visual playhead.
	*/
	var visualTime:Float = 0.0;

	public function new(?time:Float = 0.0, ?multiplier:Float = 1.0) {
		this.time = time;
		this.multiplier = multiplier;
	}

	/**
	Converts a specified position in time to visual position, or "pixels".
	@param noteTime The point in time in which this should occur.
	@return The visual position of this velocity in time, relative to the time specified.
	*/
	function toPixels(noteTime:Float) {
		return visualTime + ((noteTime - time) * multiplier);
	}
}