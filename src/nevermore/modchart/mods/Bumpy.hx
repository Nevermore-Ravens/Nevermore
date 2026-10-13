package nevermore.modchart.mods;

class Bumpy extends BaseModifier {
	var bumpyX:ModifierValue = 0;
	var bumpyXOffset:ModifierValue = 0;
	var bumpyXPeriod:ModifierValue = 0;

	var bumpyY:ModifierValue = 0;
	var bumpyYOffset:ModifierValue = 0;
	var bumpyYPeriod:ModifierValue = 0;

	var bumpy:ModifierValue = 0;
	var bumpyOffset:ModifierValue = 0;
	var bumpyPeriod:ModifierValue = 0;

	public function new(parent:ModchartManager) {
		super(parent);
		priority = 0;
	}

	// https://github.com/riconuts/FNF-Troll-Engine/blob/main/source/funkin/modchart/modifiers/DrunkModifier.hx#L45
	inline function getBumpyVal(val:Float, offset:Float, period:Float, distance:Float, clip:Float) {
		var rads = (distance + (100.0 * offset)) / ((period * 24.0) + 24.0);
		return val * Util.sinClip(rads, clip) * 40.0;
	}

	override function modifiesPosition(strumline:Int):Bool {return true;}
	override function adjustPos(_, pos:Vector3, distance:Float, _, _, _, player:Int, _, _) {
		final clipVal:Float = Math.abs(1 - parent.config.sinClip);

		final valX = bumpyX;
		if (valX != 0.0)
			pos.x += getBumpyVal(valX, bumpyXOffset, bumpyXPeriod, distance, clipVal);

		final valY = bumpyY;
		if (valY != 0.0)
			pos.y += getBumpyVal(valY, bumpyYOffset, bumpyYPeriod, distance, clipVal);

		final val = bumpy;
		if (val != 0.0)
			pos.z += getBumpyVal(val, bumpyOffset, bumpyPeriod, distance, clipVal);
	}
}