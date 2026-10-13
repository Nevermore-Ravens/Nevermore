package nevermore.modchart.mods;

class SchmovinTipsy extends BaseModifier {
	var schmovinTipsyX:ModifierValue = 0;
	var schmovinTipsyXSpeed:ModifierValue = 0;
	var schmovinTipsyXOffset:ModifierValue = 0;

	var schmovinTipsy:ModifierValue = 0;
	var schmovinTipsySpeed:ModifierValue = 0;
	var schmovinTipsyOffset:ModifierValue = 0;

	var schmovinTipsyZ:ModifierValue = 0;
	var schmovinTipsyZSpeed:ModifierValue = 0;
	var schmovinTipsyZOffset:ModifierValue = 0;

	public function new(parent:ModchartManager) {
		super(parent);
		priority = 0;
	}

	inline function getTipsyVal(val:Float, field:Strumline, speed:Float, offset:Float, lane:Int, beat:Float, clipVal:Float) {
		return Util.sinClip((beat * speed) / 4 * Math.PI + lane + offset, clipVal) * (field.constantSize * 0.5) * val;
	}

	override function modifiesPosition(_):Bool {return true;}
	override function adjustPos(_, pos:Vector3, _, _, beat:Float, lane:Int, player:Int, field:Strumline, _) {
		final clipVal:Float = Math.abs(1 - parent.config.sinClip);

		final valX = schmovinTipsyX;
		if (valX != 0.0)
			pos.x += getTipsyVal(valX, field, schmovinTipsyXSpeed + 1, schmovinTipsyXOffset, lane, beat, clipVal);

		final val = schmovinTipsy;
		if (val != 0.0)
			pos.y += getTipsyVal(val, field, schmovinTipsySpeed + 1, schmovinTipsyOffset, lane, beat, clipVal);

		final valZ = schmovinTipsyZ;
		if (valZ != 0.0)
			pos.z += getTipsyVal(valZ, field, schmovinTipsyZSpeed + 1, schmovinTipsyZOffset, lane, beat, clipVal);
	}
}