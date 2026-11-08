package nevermore.core;

import nevermore.core.timing.TimingMap;
import nevermore.core.timing.TimingPoint;

class Util {
	public static function swapDirection(direction:ScrollDirection):ScrollDirection {
		return switch direction {
			case DOWN: UP;
			case UP: DOWN;
			default: NONE;
		}
	}

	public static function expDecay(a:Float, b:Float, decay:Float) {
		return b + (a - b) * Math.exp(-decay * FlxG.elapsed);
	}

	// i have no idea how any of this works or how to explain it
	public static function cosClip(rads:Float, _clip:Float):Float {
		return clip(Math.cos(rads), _clip);
	}

	public static function sinClip(rads:Float, _clip:Float):Float {
		return clip(Math.sin(rads), _clip);
	}

	public static function clip(value:Float, clip:Float):Float {
		var absValue:Float = Math.abs(value);
		var absClip:Float = Math.abs(clip);
		var sign:Float = value / absValue;

		if (absValue > absClip) {
			return absClip * sign;
		}

		return value;
	}

	// FlxStringUtil.formatBytes() but it just adds a space between the size and the unit lol
	public static function formatBytes(bytes:Float, ?precision:Int = 2):String {
		static final units:Array<String> = ["Bytes", "KB", "MB", "GB", "TB", "PB"];
		var curUnit:Int = 0;
		while (bytes >= 1024 && curUnit < units.length - 1)
		{
			bytes /= 1024;
			curUnit++;
		}

		return '${FlxMath.roundDecimal(bytes, precision)} ${units[curUnit]}';
	}
}