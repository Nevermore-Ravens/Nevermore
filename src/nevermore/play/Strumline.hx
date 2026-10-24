package nevermore.play;

import flixel.group.FlxSpriteGroup;
import nevermore.skins.Noteskin;
import nevermore.play.Sustain;

// i'll write docs for this later im tired
class Strumline extends FlxTypedSpriteGroup<Receptor> {
	public var field:NoteField;
	public var keyCount(default, set):Int = 4;
	function set_keyCount(v:Int):Int {
		keyCount = v;
		held = [for (i in 0...keyCount) false];
		skin = skin.findRelative(v);
		return v;
	}

	public var size(default, set):Float = 1;
	function set_size(v:Float):Float {
		var scaleMult:Float = (v / size) * keyScale;
		for (receptor in members) {
			receptor.x = (receptor.x - x) * scaleMult + x;
			receptor.scale.scale(scaleMult);

			// looks schizo but i'm basically trying to update the hitbox without screwing up the original values
			receptor.width *= scaleMult;
			receptor.height *= scaleMult;
			receptor.centerOffsets();
		}
		return size = v;
	}

	public var skin(default, set):Noteskin;
	function set_skin(v:Noteskin):Noteskin {
		skin = v;
		regen();
		return v;
	}

	public var keyScale(get, never):Float;
	function get_keyScale():Float {
		return 4 / keyCount;
	}

	public var curHolds:Array<Sustain> = [];
	public var held:Array<Bool> = [];

	// for similar properties between Strumline and ProxyField. as said, only for modcharts.
	public var modchartX:Float = 0;
	public var modchartY:Float = 0;
	public var modchartAlpha:Float = 1;

	public function setModchartOffset(?x:Float = 0, ?y:Float = 0) {
		this.modchartX = x;
		this.modchartY = y;
	}

	public var constantSize(get, never):Float;
	function get_constantSize():Float {
		return skin.spacing * size * keyScale;
	}

	// not static in case someone wants to override it
	public var pixelsPerMS(get, never):Float;
	function get_pixelsPerMS():Float {
		return (FlxG.height / 160) / 10;
	}

	public var quantization:Bool = Nevermore.settings.quantization;

	public var direction:ScrollDirection;
	public var speed:Float;
	public var ai:Bool;
	public function new(?x:Float, ?y:Float, ?skin:Noteskin) {
		this.moves = false;
		super(x, y);
		this.skin = skin.findRelative(keyCount);
	}

	function regen() {
		clear();
		var oldSize = size;
		size = 1;

		var receptor:Receptor = null;
		for (i in 0...keyCount) {
			add(receptor = new Receptor(this, i));
			if (skin != null) skin.applyNoteObject(receptor, "receptor");

			receptor.x += skin.spacing * (i - keyCount * 0.5);
			receptor.y += (skin.spacing - receptor.height) * 0.5;
		}

		receptor = null;
		size = oldSize;
	}
}