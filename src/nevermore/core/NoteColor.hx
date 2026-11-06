package nevermore.core;

import nevermore.play.BaseNote;

enum abstract QuantType(String) from String to String {
	var STEPMANIA = 'StepMania';
	var STEPMANIA_39 = 'StepMania (3.9)';
	var ITG = 'In The Groove';
	var FFR = 'Flash Flash Revolution';
	var ETTERNA = 'Etterna';
	var CUSTOM = 'Custom';
}

enum abstract ColorType(String) from String to String {
	var CUSTOM = 'Custom';
}

/**
Contains customization for colouring of notes, by either lanes or snap/quantization.
*/
class NoteColor {
	public static final RED:Color = 0xFFFF2B32;
	public static final BLUE:Color = 0xFF0861FF;
	public static final PURPLE:Color = 0xFFC228FF;
	public static final YELLOW:Color = 0xFFFFE900;
	public static final MAGENTA:Color = 0xFFFF00CB;
	public static final PINK:Color = 0xFFFF91FF;
	public static final ORANGE:Color = 0xFFFF831E;
	public static final TEAL:Color = 0xFF00EDFF;
	public static final GREEN:Color = 0xFF3FFF3F;
	public static final GREEN_CYAN:Color = 0xFF2AFEB7;
	public static final WHITE:Color = 0xFFFFFFFF;
	public static final GRAY:Color = 0xFF878787;

	/**
	A list of quantization types that are able to be used.

	NOTE:

	These games don't necessarily *have* a set quantization list.  
	Quants depend on the skin, rather than the game having a hardcoded list (like in this class).  
	The quants you see here is dependent on the corresponding game's default noteskin.  
	For example:

	* StepMania - "Default"
	* FFR - "Default"
	* StepMania (3.9) - "Note" (3.9 *has* a default noteskin but it's not snapped, just randomly changing colours)
	* (Not)In The Groove - "Cel" / "Metal" (both use the same colours)
	* Etterna - "ByZero" Series
	* ...
	*/
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

		// looking for this if you want arrowvortex/quaver arrow colours
		'StepMania (3.9)' => [
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
			RED, 		// 4th
			BLUE, 		// 8th
			PURPLE, 	// 12th
			GREEN, 		// 16th
			GREEN_CYAN, // 20th
			PURPLE, 	// 24th
			YELLOW, 	// 32nd
			PURPLE, 	// 48th
			GREEN_CYAN, // 64th
			GREEN_CYAN, // 96th
			GREEN_CYAN  // 192nd
		],

		'Flash Flash Revolution' => [
			RED,    // 4th
			RED,    // 8th
			PURPLE, // 12th
			BLUE,   // 16th
			WHITE,  // 20th
			PURPLE, // 24th
			YELLOW, // 32nd
			PINK,   // 48th
			ORANGE, // 64th
			WHITE,  // 96th
			WHITE   // 192nd
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

	/**
	A list of custom lane colours that are able to be used.
	*/
	public static var list:Map<String, Array<Int>> = [
		'Custom' => [
			0xFFFFFFFF,
			0xFFFFFFFF,
			0xFFFFFFFF,
			0xFFFFFFFF
		]
	];

	/**
	Whether colouring will be based on what lane the note is in, or 
	what snap the note is in; relative to the note's time.
	*/
	public static var bySnap:Bool = false;

	/**
	The name of the current quantization list being used.
	*/
	static var quantType(default, set):QuantType;
	static function set_quantType(v:QuantType):QuantType {
		currentQuants = quantList[v];
		return quantType = v;
	}

	/**
	The name of the current lane colour list being used.
	*/
	static var type(default, set):ColorType;
	static function set_type(v:ColorType):ColorType {
		current = list[v];
		return type = v;
	}

	/**
	The list of the current quants being used.
	*/
	public static var currentQuants:Array<Int>;

	/**
	The list of the current lane colours being used.
	*/
	public static var current:Array<Int>;

	/**
	Resets the colours back to default.
	@param quants The default quantization colours.
	@param lanes The defaule lane colours.
	**/
	public static function reset(quants:String, lanes:String) {
		quantType = quants;
		type = lanes;
	}

	/**
	Returns the corresponding colour based on a given note.
	@param note The note to be checking.
	@return The colour to be applied. If `note.luminize` is false,
	it will return white instead.
	*/
	public static function get(note:BaseNote):Int {
		if (!note.luminize) return WHITE;

		if (bySnap) return currentQuants[note.data.snapID];
		return current[note.lane % current.length];
	}
}