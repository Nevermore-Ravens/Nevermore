package nevermore.play;

import flixel.group.FlxSpriteGroup;
import nevermore.skins.Noteskin;
import nevermore.play.Sustain;

/**
* Contains a set list of receptors corresponding to specific inputs.
* Can either be referred to as the "player" or "strum bar".
* Both notes and sustains follow this line.
**/
class Strumline extends FlxTypedSpriteGroup<Receptor> {
	/**
	* The parent field of this strumline.
	**/
	public var field:NoteField;

	/**
	* The amount of keys used for this strumline.
	**/
	public var keyCount(default, set):Int = 4;
	function set_keyCount(v:Int):Int {
		keyCount = v;
		held = [for (i in 0...keyCount) false];
		skin = skin.findRelative(v);
		return v;
	}

	/**
	* The general scale ratio of this strumline, relative to the key count.
	* Higher key counts make the strumline smaller, lower key counts make it bigger.
	**/
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

	/**
	* The current skin being used for this strumline.
	* Notes and sustains follow this as well, unless specified otherwise.
	**/
	public var skin(default, set):Noteskin;
	function set_skin(v:Noteskin):Noteskin {
		skin = v;
		regen();
		return v;
	}

	/**
	* The scale ratio dependant on the key count.
	**/
	public var keyScale(get, never):Float;
	function get_keyScale():Float {
		return 4 / keyCount;
	}

	/**
	* The current sustain objects being held for this strumline.
	**/
	public var curHolds:Array<Sustain> = [];

	/**
	* What keys/receptors are currently being held by the player.
	* Ranges from `0 - keyCount`.
	**/
	public var held:Array<Bool> = [];

	// for similar properties between Strumline and ProxyField. as said, only for modcharts.
	public var modchartX:Float = 0;
	public var modchartY:Float = 0;
	public var modchartAlpha:Float = 1;

	public function setModchartOffset(?x:Float = 0, ?y:Float = 0) {
		this.modchartX = x;
		this.modchartY = y;
	}

	/**
	* The constant size/spacing of this strumline.
	* Is used to determine strumline positioning and in modcharting.
	**/
	public var constantSize(get, never):Float;
	function get_constantSize():Float {
		return skin.spacing * size * keyScale;
	}

	/**
	* The distance from the bottom of the screen up to this strumline.
	* Is used primarly in note positioning and modcharting.
	**/
	public var pixelsPerMS(get, never):Float;
	function get_pixelsPerMS():Float {
		return (FlxG.height / 160) / 10;
	}

	/**
	* Whether this strumline (and its connected objects)
	* are allowed to have custom colouring.
	**/
	public var luminize:Bool = Nevermore.settings.quantization;

	/**
	* What direction this strumline is scrolling in.
	**/
	public var direction:ScrollDirection;

	/**
	* The speed at which the connected objects of this strumline are going.
	**/
	public var speed:Float;

	/**
	* Whether this strumline will play by itself, when connected to a field or input manager.
	**/
	public var ai:Bool;

	/**
	* Initializes this strumline object.
	* @param x The position of this strumline, on the X axis.
	* @param y The position of this strumline, on the Y axis.
	* @param skin The noteskin this strumline will be using.
	* @return This new strumline instance.
	**/
	public function new(?x:Float, ?y:Float, ?skin:Noteskin) {
		this.moves = false;
		super(x, y);
		this.skin = skin.findRelative(keyCount);
	}

	/**
	* Regenerates this strumline's receptors,
	* along with its scaling and spacing properties.
	**/
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