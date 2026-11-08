package nevermore.play;

import flixel.util.FlxSpriteUtil;
import flixel.graphics.FlxGraphic;
import flixel.group.FlxSpriteGroup;
import openfl.display.BitmapData;
import openfl.geom.Rectangle;

/**
Displays the deviation of a tap's hit on a coloured bar.
Heavily inspired by BoloVEVO's hit error bar, so cheers to him.
*/
class HitErrorBar extends FlxSpriteGroup {
	/**
	The actual bar itself.
	*/
	var line:FlxSprite;

	/**
	The triangle pointer below the bar.
	*/
	var pointer:FlxSprite;

	/**
	The group of lines that display when a hit happened.
	*/
	var hitRegistery:FlxTypedSpriteGroup<NoteHitBar>;

	public function new(?x:Float = 0.0, ?y:Float = 0.0, ?list:Array<Judgement>) {
		super();

		list ??= Judgement.current;

		// grab the highest hit window
		var highestWindow:Float = list[list.length - 1].window;
		// multiply by 2 since this goes both ways
		var bitmapLine:BitmapData = new BitmapData(Std.int(highestWindow * 2), 5, true);

		var rect:Rectangle = new Rectangle(0, 0, 1, bitmapLine.height);
		var posOffset:Float = 0.0;
		for (i in 0 ... list.length) {
			var judge:Judgement = list[i];
			var width:Float = judge.window;
			var colour:Int = judge.color;
			rect.width = width;

			rect.x = highestWindow - posOffset - width; // top-left positioning, offset by width to "right-align" it
			bitmapLine.fillRect(rect, colour);
			rect.x = highestWindow + posOffset;
			bitmapLine.fillRect(rect, colour);

			posOffset = width;
		}

		add(line = new FlxSprite().loadGraphic(FlxGraphic.fromBitmapData(bitmapLine, false, 'nevermore_error_bar')));
		line.alpha = 0.4;

		add(pointer = new FlxSprite((line.x + line.width / 2) - 5, 12.5).makeGraphic(10, 10, 0x00));
		FlxSpriteUtil.drawTriangle(pointer, 0, 0, 10, 0xFFFFFFFF, {thickness: 0, color: 0xFFFFFFFF}, {smoothing: true});
		pointer.scale.set(1, 0.65);
		pointer.updateHitbox();

		add(hitRegistery = new FlxTypedSpriteGroup<NoteHitBar>());
	}

	var curDeviation:Float = 0.0;
	override function update(elapsed:Float) {
		if (!pointer.visible) return;

		var pointerCenter:Float = (pointer.width / 2);
		var lineLength:Float = line.x + line.width;
		var rawPos = FlxMath.remapToRange(curDeviation, -Judgement.max.window, Judgement.max.window, line.x, lineLength) - pointerCenter;

		pointer.x = Util.expDecay(pointer.x, rawPos, 7.5);
	}

	/**
	Displays a hit on the bar.
	@param deviation The distance between the player's hit and the song clock.
	*/
	public function hit(deviation:Float) {
		curDeviation = deviation;

		var hitBar:NoteHitBar = hitRegistery.recycle(NoteHitBar);
		hitBar.setup();

		var lineLength:Float = line.x + line.width;
		var lineCenter:Float = line.x + (line.width / 2);

		var barPos:Float = FlxMath.remapToRange(deviation, -Judgement.max.window, Judgement.max.window, line.x, line.x + line.width - hitBar.width);
		hitBar.camera = camera;
		hitBar.setPosition(barPos, this.y - 7);
		hitBar.alpha = 0.7;
	}
}

class NoteHitBar extends FlxSprite {
	// the amount of time bars take to start fading in seconds
	public static var fadeDelay:Float = 0.5;

	// the amount of time this bar has been visible in seconds
	public var existTime:Float = 0.0;

	public function setup() {
		if (graphic != null) return;

		makeGraphic(3, 18, 0xFFFFFFFF);
	}

	override function draw() {
		super.draw();

		existTime += FlxG.elapsed;
		if (existTime > fadeDelay)
			alpha -= 0.25 * FlxG.elapsed;

		if (alpha <= 0.0) kill();
	}

	override function revive() {
		alive = true;
		exists = true;
	}

	override function kill() {
		alive = false;
		exists = false;

		existTime = 0.0;
	}
}