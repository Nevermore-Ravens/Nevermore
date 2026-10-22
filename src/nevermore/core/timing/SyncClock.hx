package nevermore.core.timing;

class SyncClock extends BaseClock {
	var _lastTime:Float = 0.0;
	override function reset(?chart:Chart):Void {
		super.reset(chart);
		_lastTime = 0.0;
	}

	override function update(delta:Float) {
		delta *= (rate * 1000);

		if (audio == null || !audio.playing) {
			audioTime += delta;
		} else {
			@:privateAccess
			audioTime = audio._channel.position;
		}

		songTime = audioTime + offset;

		// normally the stepmania method would work here
		// (see https://github.com/stepmania/stepmania/blob/5_1-new/src/GameState.cpp#L1270-1287)
		// however the audio system we're working with here is vastly different compared to rage
		// rage is per millisecond, or even MICROSECOND precise
		// but in flixel, we have to work with 10-20 millisecond intervals
		// which basically just brings back the stuttering the sync was trying to fix in the first place
		// so in order to circumvent that, we rework what they did a little bit
		if (audioTime == _lastTime) time += delta;
		else {
			if (Math.abs(songTime - time) >= delta) time = songTime;
			else time += delta;

			_lastTime = audioTime;
		}

		updateVelocities(time);
		updateBeats(time);
	}
}