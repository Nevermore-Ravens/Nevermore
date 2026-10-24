package nevermore.play;

import flixel.graphics.frames.FlxFrame;
#if !NEVERMORE_NO_MODCHARTS
import nevermore.modchart.ModchartManager;
#end
import nevermore.play.Note;

/**
* An individual receptor for a strumline.
**/
class Receptor extends NoteObject {
	/**
	* Whether this receptor is currently being held.
	**/
	public var isHolding:Bool = false;

	/**
	* The connected strumline instance of this receptor.
	**/
	public var parent:Strumline;

	/**
	* For any additional attachments that can be added onto this receptor.
	**/
	public var attachments:Array<NoteObject> = [];

	public function new(parent:Strumline, lane:Int) {
		super();
		this.parent = parent;
		this.lane = lane;

		animation.finishCallback = anim -> {
			if (isHolding) return;

			if (!parent.ai) return;
			glow('standard');
		}
	}

	/**
	* Makes this receptor play a specific animation,
	* preferably when a related action is done.
	* @param name The animation name to play.
	**/
	public function glow(?name:String) {
		name ??= 'glow';

		if (name == 'standard') {
			color = 0xFFFFFFFF;
			luminize = false;
		}

		animation.play(name, true);
		centerOffsets();
		centerOrigin();
	}

	override function update(delta:Float) {
		updateAnimation(delta);
		for (attach in attachments) {
			if (attach.exists && attach.active)
				attach.update(delta);
		}
	}

	override function drawComplex(camera:Dynamic) {
		final firstCam = camera == cameras[0];

		_frame.prepareMatrix(_matrix, FlxFrameAngle.ANGLE_0, checkFlipX(), checkFlipY());
		prepareMatrix(camera);
		camera.drawNote(_frame, _matrix, colorTransform, blend, antialiasing, luminize);

		// basically, positioning with draw and drawDebug. (ive shouldve just made a group -v-')
 		for (attach in attachments) {
			if (attach.alpha == 0 || !attach.exists || !attach.visible)
				continue;

			if (firstCam) {
				attach.x = x + (width - attach.width) * 0.5;
				attach.y = y + (height - attach.height) * 0.5;
			}

			attach.checkEmptyFrame();

			if (attach._frame.type == FlxFrameType.EMPTY || !attach.isOnScreen(camera))
				continue;

			if (attach.dirty && firstCam) // rarely
				attach.calcFrame(attach.useFramePixels);

			final oldAlpha = attach.colorTransform.alphaMultiplier;
			attach.colorTransform.alphaMultiplier *= colorTransform.alphaMultiplier;
			attach.drawComplex(camera);
			attach.colorTransform.alphaMultiplier = oldAlpha;

			#if FLX_DEBUG
			flixel.FlxBasic.visibleCount++;

			if (FlxG.debugger.drawDebug && !attach.ignoreDrawDebug) {
				attach.drawDebugOnCamera(camera);

				if (attach.path != null && !attach.path.ignoreDrawDebug)
					attach.path.drawDebug(); // weirdly enough (at least the version we test on) they dont toss in the camera here
			}
			#end
		}
	}

	#if !NEVERMORE_NO_MODCHARTS
	public var modchartPos:Vector3 = new Vector3();
	public var modchartScaleX:Float = 1;
	public var modchartScaleY:Float = 1;
	public var modchartDist:Float = 0;
	public var oldScaleX:Float = 1;
	public var oldScaleY:Float = 1;
	public var scrollMult:Float = 1;
	public var stealth:Float = 0;
	public var stealthColor:Vector3 = new Vector3();

	/**
	*
	**/
	public function preDrawCrazy(modchart:ModchartManager, player:Int, direction:ScrollDirection) {
		modchart.curLane = lane;
		modchart.curField = player;

		oldScaleX = scale.x;
		oldScaleY = scale.y;
		final mult:Float = direction == DOWN ? -1 : 1;
		modchart.stealthColor.set(1.0, 1.0, 1.0);
		modchart.scrollMult = mult;

		modchartDist = modchart.adjustDistance(this, 0, lane, player, parent, RECEPTOR);

		modchartPos.set(x + width * 0.5, y + height * 0.5 + (modchartDist * mult), 0);
		scale.set(1, 1);

		modchart.adjustPos(this, modchartPos, modchartDist, 0, lane, player, parent, RECEPTOR);
		modchart.adjustScale(this, scale, modchartDist, lane, player, parent, RECEPTOR);
		stealth = modchart.getStealth(this, modchartDist, 0, modchartPos, lane, player, parent, RECEPTOR);

		modchartScaleX = scale.x;
		modchartScaleY = scale.y;
		modchartPos.z += offsetZ;

		scrollMult = modchart.scrollMult;
		stealthColor.copyFrom(modchart.stealthColor);
	}

	/**
	*
	**/
	public function drawCrazy(modchart:ModchartManager, player:Int, direction:ScrollDirection) {
		modchart.curLane = lane;
		modchart.curField = player;
		if (modchart.arrowPath != null)
			modchart.arrowPath.drawPath(this, player, direction, parent);

		final oldX = x;
		final oldY = y;
		modchart.stealthColor.copyFrom(stealthColor);
		modchart.scrollMult = scrollMult;

		x = modchartPos.x - width * 0.5;
		y = modchartPos.y - height * 0.5;
		scale.set(oldScaleX * modchartScaleX, oldScaleY * modchartScaleY);
		final layer = modchartPos.z;
		_frame.prepareMatrix(_matrix, ANGLE_0, checkFlipX(), checkFlipY());
		prepareMatrix(cameras[0]);
		_matrix.translate(cameras[0].scroll.x * scrollFactor.x, cameras[0].scroll.y * scrollFactor.y);

		x = oldX;
		y = oldY;
		scale.set(oldScaleX, oldScaleY);

		prepareModchartVertices(modchartPos.z);
		final mult: Float = direction == DOWN ? -1 : 1;
		final orientAngle:Float = getOrientAngle(
			modchart,
			modchartPos,
			mult,
			y + ((modchartDist + 2) * mult),
			modchartDist + 2,
			2,
			player,
			parent,
			RECEPTOR
		);

		if (orientAngle != 0){
			for (i => vert in Note.modchartVertices){	
				vert.x -= modchartPos.x;
				vert.y -= modchartPos.y;
				vert.z -= modchartPos.z;
				vert.rotateRads(0, 0, orientAngle);
				vert.x += modchartPos.x;
				vert.y += modchartPos.y;
				vert.z += modchartPos.z;
			}
		}

		for (vert in Note.modchartVertices) {
			modchart.adjustVertex(this, vert, modchartPos, modchartDist, 0, lane, player, parent, RECEPTOR);
			vert.project();
		}

		_drawFrame = _frame.copyTo(_drawFrame);
		modchart.pushDraw(player, parent, cameras, scrollFactor, _drawFrame, Note.modchartVertices, colorTransform, blend, antialiasing, luminize, stealth, layer, true);

		modchartPos.z -= offsetZ;
		for (attach in attachments) {
			if (attach.exists && attach.visible)
				drawAttachmentCrazy(attach, modchart, player, orientAngle);
		}
	}

	/**
	*
	**/
	public function drawAttachmentCrazy(attachment:NoteObject, modchart:ModchartManager, player:Int, orientAngle:Float) {
		modchartPos.z += attachment.offsetZ;

		final oldScaleX:Float = attachment.scale.x;
		final oldScaleY:Float = attachment.scale.y;

		attachment.x = modchartPos.x - attachment.width * 0.5;
		attachment.y = modchartPos.y - attachment.height * 0.5;
		final layer = modchartPos.z;

		attachment.scale.set(oldScaleX * modchartScaleX, oldScaleY * modchartScaleY);
		attachment._frame.prepareMatrix(attachment._matrix, ANGLE_0, attachment.checkFlipX(), attachment.checkFlipY());
		attachment.prepareMatrix(attachment.cameras[0]);
		attachment._matrix.translate(attachment.cameras[0].scroll.x * attachment.scrollFactor.x, attachment.cameras[0].scroll.y * attachment.scrollFactor.y);
		attachment.scale.set(oldScaleX, oldScaleY);

		attachment.prepareModchartVertices(modchartPos.z);
		
		if (orientAngle != 0){
			for (i => vert in Note.modchartVertices){	
				vert.x -= modchartPos.x;
				vert.y -= modchartPos.y;
				vert.z -= modchartPos.z;
				vert.rotateRads(0, 0, orientAngle);
				vert.x += modchartPos.x;
				vert.y += modchartPos.y;
				vert.z += modchartPos.z;
			}
		}

		for (vert in Note.modchartVertices) {
			modchart.adjustVertex(this, vert, modchartPos, modchartDist, 0, lane, player, parent, RECEPTOR);
			vert.project();
		}

		final oldAlpha = attachment.colorTransform.alphaMultiplier;
		attachment.colorTransform.alphaMultiplier *= colorTransform.alphaMultiplier;
		attachment._drawFrame = attachment._frame.copyTo(attachment._drawFrame);
		modchart.pushDraw(player, parent, attachment.cameras, attachment.scrollFactor, attachment._drawFrame, Note.modchartVertices, attachment.colorTransform, attachment.blend, attachment.antialiasing, attachment.luminize, stealth, layer, true);
		attachment.colorTransform.alphaMultiplier = oldAlpha;

		modchartPos.z -= attachment.offsetZ;
	}
	#end
}