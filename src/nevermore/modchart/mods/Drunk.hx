package nevermore.modchart.mods;

class Drunk extends BaseModifier {
	var drunk:ModifierValue = 0;
	var drunkSpeed:ModifierValue = 0;
	var drunkSpacing:ModifierValue = 0;
	var drunkPeriod:ModifierValue = 0;
	var drunkOffset:ModifierValue = 0;

	var drunkY:ModifierValue = 0;
	var drunkYSpeed:ModifierValue = 0;
	var drunkYSpacing:ModifierValue = 0;
	var drunkYPeriod:ModifierValue = 0;
	var drunkYOffset:ModifierValue = 0;

	var drunkZ:ModifierValue = 0;
	var drunkZSpeed:ModifierValue = 0;
	var drunkZSpacing:ModifierValue = 0;
	var drunkZPeriod:ModifierValue = 0;
	var drunkZOffset:ModifierValue = 0;

	public function new(parent:ModchartManager) {
		super(parent);
		priority = 0;
	}

	// https://github.com/riconuts/FNF-Troll-Engine/blob/main/source/funkin/modchart/modifiers/DrunkModifier.hx#L15
	inline function getDrunkVal(val:Float, field:Strumline, speed:Float, spacing:Float, period:Float, offset:Float, distance:Float, lane:Int, time:Float, clipVal:Float) {
		final rads = time * (1.0 + speed) + offset + lane * ((spacing * 0.2) + 0.2) + distance * ((period * 10.0) + 10.0) / FlxG.height;
		return val * Util.sinClip(rads, clipVal) * field.constantSize * 0.5;
	}

	override function modifiesPosition(player:Int):Bool {return true;}
	override function adjustPos(_, pos:Vector3, distance:Float, _, _, lane:Int, player:Int, field:Strumline, _) {
		final time = Conductor.time * 0.001;
		final clipVal:Float = Math.abs(1 - parent.config.sinClip);

		final val = drunk;
		if (val != 0.0)
			pos.x += getDrunkVal(val, field, drunkSpeed, drunkSpacing, drunkPeriod, drunkOffset, distance, lane, time, clipVal);

		final valY = drunkY;
		if (valY != 0.0)
			pos.y += getDrunkVal(valY, field, drunkYSpeed, drunkYSpacing, drunkYPeriod, drunkYOffset, distance, lane, time, clipVal);

		final valZ = drunkZ;
		if (valZ != 0.0)
			pos.z += getDrunkVal(valZ, field, drunkZSpeed, drunkZSpacing, drunkZPeriod, drunkZOffset, distance, lane, time, clipVal);
	}
}