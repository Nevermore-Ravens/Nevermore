package nevermore.core;

class Constants {
	public static var MS_PER_SEC:Int = 1000;

	public static var holdRegrabWindow(get, never):Float;
	static function get_holdRegrabWindow():Float {
		return Judgement.max.window / MS_PER_SEC;
	}

	public static var rollRegrabWindow:Float = 0.25;

	public static var rowsPerBeat:Float = 48;

	public static function crotchet(tempo:Float):Float {
		return 60000 / tempo;
		// return (60 / tempo) * MS_PER_SEC
	}
}