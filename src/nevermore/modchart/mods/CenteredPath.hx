package nevermore.modchart.mods;

class CenteredPath extends BaseModifier {
	@:alias(movepath, centered2) var centeredPath:ModifierValue = 0;
	var centeredPathLANE:ModifierValue = 0;
	var centeredPathType:ModifierValue = 0;

	var transformPath:ModifierValue = 0;
	var transformPathLANE:ModifierValue = 0;

	public function new(parent:ModchartManager) {
		super(parent);
		priority = -1;
	}

	override function modifiesDistance(_):Bool {return true;}
	override function adjustDistance(_, distance:Float, _, _, _, _, field:Strumline, _):Float {
		var centeredLane:Float = centeredPath + centeredPathLANE;
		// adjust crotchet to the speed
		var adjustedCrotchet:Float = Conductor.crotchet * (field.pixelsPerMS * field.speed) / Conductor.clock.rate;
		var lerpedCenter:Float = FlxMath.lerp(field.constantSize, adjustedCrotchet, centeredPathType);
		
		final mainOff = lerpedCenter * centeredLane;
		return distance + mainOff + (transformPath + transformPathLANE);
	}
}