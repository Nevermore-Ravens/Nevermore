package nevermore.play;

#if !NEVERMORE_NO_MODCHARTS
import nevermore.modchart.ModchartManager;
import nevermore.play.Strumline;
#end
import flixel.graphics.frames.FlxFrame;
import flixel.FlxCamera;
import flixel.FlxSprite;

class NoteObject extends FlxSprite {
	public var lane:Int;
	/**
	 * Whether the coloring method will be based on luminostity or regular tinting.
	 */
	public var luminize:Bool = false;

	public var offsetX:Float;
	public var offsetY:Float;
	public var offsetZ:Float;

	// actually used for modchart rendering but maybe there'll be another purpose
	var _drawFrame:FlxFrame;

	function prepareMatrix(camera:FlxCamera) {
		_matrix.translate(-origin.x, -origin.y);
		_matrix.scale(scale.x, scale.y);

		if (bakedRotationAngle <= 0)
		{
			updateTrig();

			if (angle != 0)
				_matrix.rotateWithTrig(_cosAngle, _sinAngle);
		}

		getScreenPosition(_point, camera).subtractPoint(offset);
		_point.add(origin.x + offsetX, origin.y + offsetY);
		_matrix.translate(_point.x, _point.y);

		if (isPixelPerfectRender(camera))
		{
			_matrix.tx = Math.floor(_matrix.tx);
			_matrix.ty = Math.floor(_matrix.ty);
		}
		_matrix.translate(camera.scroll.x * scrollFactor.x, camera.scroll.y * scrollFactor.y);
	}

	override function drawComplex(camera:FlxCamera) {
		_frame.prepareMatrix(_matrix, FlxFrameAngle.ANGLE_0, checkFlipX(), checkFlipY());
		prepareMatrix(camera);
		camera.drawNote(_frame, _matrix, colorTransform, blend, antialiasing, luminize);
	}

	#if !NEVERMORE_NO_MODCHARTS
	function prepareModchartVertices(z:Float) {
		Note.modchartVertices[0].set(_matrix.transformX(0, 0), _matrix.transformY(0, 0), z);
		Note.modchartVertices[1].set(_matrix.transformX(_frame.frame.width, 0), _matrix.transformY(_frame.frame.width, 0), z);
		Note.modchartVertices[2].set(_matrix.transformX(0, _frame.frame.height), _matrix.transformY(0, _frame.frame.height), z);
		Note.modchartVertices[3].set(_matrix.transformX(_frame.frame.width, _frame.frame.height), _matrix.transformY(_frame.frame.width, _frame.frame.height), z);
	}

	function getOrientAngle(modchart:ModchartManager, pos:Vector3, scrollMult:Float, yPos:Float, distance:Float, unadjustedDistance:Float, player:Int, strumline:Strumline, type:ObjectType) {
		final orient:Float = modchart.config.orient;
		if (orient == 0)
			return 0.0;

		final orientOffset: Float = modchart.config.orientOffset;
		final cacheX:Float = pos.x;
		final cacheY:Float = pos.y;
		final cacheZ:Float = pos.z;
		modchart.scrollMult = scrollMult;
		pos.set(x + width * 0.5, yPos + height * 0.5, 0);
		modchart.adjustPos(this, pos, distance, unadjustedDistance, lane, player, strumline, RECEPTOR);

		// cachePoint is just diff
		Note.cachePoint.set(pos.x - cacheX, pos.y - cacheY);
		Note.cachePoint.rotateByDegrees(orientOffset);
		pos.set(cacheX, cacheY, cacheZ);

		return orient * (Math.atan2(Note.cachePoint.y, Note.cachePoint.x) - (Math.PI * 0.5));
	}
	#end
}