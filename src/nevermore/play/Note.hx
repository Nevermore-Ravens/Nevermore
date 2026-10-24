package nevermore.play;

import nevermore.shaders.NoteShader;
import nevermore.core.timing.BaseClock;
import nevermore.modchart.ModchartManager;

/**
* A rhythm object that resembles a "tap" note.
**/
class Note extends BaseNote {
	public static final directions:Array<String> = ['left', 'down', 'up', 'right'];

	/**
	* A colour shader that's used for custom colouring and modcharting.
	**/
	public static var colorShader:NoteShader = new NoteShader();

	public static var modchartVertices:Array<Vector3> = [
		new Vector3(),
		new Vector3(),
		new Vector3(),
		new Vector3()
	];

	/**
	* The connected sustain linked to this note.
	**/
	public var sustain:Sustain;

	override function set_type(v:String):String {
		type = v;
		behavior = NoteBehavior.get(type);
		behavior.setup(this);
		behavior.applySkin(this, NOTE);
		return v;
	}

	/**
	* Resets this note back to the default, so it can be reused.
	* @param strumline The strumline this note is connected to.
	* @param data The corresponding note data object.
	* @return This resetted note instance.
	**/
	public function setup(strumline:Strumline, data:NoteData):Note {
		active = false;
		moves = false;
		missed = false;

		this.data = data;
		this.strumline = strumline;
		this.field = strumline.field;

		angle = 0;
		visible = true;
		alpha = 1;

		sustain = null;
		passedStrumline = false;
		multAlpha = 1;
		
		time = data.time;
		lane = data.lane;
		player = data.player;
		beat = data.beat;
		length = data.length;
		
		this.receptor = strumline.members[lane];
		if (!strumline.quantization) luminize = false;
		else luminize = Nevermore.settings.quantization;

		color = NoteColor.get(this);
		type = data.type;

		return this;
	}

	override function move(clock:BaseClock):Void {
		alpha = receptor.alpha * multAlpha;
		visible = strumline.visible; //receptor.visible;   dude what the fuck

		var deviation:Float = (visualTime - clock.visualTime) + Nevermore.settings.visualOffset;
		var adjustedSpeed:Float = (strumline.speed * strumline.pixelsPerMS);

		distance = deviation * (adjustedSpeed / clock.rate);

		this.x = switch strumline.direction {
			//case TAIKO: receptor.x + distance;
			default: receptor.x;
		}

		this.y = switch strumline.direction {
			case UP: receptor.y + distance;
			case DOWN: receptor.y + (distance * -1);
			default: receptor.y;
			//case TAIKO: receptor.y;
		}
	}

	@:allow(nevermore.play.NoteObject)
	static var cachePoint = FlxPoint.get();
	public var modchartPos:Vector3 = new Vector3();
	public var stealth:Float = 0;
	override function drawCrazy(modchart:ModchartManager, direction:ScrollDirection) {
		final mult:Int = direction == DOWN ? -1 : 1;
		modchart.stealthColor.set(1.0, 1.0, 1.0);
		modchart.scrollMult = mult;

		modchart.curLane = lane;
		modchart.curField = player;
		
		final oldX:Float = x;
		final oldY:Float = y;
		final oldScaleX:Float = scale.x;
		final oldScaleY:Float = scale.y;

		var newDistance:Float = modchart.adjustDistance(this, distance * mult, lane, player, strumline, NOTE);
		
		var rawY:Float = y - distance;
		modchartPos.set(x + width * 0.5, (rawY + (newDistance * mult)) + height * 0.5, 0);

		modchart.adjustPos(this, modchartPos, newDistance, distance * mult, lane, player, strumline, NOTE);
		modchart.adjustScale(this, scale, newDistance, lane, player, strumline, NOTE); // TODO: add newDistance to the args of this and getStealth
		stealth = modchart.getStealth(this, newDistance, distance * mult, modchartPos, lane, player, strumline, NOTE);
		modchartPos.z += offsetZ;

		x = modchartPos.x - width * 0.5;
		y = modchartPos.y - height * 0.5;
		final layer = modchartPos.z;
		_frame.prepareMatrix(_matrix, ANGLE_0, checkFlipX(), checkFlipY());
		prepareMatrix(cameras[0]);
		_matrix.translate(cameras[0].scroll.x * scrollFactor.x, cameras[0].scroll.y * scrollFactor.y);
		x = oldX;
		y = oldY;
		scale.set(oldScaleX, oldScaleY);

		prepareModchartVertices(modchartPos.z);
		final orientAngle:Float = getOrientAngle(
			modchart,
			modchartPos,
			mult,
			rawY + ((newDistance + 2) * mult),
			newDistance + 2,
			(distance * mult) + 2,
			player,
			strumline,
			NOTE
		);

		if(orientAngle != 0){
			for (i => vert in modchartVertices) {	
				vert.x -= modchartPos.x;
				vert.y -= modchartPos.y;
				vert.z -= modchartPos.z;
				vert.rotateRads(0, 0, orientAngle);
				vert.x += modchartPos.x;
				vert.y += modchartPos.y;
				vert.z += modchartPos.z;
			}
		}

		for (i => vert in modchartVertices) {
			modchart.adjustVertex(this, vert, modchartPos, newDistance, distance * mult, lane, player, strumline, NOTE);
			vert.project();
		}

		_drawFrame = _frame.copyTo(_drawFrame);
		modchart.pushDraw(player, strumline, cameras, scrollFactor, _drawFrame, modchartVertices, colorTransform, blend, antialiasing, luminize, stealth, layer);
	}
}