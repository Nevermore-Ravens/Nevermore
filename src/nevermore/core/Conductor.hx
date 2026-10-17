package nevermore.core;

import nevermore.core.timing.*;

class Conductor extends flixel.FlxBasic {
	@:isVar public static var tempo(get, set):Float;
	public static var crotchet(get, never):Float;
	static function get_crotchet():Float {
		return Util.crotchet(timingMap.tempo);
	}

	@:isVar public static var metronome(get, set):Bool;
	static function get_metronome():Bool return clock.metronome;
	static function set_metronome(v:Bool):Bool {
		return clock.metronome = v;
	}

	public static var semiquaver(get, never):Float;
	static function get_semiquaver():Float {
		return crotchet / 4;
	}

	static function get_tempo():Float return timingMap.tempo;
	static function set_tempo(v:Float):Float {
		if (timingMap.length > 1) return tempo;
		return timingMap.tempo = v;
	}

	public static var step(get, never):Float;
	static function get_step():Float {
		return clock.step;
	}

	public static var beat(get, never):Float;
	static function get_beat():Float {
		return clock.beat;
	}

	public static var measure(get, never):Float;
	static function get_measure():Float {
		return clock.measure;
	}

	@:isVar public static var offset(get, set):Float;
	static function get_offset():Float return clock.offset;
	static function set_offset(v:Float):Float return clock.offset = v;

	public static var clock(default, set):BaseClock;
	static function set_clock(v:BaseClock):BaseClock {
		if (v == null) return clock; // clock can't be null ever
		return clock = v;
	}

	public static var timingMap(get, never):TimingMap;
	static function get_timingMap():TimingMap {
		return clock.timingMap;
	}

	public static var inst(default, set):FlxSound;
    static function set_inst(value:FlxSound):FlxSound {
		if (inst != null) inst.stop();
    	if (value == null) return clock.audio = value;

        value.persist = true;
		value.volume = volume;
		#if FLX_PITCH value.pitch = rate; #end
        return clock.audio = inst = value;
    }

	public static var vocals(default, set):FlxSound;
    static function set_vocals(value:FlxSound):FlxSound {
		if (vocals != null) vocals.stop();

    	if (value != null) {
			value.persist = true;
			value.volume = volume;
			#if FLX_PITCH value.pitch = rate; #end
		}
		
        return vocals = value;
    }

	public static var volume(default, set):Float = 1.0;
	static function set_volume(v:Float):Float {
		if (inst != null) inst.volume = v;
		if (vocals != null) vocals.volume = v;

		return volume = v;
	}

	#if FLX_PITCH
	@:isVar public static var rate(get, set):Float = 1.0;
	static function get_rate():Float return clock.rate;
	static function set_rate(v:Float):Float {
		if (inst != null) inst.pitch = v;
		if (vocals != null) vocals.pitch = v;

		return clock.rate = v;
	}
	#else
	public static var rate:Float = 1.0;
	#end

	// raw sound.time
	@:isVar public static var audioTime(get, set):Float;
	static function get_audioTime():Float return clock.audioTime;
	static function set_audioTime(v:Float):Float {
		if (!_playing) return clock.audioTime = v;
		return inst.time = v;
	}

	// sound.time + offset
	public static var songTime(get, never):Float;
	static function get_songTime():Float return clock.songTime;

	// `songTime` but more smoothed out 
	// 'cause it's trying to predict time
	// this is your sync
	public static var time(get, never):Float;
	static function get_time():Float return clock.time;

	public static function reset():Void {
		clock.reset();
		clock.stepHit.removeAll();
		clock.beatHit.removeAll();
		clock.measureHit.removeAll();

		tempo = 120;
		volume = 1.0;
		rate = 1.0;
		vocals = null;
	}

	public static function play() {
		if (inst != null) inst.play();
		if (vocals != null) vocals.play();

		clock.active = true;
		_playing = true;
	}

	public static function stop() {
		if (inst != null) inst.stop();
		if (vocals != null) vocals.stop();

		clock.active = false;
		_playing = false;
	}

	public static function pause() {
		if (inst != null) inst.pause();
		if (vocals != null) vocals.pause();

		clock.active = false;
	}

	public static function resume() {
		if (inst != null) inst.resume();
		if (vocals != null) vocals.resume();

		clock.active = true;
	}

	// internal variable to tell if the song started playing or not
	static var _playing:Bool = false;

	public function new() {
		super();
		clock = new SyncClock();
		reset();
	}

	var vocalReboundTime:Float = 15;
	override function update(delta:Float):Void {
		if (clock.active) {
			clock.update(delta);
		}

		// apparently even after it's done playing
		// this still triggers ?????
		// ok flixel
		if (vocals == null || !vocals.playing) return;

		// trying to sync vocals with streamed audio
		// kinda       Doesn't work
		// extremely laggy whenever unpausing and
		// sometimes it'll just keep resyncing
		// which sounds like shit and ruins fps
		#if (lime >= version("8.4.0"))
		@:privateAccess
		var streamed:Bool = vocals._sound.__buffer.data == null;
		if (streamed) vocalReboundTime = 30;
		#end

		if (Math.abs(inst.time - vocals.time) >= vocalReboundTime) {
			vocals.time = inst.time;
		}
	}
}