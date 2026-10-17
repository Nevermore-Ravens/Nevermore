package nevermore.core.timing;

import flixel.util.FlxSignal;

// NOTE:
// this uses SETTING beats, rather than incrementing them
// the reason why this is so important to mention is because in some circumstances
// incrementing beats can be more accurate, but it still has its downsides
// with incrementing, you have the benefit of being more accurate at the cost
// of being only able to go forwards (you can rewind, but it's a PAIN in the ass)
// tempo changes are a problem as well, but aren't that bad if you know how to write it
//
// setting beats has benefits as well as its downsides
// setting beats has the benefit of being easier to set up and work with,
// at the downside of being SLIIIGGGHTLY less accurate
//
// this doesn't mean both methods aren't viable, however
// despite incrementing being the possibly more accurate version, setting beats is more widely used
// than any other timing method
// 
// https://github.com/ppy/osu/blob/master/osu.Game/Graphics/Containers/BeatSyncedContainer.cs#L13
// https://github.com/stepmania/stepmania/blob/5_1-new/src/TimingData.cpp#L911
// https://github.com/etternagame/etterna/blob/develop/src/Etterna/Models/Misc/TimingData.cpp#L828
// https://github.com/quaver/Quaver/blob/master/Quaver.Shared/Screens/Edit/Timing/Metronome.cs#L107
// https://github.com/uvcat7/ArrowVortex/blob/beta/src/Simfile/TimingData.cpp#L395-409
//
// the only game(s) that i know of that increments beats is rhythm doctor/adofai, but that's speculation
// as both games are closed source
// and the only information to back it up is a reddit post the developer made on reddit as a rhythm crash course
//
// in the end i went with setting beats, as it was easy to set up and the accuracy in my opinion is negligable
// but it depends on what you're doing and what you need it for, especially what game engine you're using
class BaseClock {
	public var audioTime:Float;
	public var songTime:Float;
	public var time:Float;
	public var visualTime:Float;

	public var timingMap:TimingMap;
	public var velocityMap:VelocityMap;

	public var active:Bool = true;
	
	public var audio:FlxSound;
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

	public var offset:Float;
	#if FLX_PITCH 
	public var rate:Float;
	#else
	public var rate(default, set):Float;
	function set_rate(_):Float {
		return rate = 1.0;
	}
	#end
	public function reset(?chart:Chart) {
		chart ??= Song.dummyData();

		timingMap.reset(chart.timingPoints);
		audioTime = songTime = time = visualTime = 0.0;
		rate = 1.0;
		
		velocityMap.reset(chart.scrollVelocities);
		velocityIndex = 0;
		currentVelocity = {};
	}

	public var stepHit:FlxTypedSignal<Int -> Void>;
	public var beatHit:FlxTypedSignal<Int -> Void>;
	public var measureHit:FlxTypedSignal<Int -> Void>;
	public function update(delta:Float) {
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

	public var metronome:Bool = false;

	public var metronomeSound:FlxSound;
	public var measureSound:FlxSound;

	public var step:Float;
	var iStep:Int;

	public var beat:Float;
	var iBeat:Int;

	public var measure:Float;
	var iMeasure:Int;

	// TODO:
	// for some reason when starting with negative time (ie positive offset)
	// beat hits at 0 just don't seem to occur at all ?
	//
	// also maybe add stepsPerBeat support later
	// (if i can figure out how the fuck it works)
	function updateBeats(pos:Float) {
		var point:TimingPoint = null;
		
		if (timingMap.length > 1) {
			point = timingMap.getByTime(pos);
		}

		beat = timingMap.getBeat(pos, point);
		step = beat * 4;
		measure = timingMap.getMeasure(pos, point);

		var nextStep:Int = Std.int(step);
		if (nextStep != iStep) {
			stepHit.dispatch(iStep = nextStep);
		}

		var nextBeat:Int = Std.int(beat);
		if (nextBeat != iBeat) {
			beatHit.dispatch(iBeat = nextBeat);
			if (metronome) {
				var newMeasure:Bool = nextBeat % timingMap.beatsPerMeasure == 0;
				(newMeasure ? measureSound : metronomeSound).play();
			}
		}

		var nextMeasure:Int = Std.int(measure);
		if (nextMeasure != iMeasure) {
			measureHit.dispatch(iMeasure = nextMeasure);
		}
	}
}