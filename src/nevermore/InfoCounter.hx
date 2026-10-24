package nevermore;

import openfl.text.TextFormat;
import openfl.display.Sprite;
import openfl.text.TextField;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import lime.app.Application;
import lime.ui.KeyCode;
import nevermore.backend.Git.Commit;

#if hl
import hl.Gc;
#else
import nevermore.backend.memory.Memory;
#end

/**
* Displays info about the game/Nevermore,
* like app/garbage collector memory and framerate.
*
* By pressing F5, you can also see additional info
* about Nevermore, like Git history.
**/
class InfoCounter extends Sprite {
	/**
	* The rate at which this counter updates, in milliseconds.
	**/
	public static var pollingRate:Float = 1000;
	
	/**
	* The font this counter will use.
	* If you're using your own font, set this before making the counter.
	**/
	public static var font:String = 'nevermore/fonts/Nunito-Medium.ttf';

	/**
	* The amount of memory in bytes that has not been cleared
	* by the application's garbage collector.
	**/
	var gcMemory(get, never):Float;
	function get_gcMemory():Float {
		#if hl
		return 0; // hashlink only has one type of memory instead of 2 like cpp does
		#elseif cpp
		return cpp.vm.Gc.memInfo64(cpp.vm.Gc.MEM_INFO_USAGE);
		#else 
		return 0;
		#end
	}

	/**
	* The amount of memory in bytes that is in use by the application.
	**/
	var appMemory(get, never):Float;
	function get_appMemory():Float {
		#if hl
		return Gc.stats().currentMemory;
		#elseif cpp
		return Memory.getCurrentUsage();
		#else
		return 0;
		#end
	}

	/**
	* The main section of the counter.
	* This displays framerate and memory information.
	**/
	var main:InfoContainer;

	/**
	* Extra section of the counter.
	* This displays info about Nevermore, and
	* can be turned on or off by pressing F5 on your keyboard.
	**/
	var extra:InfoContainer;

	public function new() {
		super();

		var x:Float = 10;
		var y:Float = 10;
		var size:Int = 12;

		// the main info
		// like fps/memory
		addChild(main = new InfoContainer(x, y, size));
		main.updateText = function() {
			var app:String = Util.formatBytes(appMemory);
			var gc:String = Util.formatBytes(gcMemory);

			var background:Bitmap = main.background;
			var text:TextField = main.text;

			text.text = '$framerate FPS\nRAM: [APP: $app / GC: $gc]';
			
			background.width = text.width + 10;
			background.height = text.height + 10;
		}

		main.updateText();

		// extra info
		// like nevermore/flixel/openfl versions
		addChild(extra = new InfoContainer(x, (y + main.height) + 10, size));
		extra.updateText = function() {
			var background:Bitmap = extra.background;
			var text:TextField = extra.text;

			var version:String = Nevermore.version;
			var branch:String = Nevermore.branch;
			var commit:Commit = Nevermore.commit;
			var shortHash:String = commit.shortHash;
			var commitCount:Int = commit.count;

			text.text = 'Nevermore:\nVersion: $version\nBranch: $branch\nCommit $commitCount ($shortHash)';

			background.width = text.width + 10;
			background.height = text.height + 10;
		}

		extra.updateText();
		extra.visible = false;

		Application.current.window.onKeyDown.add(keyPressed);
	}

	function keyPressed(key:KeyCode, _) {
		if (key != KeyCode.F5) return;
		extra.visible = !extra.visible;
	}

	public var framerate:Int = 0;
	var _framerate:Int = 0;
	var _frameTime:Float = 0.0;
	var _time:Float = 0.0;
	override function __enterFrame(delta:Float):Void {
		_framerate++;
		_frameTime += delta;
		_time += delta;

		if (_frameTime >= 1000) {
			framerate = _framerate;
			_frameTime = _framerate = 0;
		}

		if (_time < pollingRate) return;
		_time = 0.0;

		main.updateText();
	}
}

class InfoContainer extends Sprite {
	public var background:Bitmap;
	public var text:TextField;

	public function new(x:Float, y:Float, size:Int) {
		super();

		addChild(background = new Bitmap(new BitmapData(1, 1, true, 0x99000000)));
		background.x = x;
		background.y = y;

        addChild(text = new TextField());
        text.autoSize = LEFT;
		text.x = x + 5;
		text.y = y + 5;
        text.wordWrap = text.mouseEnabled = text.selectable = false;
        text.defaultTextFormat = new TextFormat(InfoCounter.font, size, 0xFFFFFFF, JUSTIFY);
	}

	public dynamic function updateText() {}
}