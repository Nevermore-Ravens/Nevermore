package nevermore.core;

#if moonchart
import moonchart.backend.FormatData;
import moonchart.backend.FormatDetector;
import moonchart.formats.BasicFormat;
import moonchart.formats.*;
import haxe.io.Path;

/**
* A class meant for parsing a chart file and giving the result in a readable format.
* If you have Moonchart labeled as a library on your project, it will automatically
* use an implementation of the library for you.
* If you don't have Moonchart labeled, you'll have to write your own parser by extending this class.
**/
class BaseParser {
	public function new() {}

	/**
	* Parses a chart file from a given path.
	* @param path The path to the chart file. (ex. `assets/songs/Game Time/file.sm`)
	* @param diff The difficulty for this chart file.
	* Is only applicable for files such as `.sm`, `.ssc`, and `.chart`.
	*
	* @return The data of the chart (and according difficulty) in a readable, universal format.
	**/
	public function load(path:String, ?diff:String):Chart {
		var result:Chart = Song.dummyData();

		var singleDiff:Bool = diff.length == 0;

		if (!exists(path)) return result;

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

	/**
	* Whether or not a chart file exists.
	* @param path The path to the chart file.
	* @param diff What difficulty to check for.
	* Is only applicable for files such as `.json` (FNF Legacy), `.osu`, and `.qua`
	* (not in this function however).
	*
	* @return The result of the file check.
	**/
	public function exists(path:String, ?diff:String):Bool return FileSystem.exists(path);
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