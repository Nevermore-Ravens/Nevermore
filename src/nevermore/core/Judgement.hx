package nevermore.core;

enum abstract JudgementType(String) from String to String {
	var STEPMANIA_5 = 'StepMania';
}

/**
A handler for the list of judgements you can get.  
Can also be used as an instanced object.
```haxe
var flawless:Judgement = Judgement.current[0];
var perfect:Judgement = Judgement.current[1];
var great:Judgement = Judgement.current[...];

trace(flawless.window);
trace(perfect.window);
```
*/
@:structInit
class Judgement {
	/**
	The list of available judgements your game can use/have.  
	To write to this, use `register()`.
	*/
	public static var list:Map<String, Array<Judgement>> = [
		'StepMania' => [
			{
				name: 'Flawless',
				window: 22.5,
				color: 0xFF29B4FF
			},
			{
				name: 'Perfect',
				window: 45,
				color: 0xFFFFEB22
			},
			{
				name: 'Great',
				window: 90,
				color: 0xFF60E049
			},
			{
				name: 'Good',
				window: 135,
				color: 0xFF66B6FF,
				breaksCombo: true
			},
			{
				name: 'Bad',
				window: 180,
				color: 0xFFEB00F7,
				breaksCombo: true
			}
		]
	];

	/**
	The current judgements being used.
	*/
	public static var current:Array<Judgement>;

	/**
	Registers a set list of judgements for Nevermore to use.
	@param name The name for this list.
	@param judges The list of judgements to use for this type.
	*/
	public static function register(name:String, judges:Array<Judgement>) {
		list.set(name, judges);
	}

	/**
	The tightest judgement available for the current list of judgements.  
	(in StepMania context, Flawless)
	*/
	public static var min(get, never):Judgement;

	static function get_min():Judgement return current[0];

	/**
	The most loose judgement for the current list of judgements.  
	(in StepMania context, Boo/Bad)
	*/
	public static var max(get, never):Judgement;
	static function get_max():Judgement return current[current.length - 1];

	/**
	The name for the current list of judgements.
	*/
	public static var type(default, set):String;
	static function set_type(v:String):String {
		if (!list.exists(v)) return type;

		current = list[v];
		resetWindows();
		return type = v;
	}

	/**
	Resets the judgement system, and automatically re-applies the hit windows.
	@param judges The default judgements to use.
	*/
	public static function reset(judges:String) {
		type = judges;
		resetWindows();
	}

	/**
	Resets the hit windows of this judge set back to normal,
	relative to what `HitWindows.type` currently is.
	*/
	public static function resetWindows() {
		for (i => judge in current) {
			if (i >= HitWindows.current.length) break;

			judge.window = HitWindows.current[i];
		}
	}

	/**
	Resets the amount of times the current set of judgements have been hit.
	*/
	public static function resetHits() {
		for (judge in current) judge.hits = 0;
	}

	/**
	Converts the deviation of a note into a judgement ID.
	@param deviation The distance between the note time and the current time of the clock.
	@return The corresponding ID of the nearest judgement.
	*/
	public static function getID(deviation:Float):Int {
		for (i => judge in current) {
			if (Math.abs(deviation) > judge.window) continue;
			return i;
		}

		return current.length - 1;
	}

	/**
	Converts the deviation of a note into a judgement.
	@param deviation The distance between the note time and the current time of the clock.
	@return The corresponding nearest judgement.
	*/
	public static function get(deviation:Float):Judgement {
		for (judge in current) {
			if (Math.abs(deviation) > judge.window) continue;
			return judge;
		}

		return max;
	}

	/**
	The name of this judgement instance.
	*/
	public var name:String = 'Unknown';

	/**
	Whether this judgement will break your combo.
	*/
	public var breaksCombo:Bool = false;

	/**
	How tight this judgement will be to obtain, in milliseconds.  
	(ex. Flawless = 22.5ms, Perfect = 45ms, Great = 90ms)
	*/
	public var window:Float = 0.0;

	/**
	How much this judgement will affect the player's health.
	*/
	public var health:Float = 0.0;

	/**
	The colour of this judgement's instance.
	*/
	public var color:Int = 0xFFFFFFFF;

	/**
	The amount of times this judgement has been hit.
	*/
	public var hits:Int = 0;
}