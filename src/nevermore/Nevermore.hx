package nevermore;

#if !NEVERMORE_NO_MODCHARTS
import nevermore.modchart.ModchartManager;
#end
import nevermore.backend.Git.Commit;

import nevermore.play.behaviors.*;

enum abstract ScrollDirection(String) from String to String {
	var UP = 'Up';
	var DOWN = 'Down';
	var NONE = 'None';
	//var TAIKO = 'Taiko no Tatsujin';
}

@:structInit
@:publicFields
class NevermoreSettings {
	/**
	 * Shifts the time of all notes forward or backward.
	 * Moves where a hit is considered 0 milliseconds, relative to the audio.
	 * Lower values mean notes will spawn earlier, so you have to hit earlier, and vice versa.
	**/
	var inputOffset:Float = 0;

	/**
	 * Otherwise known as moving the "judgement line".
	 * Moves where a hit is considered 0 milliseconds relative to the receptors, and not the audio.
	 * Lower values moves the line to be "after" the receptors.
	**/                                     
	var visualOffset:Float = 0;

	/**
	 * The delay in the audio driver itself.
	 * When audio is played, it doesn't play *exactly* when it should,
	 * resulting in it playing a couple milliseconds later.
	 * This causes the time of the sound object being slightly behind
	 * than where the actual sound position is.
	 * This variable accounts for that.
	**/

	// TODO (maybe):
	// this variable doesn't actually do shit lol
	// afaik getting audio driver offset is pretty much impossible on lime
	// if it isn't maybe try and figure it out later ? i feel like this would
	// be useful for hitsounds
	var audioOffset:Float = 0.0;

	#if !NEVERMORE_NO_QUANTIZATION
	/**
	 * Changes note colours to resemble what beat they are snapped at.
	 * Uses StepMania's noteskin colours by default.
	 * (see core/NoteColor.hx)
	**/
	var quantization:Bool = false;
	#end

	/**
	 * How many times the game will compress sustain vertices.
	 * Higher values will stretch the hold graphic for more performance.
	 * Recommended to be at lower values if you're playing modcharts,
	 * but otherwise higher values for casual play.
	**/
	var holdGrain:Int = 5;

	// How many times the NOTEFIELDS will render per second! setting this to your monitor's HZ value or double is recommended.
	var notefieldFramerate = 60;
}

class Nevermore {
	public static final version:String = '1.0.0';

	public static var settings:NevermoreSettings = null;
	public static var keyCount:Int = 4;
	
	// why does flixel not have a variable for this
	public static var paused(get, never):Bool;
	static function get_paused():Bool {
		return !FlxG.state.persistentUpdate && FlxG.state.subState != null;
	}

	public static var initialized:Bool = false;

	public static var commit(get, never):Commit;
	static function get_commit():Commit return Git.commit;

	public static var branch(get, never):String;
	static function get_branch():String return Git.branch;

	public static function init() {
		if (initialized) return;
		initialized = true;

		Assets.init();

		FlxG.plugins.add(new Conductor());
		Controls.init();
		Judgement.init();

		NoteBehavior.register('Fake', FakeBehavior);
		NoteBehavior.register('Mine', MineBehavior);
		NoteBehavior.register('Roll', RollBehavior);

		NoteColor.reset();

		#if !NEVERMORE_NO_MODCHARTS 
		ModchartManager.setupRedirects();
		#end

		FlxG.signals.postStateSwitch.add(() -> {
			FlxG.camera.bgColor = 0x00;
			Assets.cache.clearUnused();
		});

		settings = {};
	}
}