package nevermore.input;

import lime.ui.KeyCode;
import openfl.ui.Keyboard;

/**
 * Conversion utilities for `KeyCode`s, and `Keyboard`s/`FlxKey`s.
**/
@:access(openfl.ui.Keyboard)
class KeyMapping {
	static var __boardToCode:Map<Int, KeyCode> = KeyMappingMacro.mapFields("lime.ui.KeyCode", "nevermore.input.KeyMapping.codeToBoard", true);

	// DO NOT. MAKE THIS INLINE.
	// YOU WILL GET A 100K LINE FILE TO COMPILE
	public static function codeToBoard(code:Int) {
		@:privateAccess return Keyboard.__convertKeyCode(code);
	}
	public static inline function boardToCode(key:Int) {
		return __boardToCode.get(key);
	}
}