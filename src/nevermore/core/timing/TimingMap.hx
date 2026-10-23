package nevermore.core.timing;

/**
* Allows for getting the beat, step, or measure via a set of points.
**/
class TimingMap {
	public var list(default, null):Array<TimingPoint> = [];

	public var length(get, never):Int;
	function get_length():Int return list.length;

	/**
	* The current tempo the map is at.
	**/
	public var tempo:Float;

	/**
	* The current beats per measure the map is at.
	**/
	public var beatsPerMeasure:Int;

	public function new() {}

	public function destroy() {
		list.resize(0);
		list = null;
	}

	/**
	* Resets this instance of the map.
	* @param points The list of timing points to use for this map.
	* @return The modified instance of this timing map.
	**/
	public function reset(points:Array<TimingPoint>):TimingMap {
		if (points.length == 0) points.push({});
		points.sort((a, b) -> return Std.int(a.time - b.time));

		list.resize(0);
        list = points.copy();

		tempo = list[0].tempo;
		beatsPerMeasure = list[0].beatsPerMeasure;

		// no need to do beat calculation for one point
		if (length == 1) return this;

		// pre-calculate all of the beats now
		// so we don't have to do it later
		var beat:Float = 0;
		var measure:Float = 0;
		var crotchet:Float = Util.crotchet(tempo);
		var beatsPerMeasure:Int = beatsPerMeasure;
		var lastTime:Float = 0;
		var lastBeat:Float = 0;

		for (point in list) {
			beat += (point.time - lastTime) / crotchet;
			measure += (beat - lastBeat) / beatsPerMeasure;

			lastTime = point.time;
			lastBeat = beat;
			crotchet = Util.crotchet(point.tempo);
			beatsPerMeasure = point.beatsPerMeasure;

			point.beat = beat;
			point.measure = measure;
		}

		return this;
	}

	/**
	* Gets the timing point at a specified point in time.
	* @param pos The song time.
	* @return The point at the position specified.
	**/
	@:pure public function getByTime(pos:Float):TimingPoint {
        var last:TimingPoint = list[0];

        for (point in list) {
            if (pos >= point.time) last = point;
            else break;
        }

		return last;
	}

	/**
	* Gets the row at a specified position.
	* @param pos The song time.
	* @param point The timing point to use as reference.
	* If no point is given, it will make its own.
	*
	* @return The row at the position specified.
	**/
	@:pure public function getRow(pos:Float, ?point:TimingPoint):Int {
		var result:Float = 0.0;
		if (length <= 1) {
			result = pos / Util.crotchet(tempo);
		} else result = getBeat(pos, point ?? getByTime(pos));

		return Math.round(result * Util.rowsPerBeat);
	}

	/**
	* Gets the beat at a specified position.
	* @param pos The song time.
	* @param point The timing point to use as reference.
	* If no point is given, it will make its own.
	*
	* @return The beat at the position specified.
	**/
	@:pure public function getBeat(pos:Float, ?point:TimingPoint):Float {
		if (length <= 1) return pos / Util.crotchet(tempo);
		point ??= getByTime(pos);

		var crotchet:Float = Util.crotchet(point.tempo);
		var distance:Float = (pos - point.time) / crotchet;
		return point.beat + distance;
	}

	/**
	* Gets the measure at a specified position.
	* @param pos The song time.
	* @param point The timing point to use as reference.
	* If no point is given, it will make its own.
	*
	* @return The measure at the position specified.
	**/
	@:pure public function getMeasure(pos:Float, ?point:TimingPoint):Float {
		if (length <= 1) return (pos / Util.crotchet(tempo)) / 4;
		point ??= getByTime(pos);

		var crotchet:Float = Util.crotchet(point.tempo);
		var distance:Float = (pos - point.time) / crotchet;
		return point.measure + (distance / point.beatsPerMeasure);
	}
}