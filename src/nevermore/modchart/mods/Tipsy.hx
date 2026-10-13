package nevermore.modchart.mods;

class Tipsy extends BaseModifier {
	var tipsyX:ModifierValue = 0;
	var tipsyXSpeed:ModifierValue = 0;
	var tipsyXSpacing:ModifierValue = 0;
	var tipsyXOffset:ModifierValue = 0;

	var tipsy:ModifierValue = 0;
	var tipsySpeed:ModifierValue = 0;
	var tipsySpacing:ModifierValue = 0;
	var tipsyOffset:ModifierValue = 0;

	var tipsyZ:ModifierValue = 0;
	var tipsyZSpeed:ModifierValue = 0;
	var tipsyZSpacing:ModifierValue = 0;
	var tipsyZOffset:ModifierValue = 0;

	public function new(parent:ModchartManager) {
		super(parent);
		priority = 0;
	}

	// https://github.com/riconuts/FNF-Troll-Engine/blob/main/source/funkin/modchart/modifiers/DrunkModifier.hx#L30
	inline function getTipsyVal(val:Float, field:Strumline, speed:Float, spacing:Float, offset:Float, lane:Int, time:Float, clip:Float) {
		final rads = time * ((speed * 1.2) + 1.2) + offset * 1.2 + lane * ((spacing * 1.8) + 1.8);
		return val * Util.cosClip(rads, clip) * field.constantSize * 0.4;
	}

	override function modifiesPosition(_):Bool {return true;}
	override function adjustPos(_, pos:Vector3, _, _, _, lane:Int, player:Int, field:Strumline, _) {
		final time = Conductor.time * 0.001;
		final clipVal:Float = Math.abs(1 - parent.config.cosClip);

		final valX = tipsyX;
		if (valX != 0.0)
			pos.x += getTipsyVal(valX, field, tipsyXSpeed, tipsyXSpacing, tipsyXOffset, lane, time, clipVal);

		final val = tipsy;
		if (val != 0.0)
			pos.y += getTipsyVal(val, field, tipsySpeed, tipsySpacing, tipsyOffset, lane, time, clipVal);

		final valZ = tipsyZ;
		if (valZ != 0.0)
			pos.z += getTipsyVal(valZ, field, tipsyZSpeed, tipsyZSpacing, tipsyZOffset, lane, time, clipVal);
	}
}