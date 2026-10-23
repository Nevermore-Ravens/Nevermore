package nevermore.core;

import nevermore.core.*;

/**
* Handles returning/parsing chart files.
**/
class Song {
	/**
	* The parser instance.
	* Override this via `parser = NewParser();`,
	* if you're using your own parser.
	**/
	public static var parser:BaseParser = new BaseParser();

	/**
	* Returns a readable chart file via a given path and difficulty.
	* (see `BaseParser.load()`)
	* @return The chart file.
	**/
	public static function load(path:String, ?diff:String):Chart {
		if (parser == null) return dummyData();
		
		var chart:Chart = parser.load(path, diff);
		chart.clearStackedNotes();
		chart.sortTimingPoints();

		return chart;
	}

	/**
	* Checks if a file exists via a given path and difficulty.
	* (see `BaseParser.exists()`)
	* @return The result of the file check.
	**/
	public static function exists(path:String, ?diff:String):Bool {
		return parser.exists(path, diff);
	}

	/**
	* Returns a default data set of a chart file.
	**/
	public static function dummyData():Chart {
		return {
			title: '',
			timingPoints: [],
			scrollVelocities: [],
			notes: [],
			speed: 1,
			offset: 0,
			snapRelativeToChanges: true
		}
	}
}