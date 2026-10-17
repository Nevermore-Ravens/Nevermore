package nevermore.input;

import lime.app.Application;
import lime.app.Event;
import lime.ui.Gamepad;
import lime.ui.GamepadButton;
import lime.ui.KeyCode;
import lime.system.System;
import nevermore.play.Note;
import nevermore.play.Sustain;
import nevermore.play.Strumline;

enum InputPreference {
	ALL;
	KEYBOARD;
	GAMEPAD;
}

// combines keyboard/gamepad input into one callback
// and converts the input into a 0 - keyCount integer
class InputManager {
	public var onPress:Event<(Int, Int) -> Void>;
	public var onRelease:Event<(Int, Int) -> Void>;
	public var timestamp:Int = 0;
	public var keyCount:Int = 4;

	// makes it able to only allow keyboard/gamepad input
	// or allow both at once
	public var prefer:InputPreference = ALL;

	// since this never calls remove() you can technically make a fuckton of gamepads
	// by just disconnecting/reconnecting the same controller
	// but im not sure how to go around this sooooooooooooooo
	public var gamepads:Array<CustomGamepad> = [];

	public function new() {
		onPress = new Event<(Int, Int) -> Void>();
		onRelease = new Event<(Int, Int) -> Void>();

		Gamepad.onConnect.add(_onConnectGamepad);
		for (gamepad in Gamepad.devices) gamepads.push(new CustomGamepad(this, gamepad));

		Application.current.window.onKeyDown.add(keyPressed);
		Application.current.window.onKeyUp.add(keyReleased);
	}
	
	public function destroy() {
		Application.current.window.onKeyDown.remove(keyPressed);
		Application.current.window.onKeyUp.remove(keyReleased);
		Gamepad.onConnect.remove(_onConnectGamepad);

		for (gamepad in gamepads) gamepad.destroy();
		gamepads.resize(0);

		onPress.removeAll();
		onRelease.removeAll();
		onPress = null;
		onRelease = null;
	}

	function _onConnectGamepad(gamepad:Gamepad) {
		if (gamepad.id != 0) return;
		gamepads.push(new CustomGamepad(this, gamepad));
	}

	inline function keyPressed(key:KeyCode, _) {
		if (prefer == GAMEPAD) return;

		var direction:Int = Controls.keyboard.get(keyCount, key);
		if (direction == -1) return;

		#if (lime >= version("8.4.0"))
		timestamp = Application.current.window.onKeyDown.timestamp;
		#else
		timestamp = System.getTimer();
		#end

		// -1 because who the fuck has more than one keyboard connected
		onPress.dispatch(-1, direction);
	}

	inline function keyReleased(key:KeyCode, _) {
		if (prefer == GAMEPAD) return;

		var direction:Int = Controls.keyboard.get(keyCount, key);
		if (direction == -1) return;

		onRelease.dispatch(-1, direction);
	}

	public function tap(id:Int, direction:Int):Note {return null;}
	public function releaseTimings(strumline:Strumline, sustain:Sustain) {}
	public function regrabTimer(strumline:Strumline, sustain:Sustain) {}
	public function autoplay(strumline:Strumline, note:Note) {}
}

class CustomGamepad {
	public var manager:InputManager;
	public var id:Int = 0;
	var _gamepad:Gamepad;
	public function new(manager:InputManager, gamepad:Gamepad) {
		_gamepad = gamepad;

		this.id = gamepad.id;
		this.manager = manager;

		_gamepad.onButtonDown.add(buttonPressed);
		_gamepad.onButtonUp.add(buttonReleased);
	}

	public function destroy() {
		_gamepad.onButtonDown.remove(buttonPressed);
		_gamepad.onButtonUp.remove(buttonReleased);

		_gamepad = null;
		manager = null;
	}

	inline function buttonPressed(button:GamepadButton) {
		if (manager.prefer == KEYBOARD) return;

		var direction:Int = Controls.gamepad.get(manager.keyCount, button);
		if (direction == -1) return;

		#if (lime >= version("8.4.0"))
		manager.timestamp = _gamepad.onButtonDown.timestamp;
		#else
		manager.timestamp = System.getTimer();
		#end

		manager.onPress.dispatch(_gamepad.id, direction);
	}

	inline function buttonReleased(button:GamepadButton) {
		if (manager.prefer == KEYBOARD) return;

		var direction:Int = Controls.gamepad.get(manager.keyCount, button);
		if (direction == -1) return;

		manager.onRelease.dispatch(_gamepad.id, direction);
	}
}