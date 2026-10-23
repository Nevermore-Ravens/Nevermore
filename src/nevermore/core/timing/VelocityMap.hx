package nevermore.core.timing;

/**
* Allows for getting time relative to scroll velocities, via a list of points.
**/
class VelocityMap {
	public var list:Array<ScrollVelocity>;
	public var length:Int = 0;

	public function new(?list:Array<ScrollVelocity>) {
		reset(list);
	}

	/**
	* Resets this instance of the map.
	* @param list The list of scroll velocities to use for this map.
	* @return The modified instance of this velocity map.
	**/
	public function reset(?list:Array<ScrollVelocity>) {
		list ??= [];
		
		length = list.length;

		for (i in 1...list.length) {
			list[i].visualTime = list[i - 1].toPixels(list[i].time);
		}

		this.list = list;
	}

	public function destroy() {
		list.resize(0);
		list = null;
	}

	/**
	* Gets a scroll velocity at a specified point in time.
	* @param pos The song time.
	* @return The scroll velocity at the position specified.
	**/
	public function get(pos:Float):ScrollVelocity {
		if (length == 0) return {};
		var last:ScrollVelocity = list[0];

		for (i in 0...list.length) {
			var point = list[i];

			if (pos >= point.time) last = point;
			else break;
		}

		return last;
	}

	/**
	* Converts song position into visual position from a specific scroll velocity.
	* @param time The song time.
	* @return The converted time relative to the nearest scroll velocity.
	**/
	public function getPosition(time:Float):Float {
		if (length == 0) return -1;
		return get(time).toPixels(time);
	}
}