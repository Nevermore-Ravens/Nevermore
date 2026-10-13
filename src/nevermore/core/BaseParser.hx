package nevermore.core;

#if moonchart
import moonchart.backend.FormatData;
import moonchart.backend.FormatDetector;
import moonchart.formats.BasicFormat;
import moonchart.formats.*;
import haxe.io.Path;

class BaseParser {
	public function new() {}

	// sm = StepMania
	// ssc = Spinal Shark Collective
	// osu = osu!mania (no std/taiko/catch sorry)
	// qua = Quaver
	// chart = Guitar/Clone Hero
	static var extensions:Array<String> = ['sm', 'ssc', 'osu', 'qua', 'chart'];

	// supports 2 methods
	// load('songs/Fuck/Fuck.sm', 'hard');
	// load('songs/Fuck/hard.osu');
	//
	// first method will load the file and use the diff specified
	// second method will just load the path specified
	// if the file doesn't exist for either, `result` gets thrown instead
	public function load(path:String, ?diff:String):Chart {
		var result:Chart = Song.dummyData();

		var singleDiff:Bool = diff.length == 0;

		if (!FileSystem.exists(path)) return result;

		var format = FormatDetector.instanceFromFiles([path]);
		var meta:BasicMetaData = format.getChartMeta();

		result.title = meta.title;
		result.offset = meta.offset;
		result.speed = meta.scrollSpeeds[singleDiff ? format.diffs[0] : diff];
		result.keyCount = meta.extraData[LANES_LENGTH]; // i have to do LANES_LENGTH if i want to compile, tho ill keep looking. - srt

		result.timingPoints = [
			for (change in meta.bpmChanges) {
				{
					time: change.time,
					tempo: change.bpm,
					beatsPerMeasure: Std.int(change.beatsPerMeasure)
				}
			}
		];

		result.notes = [
			for (note in format.getNotes(diff)) {
				{
					time: note.time,
					lane: note.lane,
					length: note.length,
					type: note.type
				}
			}
		];

		// moonchart doesn't support scroll velocities at the moment
		result.scrollVelocities = [];
		
		// TODO: figure out how to not apply this for osu/quaver only ?
		result.snapRelativeToChanges = true;

		return result;
	}

	public function exists(path:String, ?diff:String):Bool return false;
}

#else

class BaseParser {
	public function new() {}

	public function load(path:String, ?diff:String):Chart {
		return Song.dummyData();
	}

	public function exists(path:String, ?diff:String):Bool return false;
}
#end