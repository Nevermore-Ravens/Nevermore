package nevermore.input;

import lime.app.Application;
import lime.ui.KeyCode;
import lime.ui.KeyModifier;
import lime.ui.GamepadButton;
import lime.ui.Gamepad;

enum ListenerType {
	PRESSED;
	RELEASED;
}

/**
* A container for keyboard/gamepad bindings.
**/
class Controls {
	public static var initialized:Bool = false;

	/**
	* The connected instance for keyboard bindings.
	**/
	public static var keyboard:Input = new Input([
		0 => [KeyCode.A, KeyCode.LEFT],
		1 => [KeyCode.S, KeyCode.DOWN],
		2 => [KeyCode.SEMICOLON, KeyCode.UP],
		3 => [KeyCode.SINGLE_QUOTE, KeyCode.RIGHT],

		4 => [KeyCode.SPACE],
		5 => [KeyCode.S],
		6 => [KeyCode.D],
		7 => [KeyCode.F],
		8 => [KeyCode.J],
		9 => [KeyCode.K],
		10 => [KeyCode.L],

		11 => [KeyCode.A],
		12 => [KeyCode.S],
		13 => [KeyCode.D],
		14 => [KeyCode.F],
		15 => [KeyCode.H],
		16 => [KeyCode.J],
		17 => [KeyCode.K],
		18 => [KeyCode.L],

		19 => [KeyCode.F],
		20 => [KeyCode.J],
	], [
		[4],
		[19,20],
		[19,4,20],
		[0,1,2,3],
		[0,1,4,2,3],
		[5,6,7,8,9,10],
		[5,6,7,4,8,9,10],
		[11,12,13,14,15,16,17,18],
		[11,12,13,14,4,15,16,17,18]
	]);

	/**
	* The connected instance for gamepad/controller bindings.
	**/
	public static var gamepad:Input = new Input([
		0 => [GamepadButton.X, GamepadButton.DPAD_LEFT],
		1 => [GamepadButton.A, GamepadButton.DPAD_DOWN],
		2 => [GamepadButton.Y, GamepadButton.DPAD_UP],
		3 => [GamepadButton.B, GamepadButton.DPAD_RIGHT],
		4 => [GamepadButton.RIGHT_SHOULDER],

		5 => [GamepadButton.DPAD_LEFT],
		6 => [GamepadButton.DPAD_DOWN],
		7 => [GamepadButton.DPAD_RIGHT],

		8 => [GamepadButton.X],
		9 => [GamepadButton.Y],
		10 => [GamepadButton.B],

		11 => [GamepadButton.DPAD_LEFT],
		12 => [GamepadButton.DPAD_DOWN],
		13 => [GamepadButton.DPAD_UP],
		14 => [GamepadButton.DPAD_RIGHT],

		15 => [GamepadButton.X],
		16 => [GamepadButton.A],
		17 => [GamepadButton.Y],
		18 => [GamepadButton.B],

		19 => [GamepadButton.DPAD_LEFT],
		20 => [GamepadButton.B],
	], [
		[4],
		[19,20],
		[19,4,20],
		[0,1,2,3],
		[0,1,4,2,3],
		[5,6,7,8,9,10],
		[5,6,7,4,8,9,10],
		[11,12,13,14,15,16,17,18],
		[11,12,13,14,4,15,16,17,18]
	]);

	/**
	* Initializes the control/input system.
	**/
	public static function init() {
		if (initialized) return;
		initialized = true;

		keyboard.bind();
		gamepad.bind();
	}
}