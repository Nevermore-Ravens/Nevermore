package nevermore.modchart.mods;

class Beat extends BaseModifier {
	var beat:ModifierValue = 0;
	var beatOffset:ModifierValue = 0;
	var beatPeriod:ModifierValue = 0;
	var beatMult:ModifierValue = 0;

	var beatY:ModifierValue = 0;
	var beatYOffset:ModifierValue = 0;
	var beatYPeriod:ModifierValue = 0;
	var beatYMult:ModifierValue = 0;

	var beatZ:ModifierValue = 0;
	var beatZOffset:ModifierValue = 0;
	var beatZPeriod:ModifierValue = 0;
	var beatZMult:ModifierValue = 0;

	public var beatTimes:Array<Array<Float>> = [];

	public function new(parent:ModchartManager) {
		super(parent);
		priority = 0;
	}

	// from https://github.com/riconuts/FNF-Troll-Engine/blob/main/source/funkin/modchart/modifiers/BeatModifier.hx#L19
	// however the math is simplified.
	final accelTime:Float = 0.2;
	final totalTime:Float = 0.5;
	function getBeatTime(inBeat:Float, offset:Float, mult:Float) {
		var beat:Float = (inBeat + accelTime + offset) * (mult + 1.0);
		if (beat < 0) return 0.0;

		final endMult:Float = beat % 2 >= 1 ? -1 : 1;
		beat %= 1.0;

		if (beat >= totalTime) return 0.0;

		var amt:Float = 0.0;
		if (beat <= accelTime) {
			amt = beat / accelTime;
			amt *= amt;
		} else {
			amt = (beat - accelTime) / (totalTime - accelTime);
			amt = 1 - amt * amt;
		}

		return 40.0 * amt * endMult;
	}

	override function prepare(player:Int, beat:Float) {
		while (beatTimes.length < player + 1)
			beatTimes.push([0, 0, 0]);

		beatTimes[player] = [
			getBeatTime(beat, beatOffset, beatMult),
			getBeatTime(beat, beatOffset, beatMult),
			getBeatTime(beat, beatZOffset, beatZMult)
		];
	}

	override function modifiesPosition(_):Bool {return true;}
	override function adjustPos(_, pos:Vector3, distance:Float, _, _, _, player:Int, _, _) {
		// use cos so we dont need to offset pi/2
		final clip:Float = Math.abs(1 - parent.config.cosClip);

		final xPeriod = ((beatPeriod * 30) + 30);
		pos.x += this.beat * beatTimes[player][0] * Util.cosClip(distance / xPeriod, clip);

		final yPeriod = ((beatYPeriod * 30) + 30);
		pos.y += beatY * beatTimes[player][1] * Util.cosClip(distance / yPeriod, clip);

		final zPeriod = ((beatZPeriod * 30) + 30);
		pos.z += beatZ * beatTimes[player][2] * Util.cosClip(distance / zPeriod, clip);
	}
}