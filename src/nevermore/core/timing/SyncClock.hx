package nevermore.core.timing;

/**
* An extended version of `BaseClock` that applies sync.
* Use this as a reference for when making your own sync method.
**/
class SyncClock extends BaseClock {
	var _lastTime:Float = 0.0;
	override function reset(?chart:Chart):Void {
		super.reset(chart);
		_lastTime = 0.0;
	}

	override function update(delta:Float) {
		if (!active) return;

		delta *= (rate * 1000);

		if (audio == null || !audio.playing) {
			audioTime += delta;
		} else {
			@:privateAccess
			audioTime = audio._channel.position;
		}

		songTime = audioTime + offset;

		/**
		NOTE:

		Normally, the StepMania method would work here.
		(see https://github.com/stepmania/stepmania/blob/5_1-new/src/GameState.cpp#L1272-1287)

		However, the audio system we're working with here (OpenAL) is vastly different compared to Rage.

		Rage has direct access to the operating system's drivers, so it can be as precise as it wants.
		(see https://github.com/stepmania/stepmania/blob/5_1-new/src/arch/Sound)

		In HaxeFlixel, we're working on top of 3 already existing libraries: OpenAL, Lime, and OpenFL.
		The most accurate we can get is whatever Lime provides with its context of OpenAL.
		You can mitigate *some* of it by making a `alsoft.ini` file (which i did here), but on my end I
		can only get it as low as ~10 milliseconds.

		Which means; if we try and use StepMania's sync method, it won't look/play as smooth as theirs,
		especially when this is Flash reincarnate.

		I tried looking at FlashFlashRevolution, but I think 
		it uses frames for sync instead of time, so fuck that.

		To circumvent around this, we modify StepMania's method a little.
		For comparison sake, I'll leave their method ported to Haxe here.
		**/
		
		#if FALSE
		// StepMania method
		if (audioTime == _lastTime) {
			time += delta;
		} else {
			time = songTime;
			_lastTime = audioTime;
		}

		#else

		// Our method
		if (audioTime == _lastTime) {
			time += delta;
		} else {
			if (Math.abs(songTime - time) >= delta) time = songTime;
			else time += delta;

			_lastTime = audioTime;
		}
		#end

		updateVelocities(time);
		updateBeats(time);
	}
}