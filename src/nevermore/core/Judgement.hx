package nevermore.core;

/**
* A handler for the list of judgements you can get.
* Can also be used as an instanced object.
* ```hx
* var marvelous:Judgement = Judgement.current[0];
* var perfect:Judgement = Judgement.current[1];
* var great:Judgement = Judgement.current[...];

* trace(marvelous.window);
* trace(perfect.window);
* ```
**/
@:structInit
class Judgement {
	/**
	* The list of available judgements your game can use/have.
	* To write to this, use `register()`.
	**/
	public static var list:Map<String, Array<Judgement>> = [];

	/**
	* The current judgements being used.
	**/
	public static var current:Array<Judgement>;

	/**
	* Registers a set list of judgements for Nevermore to use.
	* @param name The name for this list.
	* @param judges The list of judgements to use for this type.
	**/
	public static function register(name:String, judges:Array<Judgement>) {
		list.set(name, judges);
	}

	/**
	* Resets the amount of times the current set of judgements have been hit.
	**/
	public static function resetHits() {
		for (judge in current) judge.hits = 0;
	}

	/**
	* The tightest judgement available for the current list of judgements.
	* (in StepMania context, Marvelous)
	**/
	public static var min(get, never):Judgement;
	static function get_min():Judgement return current[0];

	/**
	* The most loose judgement for the current list of judgements.
	* (in StepMania context, Boo/Bad)
	**/
	public static var max(get, never):Judgement;
	static function get_max():Judgement return current[current.length - 1];

	/**
	* The name for the current list of judgements.
	**/
	public static var type(default, set):String;
	static function set_type(v:String):String {
		if (!list.exists(v)) return type;

		current = list[v];
		return type = v;
	}

	/**
	* Initializes the judgement and hit windows system.
	**/
	public static function init() {
		HitWindows.init();

		register('Default', [
			{
				name: 'Fantastic',
				window: HitWindows.current[0]
			},
			{
				name: 'Perfect',
				window: HitWindows.current[1]
			},
			{
				name: 'Great',
				window: HitWindows.current[2]
			},
			{
				name: 'Good',
				window: HitWindows.current[3]
			},
			{
				name: 'Bad',
				breaksCombo: true,
				window: HitWindows.current[4]
			}
		]);
		type = 'Default';
	}

	/**
	* Converts the deviation of a note into a judgement ID.
	* @param deviation The distance between the note time and the current time of the clock.
	* @return The corresponding ID of the nearest judgement.
	**/
	public static function getID(deviation:Float):Int {
		for (i => judge in current) {
			if (Math.abs(deviation) > judge.window) continue;
			return i;
		}

		return current.length - 1;
	}

	/**
	* Converts the deviation of a note into a judgement.
	* @param deviation The distance between the note time and the current time of the clock.
	* @return The corresponding nearest judgement.
	**/
	public static function get(deviation:Float):Judgement {
		for (judge in current) {
			if (Math.abs(deviation) > judge.window) continue;
			return judge;
		}

		return max;
	}

	/**
	* The name of this judgement instance.
	**/
	public var name:String = 'Unknown';

	/**
	* Whether this judgement will break your combo.
	**/
	public var breaksCombo:Bool = false;

	/**
	* How tight this judgement will be to obtain, in milliseconds.
	* (ex. Marvelous = 22.5ms, Perfect = 45ms, Great = 90ms)
	**/
	public var window:Float = 0.0;

	/**
	* How much this judgement will affect the player's health.
	**/
	public var health:Float = 0.0;

	/**
	* The colour of this judgement's instance.
	**/
	public var color:Int = 0xFFFFFFFF;

	/**
	* The amount of times this judgement has been hit.
	**/
	public var hits:Int = 0;
}