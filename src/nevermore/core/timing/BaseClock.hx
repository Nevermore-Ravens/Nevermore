package nevermore.core.timing;

import flixel.util.FlxSignal;

/**
* A clock instance that acts as a "metronome".
* It keeps track of what beat the audio is at, along with steps, measures, and what position.
*
* Extend this if you're looking to make your own sync.
**/
class BaseClock {
	/**
	* The audio connected to this clock instance.
	**/
	public var audio:FlxSound;

	/**
	* The raw audio position of this clock, in milliseconds.
	**/
	public var audioTime:Float;

	/**
	* The audio position of this clock with offset taken into account, in milliseconds.
	**/
	public var songTime:Float;

	/**
	* The audio position of this clock with offset taken into account, in milliseconds.
	* Make sure to use this as your sync.
	**/
	public var time:Float;

	/**
	* Basically `time`, but it takes scroll velocities into account.
	* Use this for note visual positions ONLY.
	**/
	public var visualTime:Float;

	/**
	* The audio offset for this clock.
	* Negative = Time moves forward.
	* Positive = Time moves backward.
	**/
	public var offset:Float;

	/**
	* The timing points for this clock.
	**/
	public var timingMap:TimingMap;

	/**
	* The scroll velocities for this clock.
	**/
	public var velocityMap:VelocityMap;

	/**
	* Whether this clock is allowed to update or not.
	**/
	public var active:Bool = true;

	/**
	* Whether a sound will be played every time a beat is hit or not.
	**/
	public var metronome:Bool = false;

	/**
	* A signal that gets dispatched whenever a step is hit.
	**/
	public var stepHit:FlxTypedSignal<Int -> Void>;

	/**
	* A signal that gets dispatched whenever a beat is hit.
	**/
	public var beatHit:FlxTypedSignal<Int -> Void>;

	/**
	* A signal that gets dispatched whenever a measure is hit.
	**/
	public var measureHit:FlxTypedSignal<Int -> Void>;
	
	public function new(?audio:FlxSound) {
		this.audio = audio;

		timingMap = new TimingMap();
		velocityMap = new VelocityMap();

		stepHit = new FlxTypedSignal<Int -> Void>();
		beatHit = new FlxTypedSignal<Int -> Void>();
		measureHit = new FlxTypedSignal<Int -> Void>();

		// yknow maybe ninjamuffin was onto something about making sounds yourself
		metronomeSound = new FlxSound().loadEmbedded(Assets.dependency.audio('sfx/metronome.wav'));
		metronomeSound.persist = true;
		metronomeSound.autoDestroy = false;
		FlxG.sound.list.add(metronomeSound);

		measureSound = new FlxSound().loadEmbedded(Assets.dependency.audio('sfx/metronome measure.wav'));
		measureSound.persist = true;
		measureSound.autoDestroy = false;
		FlxG.sound.list.add(measureSound);
	}

	public function destroy() {
		timingMap.destroy();
		timingMap = null;

		velocityMap.destroy();
		velocityMap = null;

		stepHit.destroy();
		stepHit = null;

		beatHit.destroy();
		beatHit = null;

		measureHit.destroy();
		measureHit = null;

		metronomeSound.destroy();
		FlxG.sound.list.remove(metronomeSound);
		metronomeSound = null;

		measureSound.destroy();
		FlxG.sound.list.remove(measureSound);
		measureSound = null;
	}

	public var rate(default, set):Float = 1.0;
	function set_rate(v:Float):Float {
		#if FLX_PITCH
		audio?.pitch = v;
		return rate = v;
		#else
		return rate = 1.0;
		#end
	}

	/**
	* Resets this clock back to default.
	* Make sure to run this *after* initialzing.
	**/
	public function reset(?chart:Chart) {
		chart ??= Song.dummyData();

		timingMap.reset(chart.timingPoints);
		audioTime = songTime = time = visualTime = 0.0;
		rate = 1.0;
		
		velocityMap.reset(chart.scrollVelocities);
		velocityIndex = 0;
		currentVelocity = {};
	}

	public function update(delta:Float) {
		if (!active) return;

		if (audio == null || !audio.playing) {
			audioTime += (delta * 1000) * rate;
		} else {
			@:privateAccess
			audioTime = audio._channel.position;
		}

		songTime = audioTime + offset;
		time = songTime;

		updateVelocities(time);
		updateBeats(songTime);
	}

	var velocityIndex:Int;
	var currentVelocity:ScrollVelocity;
	function updateVelocities(pos:Float) {
		var offsetedTime:Float = pos - Nevermore.settings.inputOffset;

		if (velocityMap.length == 0) {
			visualTime = offsetedTime;
			return;
		}

		for (i in (velocityIndex + 1) ... velocityMap.length) {
			var next:ScrollVelocity = velocityMap.list[i];
			if (next.time > offsetedTime) break;

			velocityIndex = i;
			currentVelocity = next;
		}

		visualTime = currentVelocity.toPixels(offsetedTime);
	}

	public var metronomeSound:FlxSound;
	public var measureSound:FlxSound;

	public var step:Float;
	var iStep:Int;

	public var beat:Float;
	var iBeat:Int;

	public var measure:Float;
	var iMeasure:Int;

	/**
	NOTE:

	This uses *setting* beats, rather than incrementing them.
	The reason why this is so important to mention is because in some circumstances,
	incrementing beats can be more accurate, but it still has its downsides.

	With incrementing, you have the benefit of being *slightly* more accurate, at the cost
	of being only able to go forwards (you can rewind, but it's a pain in the ASS to figure out).
	Tempo changes are a problem as well, but aren't that bad if you know what you're doing.

	Setting beats has both upsides and downsides as well.
	You have the benefit of it being easier to set up and use,
	but it's not as accurate as incrementing.

	This doesn't mean both methods aren't viable to use, however.
	Despite incrementing beats being the absolutely more accurate method, setting beats is more widely used
	than any other timing method.

	https://github.com/ppy/osu/blob/master/osu.Game/Graphics/Containers/BeatSyncedContainer.cs#L13
	https://github.com/stepmania/stepmania/blob/5_1-new/src/TimingData.cpp#L911
	https://github.com/etternagame/etterna/blob/develop/src/Etterna/Models/Misc/TimingData.cpp#L828
	https://github.com/quaver/Quaver/blob/master/Quaver.Shared/Screens/Edit/Timing/Metronome.cs#L107
	https://github.com/uvcat7/ArrowVortex/blob/beta/src/Simfile/TimingData.cpp#L395-409

	The only game(s) that I know of that increment beats is Rhythm Doctor, or A Dance of Fire and Ice.
	However, that's speculation; as both games are closed source, and can only be viewed via decompiling.
	The only evidence to back up this claim is an old rhythm crash-course that 7th Beat Games (or its lead programmer, Giacomo Preciado)
	posted on Reddit, where it shows incrementing instead of setting, like most other rhythm games out there.

	In the end, I went with setting beats. In my opinion, the accuracy is negligable, and I didn't wanna spend a bunch of time
	trying to make incrementing work like I wanted it to when I could just set up setting faster.

	Realistically, it depends on what you're doing and what you need it for, especially in the game engine you're developing in.
	**/
	function updateBeats(pos:Float) {
		var point:TimingPoint = null;
		
		if (timingMap.length > 1) {
			point = timingMap.getByTime(pos);
		}

		beat = timingMap.getBeat(pos, point);
		step = beat * 4; // TODO: add stepsPerBeat support later ?
		measure = timingMap.getMeasure(pos, point);

		var nextStep:Int = Math.floor(step);
		if (nextStep != iStep) {
			stepHit.dispatch(iStep = nextStep);
		}

		var nextBeat:Int = Math.floor(beat);
		if (nextBeat != iBeat) {
			beatHit.dispatch(iBeat = nextBeat);

			if (metronome) {
				var newMeasure:Bool = nextBeat % timingMap.beatsPerMeasure == 0;

				metronomeSound.play(true);
				if (newMeasure) measureSound.play(true);
			}
		}

		var nextMeasure:Int = Math.floor(measure);
		if (nextMeasure != iMeasure) {
			measureHit.dispatch(iMeasure = nextMeasure);
		}
	}
}