package nevermore.skins;

import nevermore.skins.Noteskin;
import nevermore.skins.NoteskinSection;
import flixel.graphics.frames.FlxTileFrames;
import flixel.math.FlxPoint;

class GridSection extends NoteskinSection<Array<Int>> {
	var gridWidth:Int = 16;
	var gridHeight:Int = 16;
	var gridPaddingX:Int = 16;
	var gridPaddingY:Int = 16;

	public function new(parent:Noteskin, data:Dynamic) {
		gridWidth = data.width ?? 16;
		gridHeight = data.height ?? 16;
		gridPaddingX = data.paddingX ?? 0;
		gridPaddingY = data.paddingY ?? 0;
		super("grid", parent, data.spritesheet, loadAnimsFromData(data.animations), data.scale, data.antialiasing, data.angles, data.colors, data.luminize);
	}

	public function apply(to:FlxSprite, lane:Int, luminized:Bool) {
		basicApply(to, lane, luminized);

		for (anim in animations)
			to.animation.add(anim.name, anim.prefixes[lane % anim.prefixes.length], anim.framerate, anim.looped);
		to.animation.play(animations[0].name, true);

		to.updateHitbox();
	}

	function loadFrames(path:String) {
		for (handler in [Assets.main, Assets.dependency]) {
			if (handler.exists(path + "." + handler.imageFormats[0])) {
				var size = FlxPoint.get(gridWidth, gridHeight);
				var padding = FlxPoint.get(gridPaddingX, gridPaddingY);
				var result = FlxTileFrames.fromGraphic(handler.image(path), size, null, padding);
				size.put();
				padding.put();
				return result;
			}
		}
		return null;
	}
	function getBackupAnim():NoteskinAnim<Array<Int>> {
		return {name: "", prefixes: [[0]]};
	}
}