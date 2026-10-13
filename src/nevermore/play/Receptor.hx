package nevermore.play;

import flixel.graphics.frames.FlxFrame;
#if !NEVERMORE_NO_MODCHARTS
import nevermore.modchart.ModchartManager;
#end
import nevermore.play.Note;

class Receptor extends NoteObject {
	public var isHolding:Bool = false;
	public var parent:Strumline;

	public var attachments:Array<NoteObject> = [];

	public function new(parent:Strumline, lane:Int) {
		super();
		this.parent = parent;
		this.lane = lane;

		animation.finishCallback = anim -> {
			if (isHolding) return;
			
			var waitForAnim = !parent.ai;

			if (waitForAnim) return;
			glow('standard');
		}
	}

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

			attach.drawComplex(camera);

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

		Note.modchartVertices[0].set(_matrix.transformX(0, 0), _matrix.transformY(0, 0), modchartPos.z);
		Note.modchartVertices[1].set(_matrix.transformX(_frame.frame.width, 0), _matrix.transformY(_frame.frame.width, 0), modchartPos.z);
		Note.modchartVertices[2].set(_matrix.transformX(0, _frame.frame.height), _matrix.transformY(0, _frame.frame.height), modchartPos.z);
		Note.modchartVertices[3].set(_matrix.transformX(_frame.frame.width, _frame.frame.height), _matrix.transformY(_frame.frame.width, _frame.frame.height), modchartPos.z);
		
		var orientAngle:Float = 0;
		final orient:Float = modchart.config.orient;
		if (orient != 0){
			final orientOffset: Float = modchart.config.orientOffset;
			final cacheX:Float = modchartPos.x;
			final cacheY:Float = modchartPos.y;
			final cacheZ:Float = modchartPos.z;
			final mult: Float = direction == DOWN ? -1 : 1;
			modchartPos.set(x + width * 0.5, y + (height * 0.5) + ((modchartDist + 2) * mult), 0);
			modchart.adjustPos(this, modchartPos, modchartDist + 2, 2, lane, player, parent, RECEPTOR);

			Note.cachePoint.set(modchartPos.x - cacheX, modchartPos.y - cacheY);
			Note.cachePoint.rotateByDegrees(orientOffset);

			final diffX:Float = Note.cachePoint.x;
			final diffY:Float = Note.cachePoint.y;
			orientAngle = orient * (Math.atan2(diffY, diffX) - (Math.PI / 2));

			for (i => vert in Note.modchartVertices){	
				vert.x -= modchartPos.x;
				vert.y -= modchartPos.y;
				vert.z -= modchartPos.z;
				vert.rotateRads(0, 0, orientAngle);
				vert.x += modchartPos.x;
				vert.y += modchartPos.y;
				vert.z += modchartPos.z;
			}
			modchartPos.set(cacheX, cacheY, cacheZ);
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

	public function drawAttachmentCrazy(attachment:NoteObject, modchart:ModchartManager, player:Int, orientAngle:Float) {
		modchartPos.z += attachment.offsetZ;

		final oldScaleX:Float = attachment.scale.x;
		final oldScaleY:Float = attachment.scale.y;

		attachment.x = modchartPos.x - attachment.width * 0.5;
		attachment.y = modchartPos.y - attachment.height * 0.5;
		final layer = modchartPos.z;

		scale.set(oldScaleX * modchartScaleX, oldScaleY * modchartScaleY);
		attachment._frame.prepareMatrix(attachment._matrix, ANGLE_0, attachment.checkFlipX(), attachment.checkFlipY());
		attachment.prepareMatrix(attachment.cameras[0]);
		attachment._matrix.translate(attachment.cameras[0].scroll.x * attachment.scrollFactor.x, attachment.cameras[0].scroll.y * attachment.scrollFactor.y);
		attachment.scale.set(oldScaleX, oldScaleY);

		Note.modchartVertices[0].set(_matrix.transformX(0, 0), _matrix.transformY(0, 0), modchartPos.z);
		Note.modchartVertices[1].set(_matrix.transformX(_frame.frame.width, 0), _matrix.transformY(_frame.frame.width, 0), modchartPos.z);
		Note.modchartVertices[2].set(_matrix.transformX(0, _frame.frame.height), _matrix.transformY(0, _frame.frame.height), modchartPos.z);
		Note.modchartVertices[3].set(_matrix.transformX(_frame.frame.width, _frame.frame.height), _matrix.transformY(_frame.frame.width, _frame.frame.height), modchartPos.z);
		
		var orientAngle:Float = 0;
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

		attachment._drawFrame = attachment._frame.copyTo(attachment._drawFrame);
		modchart.pushDraw(player, parent, cameras, scrollFactor, attachment._drawFrame, Note.modchartVertices, colorTransform, blend, antialiasing, luminize, stealth, layer, true);

		modchartPos.z -= attachment.offsetZ;
	}
	#end
}