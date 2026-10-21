package nevermore.skins;

import nevermore.skins.Noteskin;
import nevermore.skins.NoteskinSection;

class SparrowSection extends NoteskinSection<String> {
	public function new(parent:Noteskin, data:Dynamic) {
		super("sparrow", parent, data.spritesheet, loadAnimsFromData(data.animations), data.scale, data.antialiasing, data.angles, data.colors, data.luminize);
	}

	public function apply(to:FlxSprite, lane:Int, luminized:Bool) {
		basicApply(to, lane, luminized);

		for (anim in animations)
			to.animation.addByPrefix(anim.name, anim.prefixes[lane % anim.prefixes.length], anim.framerate, anim.looped);
		to.animation.play(animations[0].name, true);

		to.updateHitbox();
	}

	function loadFrames(path:String) {
		for (handler in [Assets.main, Assets.dependency]) {
			if (handler.exists(path + ".xml"))
				return handler.sparrowAtlas(path);
		}
		return null;
	}
	function getBackupAnim():NoteskinAnim<String> {
		return {name: "", prefixes: [""]};
	}
}