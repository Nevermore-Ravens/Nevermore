package nevermore.play;

import flixel.group.FlxSpriteGroup;

class FieldBackground extends FlxTypedSpriteGroup<Underlay> {
	public function new(?lines:Array<Strumline>) {
		super();
		for (line in lines ?? []) add(new Underlay(line));
	}

	override function update(_) {
		for (underlay in members) {
			var strumline:Strumline = underlay.strumline;

			underlay.x = strumline.x - (underlay.width / 2);
			underlay.visible = this.visible && strumline.visible;
			underlay.alpha = strumline.alpha * this.alpha;
		}
	}
}

class Underlay extends FlxSprite {
	public var strumline:Strumline;
	public function new(strumline:Strumline) {
		super();
		this.strumline = strumline;
		active = false;
		moves = false;

		makeGraphic(1, 1, 0xFFFFFFFF); // set to white so you can set your own colours
		scale.set(strumline.width + 40, FlxG.height);
		updateHitbox();
	}
}