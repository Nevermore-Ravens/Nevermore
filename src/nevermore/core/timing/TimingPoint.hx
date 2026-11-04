package nevermore.core.timing;

@:structInit
class TimingPoint {
	/**
	The time at which this point occurs in milliseconds,
	relative to the song position.
	*/
	public var time:Float = 0;

	/**
	The tempo/beats per minute of this point.
	*/
	public var tempo:Float = 120;

	/**
	The amount of beats per measure this point onward uses.
	*/
	public var beatsPerMeasure:Int = 4;

	/**
	The beat at which this point occurs, relative to the song position.
	*/
	public var beat:Float = 0;

	/**
	The measure at which this point occurs, relative to the song position.
	*/
	public var measure:Float = 0;

	function toString():String {
		return 'Time: ${time}ms | Tempo: $tempo';
	}
}