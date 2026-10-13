package nevermore.modchart.mods;

class Paths extends BaseModifier {
	var xMode:ModifierValue = 0; 
	var zigzag:ModifierValue = 0; 
	var zigzagOffset:ModifierValue = 0; 
	var zigzagPeriod:ModifierValue = 0; 
	var digital:ModifierValue = 0; 
	var digitalOffset:ModifierValue = 0; 
	var digitalPeriod:ModifierValue = 0; 
	var digitalSteps:ModifierValue = 0; 
	var cubicX:ModifierValue = 0; 
	var cubicXOffset:ModifierValue = 0; 
	var cubicY:ModifierValue = 0;
	var cubicYOffset:ModifierValue = 0;
	var cubicZ:ModifierValue = 0;
	var cubicZOffset:ModifierValue = 0;
	var parabolaX:ModifierValue = 0; 
	var parabolaXOffset:ModifierValue = 0; 
	var parabolaY:ModifierValue = 0;
	var parabolaYOffset:ModifierValue = 0;
	var parabolaZ:ModifierValue = 0;
	var parabolaZOffset:ModifierValue = 0;
	@:alias(attenuatex) var attenuate:ModifierValue = 0;
	@:alias(attenuatexoffset) var attenuateOffset:ModifierValue = 0;
	var attenuateY:ModifierValue = 0;
	var attenuateYOffset:ModifierValue = 0;
	var attenuateZ:ModifierValue = 0;
	var attenuateZOffset:ModifierValue = 0;
	var bounce:ModifierValue = 0;
	var bounceOffset:ModifierValue = 0;
	var bouncePeriod:ModifierValue = 0;
	var bounceZ:ModifierValue = 0;
	var bounceZOffset:ModifierValue = 0;
	var bounceZPeriod:ModifierValue = 0;
	var square:ModifierValue = 0;
	var squareOffset:ModifierValue = 0;
	var squarePeriod:ModifierValue = 0;
	var tornado:ModifierValue = 0;
	var tornadoOffset:ModifierValue = 0;
	var tornadoPeriod:ModifierValue = 0;
	var pathType:ModifierValue = 0; // TODO: maybe figure out a new name, but TL;DR similar to stealthtype where if its 1 then paths will use pos.y instead of distance
	// maybe this should be an aux mod in modmanager that every path mod that requires note's y pos follows? we should also add stealthtype lol

	inline function cos(rads:Float, clip:Float)
		return Util.sinClip(rads + Math.PI * 0.5, clip);

	inline function squareWave(angle:Float) {
		return (angle % (Math.PI * 2)) >= Math.PI ? -1.0 : 1.0;
	}

	inline function triangle(angle:Float):Float {
		var fAngle:Float = angle % (Math.PI * 2.0);
		if (fAngle < 0.0) fAngle += Math.PI * 2.0;
		
		var result:Float = fAngle / Math.PI;
		if (result < 0.5) {
			return 2.0 * result;
		}

		if (result < 1.5) {
			return -2.0 * result + 2.0;
		}

		return 2.0 * result - 4.0;
	}

	inline function bounceWave(val:Float, field:Strumline, offset:Float, period:Float, diff:Float, sinClip:Float) {
		if (period == -1) return 0.0;

		final rads = (diff + offset) / (90.0 + 90.0 * period);
		return val * field.constantSize * 0.5 * Math.abs(Util.sinClip(rads, sinClip));
	}

	inline function getDigitalAngle(field:Strumline, yOffset:Float, offset:Float, period:Float) {
		return Math.PI * (yOffset + (1 * offset)) / (field.constantSize + (period * field.constantSize));
	}

	public function new(parent:ModchartManager) {
		super(parent);
		priority = 20;
	}

	// TODO: dont hardcode this shit
	inline function getXOffset(field:Strumline, lane:Int):Float {
		return field.constantSize * (lane - (parent.laneCount - 1) * 0.5);
	}

	override function modifiesDistance(_) {return true;}
	override function adjustDistance(_, distance:Float, _, _, _, _, field:Strumline, _) {
		final cubicY:Float = cubicY;
		if (cubicY != 0)
			distance += cubicY * Math.pow((cubicYOffset + distance) / field.constantSize, 3);
		
		final parabolaY:Float = parabolaY;
		if (parabolaY != 0) {
			final factor:Float = (parabolaYOffset + distance) / field.constantSize;
			distance += parabolaY * factor * factor;
		}

		return distance;
	}

	override function modifiesPosition(_) {return true;}
	override function adjustPos(_, pos:Vector3, distance:Float, unadjustedDistance:Float, _, lane:Int, player:Int, field:Strumline, _) {
		// Gets the distance value based on if PATHS_USE_PATH_Y is enabled or not
		// When enabled, then paths will use pos.y to determine where in the path it is
		// When disabled, paths use distance.
		// Doing it in a function so paths that modify the Y are also taken into account here
		final sinClip:Float = Math.abs(1 - parent.config.sinClip);
		final cosClip:Float = Math.abs(1 - parent.config.cosClip);

		var usedDistance:Float = pathType == 1 ? distance : unadjustedDistance;

		pos.x += xMode * usedDistance * (player % 2 == 0 ? 1 : -1);
		final zigzag:Float = zigzag;
		if (zigzag != 0) {
			final offset:Float = zigzagOffset;
			final period:Float = zigzagPeriod;
			final result:Float = triangle((Math.PI * (1 / (period + 1)) * ((usedDistance + 100 * offset) / field.constantSize)));

			pos.x += (zigzag * (field.constantSize * 0.5)) * result;
		}

		final digital = digital;
		if (digital != 0) {
			final steps:Float = digitalSteps + 1;
			final period:Float = digitalPeriod;
			final offset:Float = digitalOffset;

			pos.x += (digital * (field.constantSize * 0.5)) * Math.round(steps * Util.sinClip(getDigitalAngle(field, usedDistance, offset, period), sinClip)) / steps;
		}

		final squareVal = square;
		if (squareVal != 0) {
			final rads: Float = (Math.PI * (usedDistance + squareOffset) / (field.constantSize * (1 + squarePeriod)));
			pos.x += squareVal * field.constantSize * 0.5 * squareWave(rads);
		}

		final bounceX = bounce;
		if (bounceX != 0)
			pos.x += bounceWave(bounceX, field, bounceOffset, bouncePeriod, usedDistance, sinClip);

		final bounceZ = bounceZ;
		if (bounceZ != 0)
			pos.z += bounceWave(bounceZ, field, bounceZOffset, bounceZPeriod, usedDistance, sinClip);

		final cubic: Float = cubicX;
		if (cubic != 0)
			pos.x += cubic * Math.pow((cubicXOffset + usedDistance) / field.constantSize, 3);

		final cubicZ: Float = cubicZ;
		if (cubicZ != 0)
			pos.z += cubicZ * Math.pow((cubicZOffset + usedDistance) / field.constantSize, 3);

		final parabola: Float = parabolaX;
		if (parabola != 0) {
			final factor:Float = (parabolaXOffset + usedDistance) / field.constantSize;
			pos.x += parabola * factor * factor;
		}

		final parabolaZ:Float = parabolaZ;
		if (parabolaZ != 0) {
			final factor:Float = (parabolaZOffset + usedDistance) / field.constantSize;
			pos.z += parabolaZ * factor * factor;
		}
		
		var xOffset:Float = getXOffset(field, lane);

		final attenuateX:Float = attenuate;
		if (attenuateX != 0) {
			final attenuateFactor:Float = (attenuateOffset + usedDistance) / field.constantSize;
			pos.x += attenuateX * attenuateFactor * attenuateFactor * (xOffset / field.constantSize);
		}

		final attenuateY:Float = attenuateY;
		if (attenuateY != 0) {
			final attenuateFactor:Float = (attenuateYOffset + usedDistance) / field.constantSize;
			pos.y += attenuateY * attenuateFactor * attenuateFactor * (xOffset / field.constantSize);
		}

		final attenuateZ:Float = attenuateZ;
		if (attenuateZ != 0) {
			final attenuateFactor:Float = (attenuateZOffset + usedDistance) / field.constantSize;
			pos.z += attenuateZ * attenuateFactor * attenuateFactor * (xOffset / field.constantSize);
		}

		final tornado: Float = tornado;
		if (tornado != 0) {
			// from schmovin!! (well i copy pasted this from troll)
			var columnPhaseShift = (lane * Math.PI / 3) + tornadoOffset;
			var phaseShift = (usedDistance / 135) * (1 + tornadoPeriod);
			var halfSize = field.constantSize * (parent.laneCount - 1) * 0.5;
			var returnReceptorToZeroOffsetX = (-cos(-columnPhaseShift, cosClip) + 1) * halfSize;
			var offsetX = (-cos(phaseShift - columnPhaseShift, cosClip) + 1) * halfSize - returnReceptorToZeroOffsetX;
			pos.x += offsetX * tornado;
		}
	}
}