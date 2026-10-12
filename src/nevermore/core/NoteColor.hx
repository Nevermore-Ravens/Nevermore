package nevermore.core;

import nevermore.play.BaseNote;

enum abstract QuantType(String) from String to String {
	var STEPMANIA = 'StepMania';
	var ITG = 'In The Groove';
	var FFR = 'Flash Flash Revolution';
	var ETTERNA = 'Etterna';
	var ARROWVORTEX = 'ArrowVortex';
	var CUSTOM = 'Custom';
}

enum abstract ColorType(String) from String to String {
	var CUSTOM = 'Custom';
}

class NoteColor {
	public static final RED:FlxColor = 0xFFFF2B32;
	public static final BLUE:FlxColor = 0xFF0861FF;
	public static final PURPLE:FlxColor = 0xFFC228FF;
	public static final YELLOW:FlxColor = 0xFFFFE900;
	public static final MAGENTA:FlxColor = 0xFFFF00CB;
	public static final PINK:FlxColor = 0xFFFF91FF;
	public static final ORANGE:FlxColor = 0xFFFF831E;
	public static final TEAL:FlxColor = 0xFF00EDFF;
	public static final GREEN:FlxColor = 0xFF3FFF3F;
	public static final LIME:FlxColor = 0xFFA5E123;
	public static final WHITE:FlxColor = 0xFFFFFFFF;
	public static final GRAY:FlxColor = 0xFF878787;

	// these games don't necessarily *have* a set quant list
	// as quants depend on the skin, rather than the game setting them (like in this scenario)
	// the quant list you see here is dependent on the game's default noteskin
	// sm being "default" (no shit)
	// itg being metal/cel
	// etterna being the byzero series
	// etc
	public static var quantList:Map<String, Array<Int>> = [
		'StepMania' => [
			RED,     // 4th
			BLUE,    // 8th
			GREEN,   // 12th
			YELLOW,  // 16th
			GRAY,    // 20th
			PURPLE,  // 24th
			TEAL,    // 32nd
			MAGENTA, // 48th
			GRAY,    // 64th
			GRAY,    // 96th
			GRAY     // 192nd
		],

		'Etterna' => [
			RED,     // 4th
			BLUE,    // 8th
			GREEN,   // 12th
			YELLOW,  // 16th
			GRAY,    // 20th
			MAGENTA, // 24th
			ORANGE,  // 32nd
			TEAL,    // 48th
			GRAY,    // 64th
			GRAY,    // 96th
			GRAY     // 192nd
		],

		'In The Groove' => [
			RED,    // 4th
			BLUE,   // 8th
			PURPLE, // 12th
			GREEN,  // 16th
			TEAL,   // 20th 
			TEAL,   // 24th
			ORANGE, // 32nd
			TEAL,   // 48th
			TEAL,   // 64th
			TEAL,   // 96th
			TEAL    // 192nd
		],

		// these probably aren't accurate ????
		// i tried the best i could
		'Flash Flash Revolution' => [
			RED,
			RED,
			PURPLE,
			BLUE,
			WHITE,
			PINK,
			YELLOW,
			ORANGE,
			GREEN,
			WHITE,
			WHITE
		],

		'ArrowVortex' => [
			RED,     // 4th
			BLUE,    // 8th
			PURPLE,  // 12th
			YELLOW,  // 16th
			GRAY,    // 20th 
			PINK,    // 24th
			ORANGE,  // 32nd
			TEAL,    // 48th
			GREEN,   // 64th
			GRAY,    // 96th
			GRAY     // 192nd
		],

		'Custom' => [
			0xFFFFFFFF, // 4th
			0xFFFFFFFF, // 8th
			0xFFFFFFFF, // 12th
			0xFFFFFFFF, // 16th
			0xFFFFFFFF, // 20th 
			0xFFFFFFFF, // 24th
			0xFFFFFFFF, // 32nd
			0xFFFFFFFF, // 48th
			0xFFFFFFFF, // 64th
			0xFFFFFFFF, // 96th
			0xFFFFFFFF  // 192nd
		]
	];

	public static var list:Map<String, Array<Int>> = [
		'Custom' => [
			0xFFFFFFFF,
			0xFFFFFFFF,
			0xFFFFFFFF,
			0xFFFFFFFF
		]
	];

	public static var bySnap:Bool = true;
	static var quantType(default, set):QuantType;
	static function set_quantType(v:QuantType):QuantType {
		currentQuants = quantList[v];
		return quantType = v;
	}

	static var type(default, set):ColorType;
	static function set_type(v:ColorType):ColorType {
		current = list[v];
		return type = v;
	}

	// colouring based on the note's snap timing
	public static var currentQuants:Array<Int>;

	// colouring based on what lane the note is in
	public static var current:Array<Int>;

	public static function reset() {
		quantType = STEPMANIA;
		type = CUSTOM;
	}

	public static function get(note:BaseNote):Int {
		if (!note.luminize) return WHITE;

		if (bySnap) return currentQuants[note.data.snapID];
		return current[note.lane % (current.length - 1)];
	}
}