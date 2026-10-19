package nevermore.play;

import flixel.FlxCamera;
import flixel.animation.FlxAnimation;
import flixel.graphics.frames.FlxFrame;
import nevermore.core.timing.BaseClock;
#if !NEVERMORE_NO_MODCHARTS
import nevermore.modchart.ModchartManager;
#end

// TODO:
// refer to top of Note.hx
// especially this class
// because rolls still have to be added
class Sustain extends Note {
	public static var vertices:Array<Float> = [0, 0, 0, 0, 0, 0, 0, 0];
	public var forceHeightRecalc:Bool = false;
	public var isRoll:Bool = false;

	// stupid shit to make texture setting not break this
	override function updateHitbox() {}
	override function resetHelpers():Void {
		resetFrameSize();
		_flashRect2.x = 0;
		_flashRect2.y = 0;

		if (graphic != null) {
			_flashRect2.width = graphic.width;
			_flashRect2.height = graphic.height;
		}
	}

	override function set_type(v:String):String {
		type = v;
		behavior = NoteBehavior.get(type);
		behavior.setup(this);
		behavior.applySkin(this, SUSTAIN);

		isRoll = type.toLowerCase() == 'roll';

		lastScaleY = -1;
		lastSustainScale = -1;

		holdAnim = animation.getByName("piece");
		tailAnim = animation.getByName("tail");
		holdHeight = holdAnim == null ? getBlankFrame().frame.height : frames.frames[holdAnim.frames[0]].frame.height;
		tailHeight = tailAnim == null ? getBlankFrame().frame.height : frames.frames[tailAnim.frames[0]].frame.height;
		return v;
	}

	public var wasHit:Bool;
	public var regrabTimer:Float;
	public var regrabAlpha:Float;
	public var untilTick:Float;

	public var visualEnd:Float;
	override function setup(strumline:Strumline, data:NoteData):Note {
		wasHit = false;
		regrabTimer = Judgement.max.window / 1000;
		regrabAlpha = 0.7;
		untilTick = 0;

		super.setup(strumline, data);

		flipY = strumline.direction == DOWN;
		timeOffset = 0;
		visualEnd = data.visualEnd;

		return this;
	}

	public var timeOffset:Float;
	override function move(clock:BaseClock) {
		alpha = receptor.alpha;
		visible = strumline.visible; //receptor.visible;   dude what the fuck

		var deviation:Float = ((visualTime - clock.visualTime) + timeOffset) + Nevermore.settings.visualOffset;
		var adjustedSpeed:Float = (strumline.speed * strumline.pixelsPerMS);

		distance = deviation * (adjustedSpeed / clock.rate);

		this.x = switch strumline.direction {
			default: receptor.x + receptor.width * 0.5;
		}

		var center:Float = receptor.y + receptor.height * 0.5;
		this.y = switch strumline.direction {
			case UP: center + distance;
			case DOWN: center + (distance * -1);
			default: center;
		}
	}

	var lastScaleY:Float = -1;
	var lastSustainScale:Float = -1;
	public function calcHeight(holdScale:Float) {
		if (forceHeightRecalc || scale.y != lastScaleY || holdScale != lastSustainScale) {
			forceHeightRecalc = false;
			lastScaleY = scale.y;
			lastSustainScale = holdScale;

			var length:Float = visualEnd > 0 ? (visualEnd - data.visualTime) : length;
			height = (length - timeOffset) * (holdScale * strumline.pixelsPerMS);
		}
	}

	override function set_height(value:Float):Float {
		if (height == value) return height;

		final divisionsFloat:Float = ((Math.abs(value) - tailHeight * scale.y) / (holdHeight * scale.y)) / Nevermore.settings.holdGrain;
		sustainDivisions = Math.ceil(divisionsFloat);
		sustainTopY = holdHeight * (sustainDivisions - divisionsFloat);
		return height = value;
	}

	// drawing bullshit
	// you can ignore this
	var blankFrame:FlxFrame;
	var sustainDivisions:Int = 0;
	var sustainTopY:Float = 0;
	var holdFrame:FlxFrame;
	var holdAnim:FlxAnimation;
	var holdHeight:Float = 0;
	var tailFrame:FlxFrame;
	var tailAnim:FlxAnimation;
	var tailHeight:Float = 0;
	override function draw() {
		if (height == 0 || !visible || alpha == 0 || regrabAlpha <= 0)
			return;

		updateFrames(clock.time);

		// super.draw();
		for (camera in cameras) {
			if (!camera.visible || !camera.exists)
				continue;

			drawComplex(camera);

			#if FLX_DEBUG
			flixel.FlxBasic.visibleCount++;
			#end
		}

		#if FLX_DEBUG
		if (FlxG.debugger.drawDebug)
			drawDebug();
		#end
	}
	
	// NOTE:
	// this method of drawing sustains relies on FlxAnimation.frame
	// which is directly from the atlas itself
	//
	// if your noteksin is using sparrow atlas and your pieces/tail are rotated
	// flixel doesn't fix that via code, it just parses it as is
	// meaning drawing the flxframe this way will draw it as it is shown in the sheet
	//
	// tldr if your sustain frames are rotated you're fucked
	override function drawComplex(camera:FlxCamera) {
		final camX = camera.scroll.x * scrollFactor.x;

		final yFlip:Bool = flipY;
		if (height < 0)
			flipY = !flipY;
		
		final yMult = flipY ? -1 : 1;
		var curY = offsetY * yMult - camera.scroll.y * scrollFactor.y;

		// drawing each individual piece
		var holdWidth = (holdFrame.frame.width * scale.x * 0.5);
		vertices[0] = vertices[4] = x + offsetX - camX - holdWidth;
		vertices[2] = vertices[6] = x + offsetX - camX + holdWidth;

		final backupHoldY = holdFrame.frame.y;
		final backupHoldHeight = holdFrame.frame.height;

		// divisions = how many pieces will be drawn
		for (i in 0...sustainDivisions) {
			vertices[1] = vertices[3] = y + curY;
			
			holdFrame.frame.y = (i == 0) ? backupHoldY + sustainTopY : backupHoldY;
			holdFrame.frame.height = backupHoldHeight - (holdFrame.frame.y - backupHoldY);
			curY += holdFrame.frame.height * scale.y * yMult * Nevermore.settings.holdGrain;

			vertices[5] = vertices[7] = y + curY;

			// only renders the piece if the piece is within the viewport
			if (Math.min(vertices[1], vertices[5]) <= camera.viewMarginBottom && 
				Math.max(vertices[1], vertices[5]) >= camera.viewMarginTop) {
				camera.drawNoteVertices(holdFrame, vertices, colorTransform, blend, antialiasing, luminize, 0, colorTransform.alphaMultiplier * regrabAlpha);
			}
		}

		holdFrame.frame.y = backupHoldY;
		holdFrame.frame.height = backupHoldHeight;

		// drawing the tail piece
		final backupTailY = tailFrame.frame.y;
		final backupTailHeight = tailFrame.frame.height;
		tailFrame.frame.height = Math.min(height, backupTailHeight);
		tailFrame.frame.y = backupTailY + (backupTailHeight - tailFrame.frame.height);

		vertices[1] = vertices[3] = y + curY;
		vertices[5] = vertices[7] = y + curY + (tailFrame.frame.height * scale.y * yMult);

		// only renders the tail if the piece is within the viewport
		if (Math.min(vertices[1], vertices[5]) <= camera.viewMarginBottom && 
			Math.max(vertices[1], vertices[5]) >= camera.viewMarginTop) {
			camera.drawNoteVertices(tailFrame, vertices, colorTransform, blend, antialiasing, luminize, 0, colorTransform.alphaMultiplier * regrabAlpha);
		}

		tailFrame.frame.y = backupTailY;
		tailFrame.frame.height = backupTailHeight;
	}

	function getBlankFrame() {
		if (blankFrame == null)
			blankFrame = FlxG.bitmap.add("flixel/images/logo/default.png").imageFrame.frame;
		return blankFrame;
	}
	function updateFrames(time:Float) {
		inline function getSustainFrame(anim:FlxAnimation):Int {
			var frameIndex:Float = Math.abs(time / 1000 * anim.frameRate) % anim.frames.length;
			return anim.frames[Math.floor(frameIndex)];
		}

		holdFrame = holdAnim == null ? getBlankFrame() : frames.frames[getSustainFrame(holdAnim)];
		tailFrame = tailAnim == null ? getBlankFrame() : frames.frames[getSustainFrame(tailAnim)];
	}

	#if !NEVERMORE_NO_MODCHARTS
	// im so sorry
	var modchartPosLow:Vector3 = new Vector3();
	static var curStealthColor:Vector3 = new Vector3();
	static var nextStealthColor:Vector3 = new Vector3();
	static var nextScale:FlxPoint = FlxPoint.get();
	override function drawCrazy(modchart:ModchartManager, direction:ScrollDirection) {
		if (height == 0 || alpha <= 0 || regrabAlpha <= 0)
			return;

		final ogAlpha = colorTransform.alphaMultiplier;
		colorTransform.alphaMultiplier *= regrabAlpha;
		if (height < 0) {
			direction = Util.swapDirection(direction);
		}
		
		modchart.curLane = lane;
		modchart.curField = player;

		final yMult = direction == DOWN ? -1 : 1;
		final oldScaleX = scale.x;
		final oldScaleY = scale.y;
		final spiral:Bool = modchart.config.spiralHolds == 1;
		final sexuality:Float = modchart.config.straightHolds - modchart.config.gayHolds;
		final superstraight:Float = modchart.config.extraStraightHolds;
		var layer:Float = 0;
		var angleUp:Float = 0;
		var angleDown:Float = 0;

		var curDist = distance * yMult;
		var curY = offsetY;

		updateFrames(clock.time);
		
		var newDist:Float = modchart.adjustDistance(this, curDist, lane, player, strumline, SUSTAIN);
		final rawY:Float = (y - distance);
		final newY:Float = rawY + (newDist * yMult);
		modchartPos.set(x, newY, 0);
		modchart.scrollMult = yMult;
		modchart.adjustPos(this, modchartPos, newDist, curDist, lane, player, strumline, SUSTAIN);
		modchart.adjustScale(this, scale, newDist, lane, player, strumline, SUSTAIN);

		final baseX:Float = modchartPos.x;
		final baseZ:Float = modchartPos.z;
		modchartPos.set(
			FlxMath.lerp(modchartPos.x, x, superstraight),
			FlxMath.lerp(modchartPos.y, y, superstraight),
			FlxMath.lerp(modchartPos.z, 0, superstraight)
		);

		final backupHoldY = holdFrame.frame.y;
		final backupHoldHeight = holdFrame.frame.height;
		final backupTailY = tailFrame.frame.y;
		final backupTailHeight = tailFrame.frame.height;
		var rects = sustainDivisions + 1;
		inline function getNextPos() {
			--rects;
			modchart.stealthColor.set(1.0, 1.0, 1.0);
			stealth = modchart.getStealth(this, newDist, curDist, modchartPos, lane, player, strumline, SUSTAIN);
			nextStealthColor.copyFrom(modchart.stealthColor);

			final height:Float = (rects == 0) ? Math.min(Math.abs(height), backupTailHeight) : ((rects == sustainDivisions) ? backupHoldHeight - sustainTopY : backupHoldHeight) * Nevermore.settings.holdGrain;
			curY += height * oldScaleY * yMult;
			curDist = (distance + curY) * yMult;

			final newDist: Float = modchart.adjustDistance(this, curDist, lane, player, strumline, SUSTAIN);
			final newY: Float = rawY + (newDist * yMult);

			modchartPosLow.set(x, newY, 0);
			nextScale.set(oldScaleX, oldScaleY);
			modchart.scrollMult = yMult;
			modchart.adjustPos(this, modchartPosLow, newDist, curDist, lane, player, strumline, SUSTAIN);
			modchart.adjustScale(this, nextScale, curDist, lane, player, strumline, SUSTAIN);
			
			modchartPosLow.set(
				FlxMath.lerp(modchartPosLow.x, baseX, sexuality),
				FlxMath.lerp(modchartPosLow.y, newY, sexuality),
				FlxMath.lerp(modchartPosLow.z, baseZ, sexuality),
			);

			// first one was for straightholds/gayholds, this one is for extrastraightholds.
			modchartPosLow.set(
				FlxMath.lerp(modchartPosLow.x, x, superstraight),
				FlxMath.lerp(modchartPosLow.y, rawY + (curDist * yMult), superstraight),
				FlxMath.lerp(modchartPosLow.z, 0, superstraight)
			);
			
			if (spiral) {
				angleDown = Math.atan2(modchartPosLow.y - modchartPos.y, modchartPosLow.x - modchartPos.x);
				angleUp += Math.abs(angleDown - angleUp) > 180 ? Math.PI * 2 : 0;
			}

			return modchartPosLow.z;
		}
		layer = getNextPos();
		final halfHoldWidth = holdFrame.frame.width * scale.x * 0.5;
		final offsetX = spiral ? halfHoldWidth * Math.sin(angleDown) : halfHoldWidth;
		final offsetY = spiral ? halfHoldWidth * Math.cos(angleDown) : 0;

		Note.modchartVertices[0].set(
			modchartPos.x - offsetX + this.offsetX,
			modchartPos.y + offsetY + this.offsetY,
			modchartPos.z + this.offsetZ
		);
		modchart.adjustVertex(this, Note.modchartVertices[0], modchartPos, newDist, curDist, lane, player, strumline, SUSTAIN);
		Note.modchartVertices[0].project();
		Note.modchartVertices[1].set(
			modchartPos.x + offsetX + this.offsetX,
			modchartPos.y - offsetY + this.offsetY,
			modchartPos.z + this.offsetZ
		);
		modchart.adjustVertex(this, Note.modchartVertices[1], modchartPos, newDist, curDist, lane, player, strumline, SUSTAIN);
		Note.modchartVertices[1].project();

		angleUp = angleDown;
		scale.copyFrom(nextScale);
		modchartPos.copyFrom(modchartPosLow);

		for (i in 0...sustainDivisions) {
			holdFrame.frame.y = (i == 0) ? backupHoldY + sustainTopY : backupHoldY;
			holdFrame.frame.height = backupHoldHeight - (holdFrame.frame.y - backupHoldY);

			curStealthColor.copyFrom(modchart.stealthColor);
			final nextLayer = getNextPos();
			final halfHoldWidth = holdFrame.frame.width * scale.x * 0.5;
			final offsetX = spiral ? halfHoldWidth * Math.sin((angleDown + angleUp) * 0.5) : halfHoldWidth;
			final offsetY = spiral ? halfHoldWidth * Math.cos((angleDown + angleUp) * 0.5) : 0;

			Note.modchartVertices[2].set(
				modchartPos.x - offsetX + this.offsetX,
				modchartPos.y + offsetY + this.offsetY,
				modchartPos.z + this.offsetZ
			);
			modchart.adjustVertex(this, Note.modchartVertices[2], modchartPos, newDist, curDist, lane, player, strumline, SUSTAIN);
			Note.modchartVertices[2].project();
			Note.modchartVertices[3].set(
				modchartPos.x + offsetX + this.offsetX,
				modchartPos.y - offsetY + this.offsetY,
				modchartPos.z + this.offsetZ
			);
			modchart.adjustVertex(this, Note.modchartVertices[3], modchartPos, newDist, curDist, lane, player, strumline, SUSTAIN);
			Note.modchartVertices[3].project();

			modchart.stealthColor.copyFrom(curStealthColor);
			modchart.pushDraw(player, strumline, cameras, scrollFactor, holdFrame, Note.modchartVertices, colorTransform, blend, antialiasing, luminize, stealth, layer);
			modchart.stealthColor.copyFrom(nextStealthColor);

			Note.modchartVertices[0].copyFrom(Note.modchartVertices[2]);
			Note.modchartVertices[1].copyFrom(Note.modchartVertices[3]);

			layer = nextLayer;
			angleUp = angleDown;
			scale.copyFrom(nextScale);
			modchartPos.copyFrom(modchartPosLow);
		}
		holdFrame.frame.y = backupHoldY;
		holdFrame.frame.height = backupHoldHeight;

		tailFrame.frame.height = Math.min(Math.abs(height), backupTailHeight);
		tailFrame.frame.y = backupTailY + (backupTailHeight - tailFrame.frame.height);
		final halfTailWidth = tailFrame.frame.width * scale.x * 0.5;
		final offsetX = spiral ? halfTailWidth * Math.sin(angleUp) : halfTailWidth;
		final offsetY = spiral ? halfTailWidth * Math.cos(angleUp) : 0;

		Note.modchartVertices[2].set(
			modchartPos.x - offsetX + this.offsetX,
			modchartPos.y + offsetY + this.offsetY,
			modchartPos.z + this.offsetZ
		);
		modchart.adjustVertex(this, Note.modchartVertices[2], modchartPos, newDist, curDist, lane, player, strumline, SUSTAIN);
		Note.modchartVertices[2].project();
		Note.modchartVertices[3].set(
			modchartPos.x + offsetX + this.offsetX,
			modchartPos.y - offsetY + this.offsetY,
			modchartPos.z + this.offsetZ
		);
		modchart.adjustVertex(this, Note.modchartVertices[3], modchartPos, newDist, curDist, lane, player, strumline, SUSTAIN);
		Note.modchartVertices[3].project();

		modchart.pushDraw(player, strumline, cameras, scrollFactor, tailFrame, Note.modchartVertices, colorTransform, blend, antialiasing, luminize, stealth, layer);

		tailFrame.frame.y = backupTailY;
		tailFrame.frame.height = backupTailHeight;

		scale.set(oldScaleX, oldScaleY);
		colorTransform.alphaMultiplier = ogAlpha;
	}
	#end
}