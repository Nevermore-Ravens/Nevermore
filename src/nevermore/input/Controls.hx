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
A container for keyboard/gamepad bindings.
*/
class Controls {
	public static var initialized:Bool = false;

	/**
	The connected instance for keyboard bindings.
	*/
	public static var keyboard:Input = new Input([
		0 => [KeyCode.D, KeyCode.LEFT],
		1 => [KeyCode.F, KeyCode.DOWN],
		2 => [KeyCode.J, KeyCode.UP],
		3 => [KeyCode.K, KeyCode.RIGHT],

		4 => [KeyCode.SPACE],

		5 => [KeyCode.D],
		6 => [KeyCode.F],
		7 => [KeyCode.J],
		8 => [KeyCode.K],
		
		9 => [KeyCode.A],
		10 => [KeyCode.S],
		11 => [KeyCode.L],
		12 => [KeyCode.H],
	], [
		[4],
		[6, 7],
		[6, 4, 7],
		[0, 1, 2, 3],
		[0, 1, 4, 2, 3],
		[10, 5, 6, 7, 8, 11],
		[10, 5, 6, 4, 7, 8, 11],
		[9, 10, 5, 6, 12, 7, 8, 11],
		[9, 10, 5, 6, 4, 12, 7, 8, 11]
	]);

	/**
	The connected instance for gamepad/controller bindings.
	*/
	public static var gamepad:Input = new Input([
		0 => [GamepadButton.X, GamepadButton.DPAD_LEFT],
		1 => [GamepadButton.A, GamepadButton.DPAD_DOWN],
		2 => [GamepadButton.Y, GamepadButton.DPAD_UP],
		3 => [GamepadButton.B, GamepadButton.DPAD_RIGHT],
		4 => [GamepadButton.RIGHT_SHOULDER],

		5 => [GamepadButton.DPAD_LEFT],
		6 => [GamepadButton.DPAD_DOWN],
		7 => [GamepadButton.DPAD_UP],
		8 => [GamepadButton.DPAD_RIGHT],

		9 => [GamepadButton.X],
		10 => [GamepadButton.A],
		11 => [GamepadButton.Y],
		12 => [GamepadButton.B],
	], [
		[4],
		[5, 12],
		[5, 4, 12],
		[0, 1, 2, 3],
		[0, 1, 4, 2, 3],
		[5, 6, 8, 9, 11, 12],
		[5, 6, 8, 4, 9, 11, 12],
		[5, 6, 7, 8, 9, 10, 11, 12],
		[5, 6, 7, 8, 4, 9, 10, 11, 12]
	]);

	/**
	Initializes the control/input system.
	*/
	public static function init() {
		if (initialized) return;
		initialized = true;

		keyboard.bind();
		gamepad.bind();
	}
}