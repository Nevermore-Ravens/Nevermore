package nevermore.core;

class Constants {
	public static var MS_PER_SEC:Int = 1000;
	public static var ROLL_REGRAB_WINDOW:Float = 0.25;
	public static var ROWS_PER_BEAT:Float = 48;

	public static var HOLD_REGRAB_WINDOW(get, never):Float;
	static function get_HOLD_REGRAB_WINDOW():Float {
		return Judgement.max.window / MS_PER_SEC;
	}
	
	public static function crotchet(tempo:Float):Float {
		return 60000 / tempo;
		// return (60 / tempo) * MS_PER_SEC
	}
}