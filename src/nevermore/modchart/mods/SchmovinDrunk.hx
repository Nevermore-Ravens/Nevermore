package nevermore.modchart.mods;

class SchmovinDrunk extends BaseModifier {
	var schmovinDrunk:ModifierValue = 0;
	var schmovinDrunkSpeed:ModifierValue = 0;
	var schmovinDrunkPeriod:ModifierValue = 0;
	var schmovinDrunkOffset:ModifierValue = 0;

	var schmovinDrunkY:ModifierValue = 0;
	var schmovinDrunkYSpeed:ModifierValue = 0;
	var schmovinDrunkYPeriod:ModifierValue = 0;
	var schmovinDrunkYOffset:ModifierValue = 0;

	var schmovinDrunkZ:ModifierValue = 0;
	var schmovinDrunkZSpeed:ModifierValue = 0;
	var schmovinDrunkZPeriod:ModifierValue = 0;
	var schmovinDrunkZOffset:ModifierValue = 0;

	public function new(parent:ModchartManager) {
		super(parent);
		priority = 0;
	}

	inline function getDrunkVal(val:Float, field:Strumline, speed:Float, offset:Float, period:Float, distance:Float, lane:Int, beat:Float, clipVal:Float) {
		var phaseShift = (lane * 0.5) + offset + (distance * period) / 222 * Math.PI;
		return Util.sinClip((beat * speed) / 4 * Math.PI + phaseShift, clipVal) * (field.constantSize * 0.5) * val;
	}

	override function modifiesPosition(_):Bool {return true;}
	override function adjustPos(_, pos:Vector3, distance:Float, _, beat:Float, lane:Int, player:Int, field:Strumline, _) {
		final clipVal:Float = Math.abs(1 - parent.config.sinClip);
		
		final val = schmovinDrunk;
		if (val != 0.0)
			pos.x += getDrunkVal(val, field, schmovinDrunkSpeed + 1, schmovinDrunkOffset, schmovinDrunkPeriod + 1, distance, lane, beat, clipVal);

		final valY = schmovinDrunkY;
		if (valY != 0.0)
			pos.y += getDrunkVal(valY, field, schmovinDrunkYSpeed + 1, schmovinDrunkYOffset, schmovinDrunkYPeriod + 1, distance, lane, beat, clipVal);

		final valZ = schmovinDrunkZ;
		if (valZ != 0.0)
			pos.z += getDrunkVal(valZ, field, schmovinDrunkZSpeed + 1, schmovinDrunkZOffset, schmovinDrunkZPeriod + 1, distance, lane, beat, clipVal);
	}
}