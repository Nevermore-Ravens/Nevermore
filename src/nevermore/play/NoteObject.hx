package nevermore.play;

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
}