package nevermore.core;

enum abstract HitWindowType(String) from String to String {
	var STEPMANIA_J1 = 'StepMania J1';
	var STEPMANIA_J2 = 'StepMania J2';
	var STEPMANIA_J3 = 'StepMania J3';
	var STEPMANIA_J4 = 'StepMania J4';
	var STEPMANIA_J5 = 'StepMania J5';
	var STEPMANIA_J6 = 'StepMania J6';
	var STEPMANIA_J7 = 'StepMania J7';
	var STEPMANIA_J8 = 'StepMania J8';
	var STEPMANIA_JUSTICE = 'StepMania Justice';

	var OSU_MANIA_OD1 = 'osu!mania OD1';
	var OSU_MANIA_OD2 = 'osu!mania OD2';
	var OSU_MANIA_OD3 = 'osu!mania OD3';
	var OSU_MANIA_OD4 = 'osu!mania OD4';
	var OSU_MANIA_OD5 = 'osu!mania OD5';
	var OSU_MANIA_OD6 = 'osu!mania OD6';
	var OSU_MANIA_OD7 = 'osu!mania OD7';
	var OSU_MANIA_OD8 = 'osu!mania OD8';
	var OSU_MANIA_OD9 = 'osu!mania OD9';
	var OSU_MANIA_OD10 = 'osu!mania OD10';

	var QUAVER_PEACEFUL = 'Quaver (Peaceful)';
	var QUAVER_LENIENT = 'Quaver (Lenient)';
	var QUAVER_CHILL = 'Quaver (Chill)';
	var QUAVER_STANDARD = 'Quaver (Standard)';
	var QUAVER_STRICT = 'Quaver (Strict)';
	var QUAVER_TOUGH = 'Quaver (Tough)';
	var QUAVER_EXTREME = 'Quaver (Extreme)';
	var QUAVER_IMPOSSIBLE = 'Quaver (Impossible)';

	var DDR = 'DanceDanceRevolution';
	var ITG = 'In The Groove';

	var FNF_LEGACY = "Friday Night Funkin' (Legacy)";
	var FNF_WEEK7 = "Friday Night Funkin' (Week 7)";
	var FNF = "Friday Night Funkin'";
}

class HitWindows {
	public static var list:Map<String, Array<Float>> = [
		// etterna limits the bad/boo window to 180 for anything above j4
		// but for the sake of it being stepmania im not doing that
		'StepMania J1' => [33.75, 67.5, 135, 202.5, 270],
		'StepMania J2' => [29.925, 59.85, 119.7, 179.55, 239.4],
		'StepMania J3' => [26.1, 52.2, 104.4, 156.6, 208.8],
		'StepMania J4' => [22.5, 45, 90, 135, 180],
		'StepMania J5' => [18.9, 37.8, 75.6, 113.4, 151.2],
		'StepMania J6' => [14.85, 29.7, 59.4, 89.1, 118.8],
		'StepMania J7' => [11.25, 22.5, 45, 67.5, 90],
		'StepMania J8' => [7.425, 14.85, 29.7, 44.55, 59.4],
		'StepMania Justice' => [4.5, 9, 18, 27, 36],

		'osu!mania OD1' => [16, 61, 94, 124, 148],
		'osu!mania OD2' => [16, 58, 91, 121, 145],
		'osu!mania OD3' => [16, 55, 88, 118, 142],
		'osu!mania OD4' => [16, 52, 85, 115, 139],
		'osu!mania OD5' => [16, 49, 82, 112, 136],
		'osu!mania OD6' => [16, 46, 79, 109, 133],
		'osu!mania OD7' => [16, 43, 76, 106, 130],
		'osu!mania OD8' => [16, 40, 73, 103, 127],
		'osu!mania OD9' => [16, 37, 70, 100, 124],
		'osu!mania OD10' => [16, 33, 66, 97, 121],

		'Quaver (Peaceful)' => [23, 57, 101, 141, 169],
		'Quaver (Lenient)' => [21, 52, 91, 128, 153],
		'Quaver (Chill)' => [19, 47, 83, 116, 139],
		'Quaver (Standard)' => [18, 43, 76, 106, 127], // til this is basically just osu!mania od7
		'Quaver (Strict)' => [16, 39, 69, 96, 127],
		'Quaver (Tough)' => [14, 35, 62, 87, 127],
		'Quaver (Extreme)' => [13, 32, 57, 79, 127],
		'Quaver (Impossible)' => [8, 20, 35, 49, 127],

		"Friday Night Funkin' (Legacy)" => [33.34, 125, 150, 166.67],
		"Friday Night Funkin' (Week 7)" => [33.34, 91.69, 133.34, 166.67],
		"Friday Night Funkin'" => [/* 12.5, */45, 90, 135, 160], // StepMania J4 but bads are 160 instead of 180

		// these i got from project outfox
		// as i really don't have a concrete way of getting these (tmk)
		'DanceDanceRevolution' => [17, 34, 84, 124, 160],
		'In The Groove' => [23, 44.5, 103.5, 136.5, 181.2]
	];

	public static var min(get, never):Float;
	static function get_min():Float return current[0];

	public static var max(get, never):Float;
	static function get_max():Float return current[current.length - 1];

	public static function register(name:String, windows:Array<Float>) {
		list.set(name, windows);
	}

	public static var current:Array<Float>;
	public static var type(default, set):HitWindowType;
	static function set_type(v:HitWindowType):HitWindowType {
		current = list[v];
		return type = v;
	}

	public static function reset(type:String) {
		HitWindows.type = type;
	}
}