package nevermore.core;

class Constants {
	/**
	The amount of milliseconds in a second.
	*/
	public static var MS_PER_SEC:Int = 1000;

	/**
	The amount of time that passes until the player has to regrab a roll, in seconds.
	*/
	public static var ROLL_REGRAB_WINDOW:Float = 0.25;

	/**
	The amount of time that passes until the player has to regrab a hold, in seconds.
	*/
	public static var HOLD_REGRAB_WINDOW(get, never):Float;
	static function get_HOLD_REGRAB_WINDOW():Float {
		return Judgement.max.window / MS_PER_SEC;
	}

	/**
	The amount of rows that are in a beat.
	*/
	public static var ROWS_PER_BEAT:Float = 48;
	
	/**
	Gets the length of a beat in milliseconds.
	*/
	public static function crotchet(tempo:Float):Float {
		return 60000 / tempo;
		// return (60 / tempo) * MS_PER_SEC
	}
}