package nevermore.backend;

/**
* Basically a recreation of `FlxColor` to reduce dependency on HaxeFlixel.
*
* *Mostly* copypasted.
**/
abstract Color(Int) from Int from UInt to Int to UInt {
	public static inline var TRANSPARENT:Color = 0x00000000;
	public static inline var WHITE:Color = 0xFFFFFFFF;
	public static inline var GRAY:Color = 0xFF808080;
	public static inline var BLACK:Color = 0xFF000000;

	public static inline var GREEN:Color = 0xFF008000;
	public static inline var LIME:Color = 0xFF00FF00;
	public static inline var YELLOW:Color = 0xFFFFFF00;
	public static inline var ORANGE:Color = 0xFFFFA500;
	public static inline var RED:Color = 0xFFFF0000;
	public static inline var PURPLE:Color = 0xFF800080;
	public static inline var BLUE:Color = 0xFF0000FF;
	public static inline var BROWN:Color = 0xFF8B4513;
	public static inline var PINK:Color = 0xFFFFC0CB;
	public static inline var MAGENTA:Color = 0xFFFF00FF;
	public static inline var CYAN:Color = 0xFF00FFFF;

	/**
	* Fields for the red channel of this colour.
	**/
	public var red(get, set):Int;
	inline function get_red():Int {
		return (this >> 16) & 0xff;
	}

	inline function set_red(value:Int):Int {
		this &= 0xff00ffff;
		this |= boundChannel(value) << 16;
		return value;
	}

	public var redFloat(get, set):Float;
	inline function get_redFloat():Float return red / 255;

	inline function set_redFloat(value:Float):Float {
		red = Math.round(value * 255);
		return value;
	}

	/**
	* Fields for the green channel of this colour.
	**/
	public var green(get, set):Int;
	inline function get_green():Int {
		return (this >> 8) & 0xff;
	}

	inline function set_green(value:Int):Int {
		this &= 0xffff00ff;
		this |= boundChannel(value) << 8;
		return value;
	}

	public var greenFloat(get, set):Float;
	inline function get_greenFloat():Float return green / 255;

	inline function set_greenFloat(value:Float):Float {
		green = Math.round(value * 255);
		return value;
	}

	/**
	* Fields for the blue channel of this colour.
	**/
	public var blue(get, set):Int;
	inline function get_blue():Int {
		return this & 0xff;
	}

	inline function set_blue(value:Int):Int {
		this &= 0xffffff00;
		this |= boundChannel(value);
		return value;
	}

	public var blueFloat(get, set):Float;
	inline function get_blueFloat():Float return blue / 255;

	inline function set_blueFloat(value:Float):Float {
		blue = Math.round(value * 255);
		return value;
	}

	/**
	* Fields for the alpha channel of this colour.
	**/
	public var alpha(get, set):Int;
	inline function get_alpha():Int {
		return (this >> 24) & 0xff;
	}

	inline function set_alpha(value:Int):Int {
		this &= 0x00ffffff;
		this |= boundChannel(value) << 24;
		return value;
	}
	
	public var alphaFloat(get, set):Float;
	inline function get_alphaFloat():Float return alpha / 255;

	inline function set_alphaFloat(value:Float):Float {
		alpha = Math.round(value * 255);
		return value;
	}

	public var cyan(get, set):Float;
	inline function get_cyan():Float {
		return (1 - redFloat - black) / brightness;
	}

	inline function set_cyan(value:Float):Float {
		setCMYB(value, magenta, yellow, black, alphaFloat);
		return value;
	}

	public var magenta(get, set):Float;
	inline function get_magenta():Float {
		return (1 - greenFloat - black) / brightness;
	}

	inline function set_magenta(value:Float):Float {
		setCMYB(cyan, value, yellow, black, alphaFloat);
		return value;
	}

	public var yellow(get, set):Float;
	inline function get_yellow():Float {
		return (1 - blueFloat - black) / brightness;
	}

	inline function set_yellow(value:Float):Float {
		setCMYB(cyan, magenta, value, black, alphaFloat);
		return value;
	}

	public var black(get, set):Float;
	inline function get_black():Float return 1 - brightness;

	inline function set_black(value:Float):Float {
		setCMYB(cyan, magenta, yellow, value, alphaFloat);
		return value;
	}

	/**
	* The red, green, and blue channels of this colour, as a 24-bit integer.
	* (from 0 to 0xFFFFFF)
	**/
	public var rgb(get, set):Color;
	inline function get_rgb():Color return this & 0x00ffffff;

	inline function set_rgb(value:Color):Color {
		this = (this & 0xff000000) | (value & 0x00ffffff);
		return value;
	}

	/** 
	* The hue of this colour, in degrees.
	* (from 0 to 359)
	**/
	public var hue(get, set):Float;
	function get_hue():Float {
		var hueRad = Math.atan2(Math.sqrt(3) * (greenFloat - blueFloat), 2 * redFloat - greenFloat - blueFloat);
		var hue:Float = 0;
		if (hueRad != 0) {
			hue = 180 / Math.PI * hueRad;
		}

		return hue < 0 ? hue + 360 : hue;
	}

	inline function set_hue(value:Float):Float {
		setHSB(value, saturation, brightness, alphaFloat);
		return value;
	}

	/**
	* The saturation of this colour.
	* (from 0 to 1)
	**/
	public var saturation(get, set):Float;
	inline function get_saturation():Float {
		return (max - min) / brightness;
	}

	inline function set_saturation(value:Float):Float {
		setHSB(hue, value, brightness, alphaFloat);
		return value;
	}

	/**
	* The brightness of this colour.
	* (from 0 to 1)
	**/
	public var brightness(get, set):Float;
	inline function get_brightness():Float return max;

	inline function set_brightness(value:Float):Float {
		setHSB(hue, saturation, value, alphaFloat);
		return value;
	}

	/**
	* The lightness of this colour.
	* (from 0 to 1)
	**/
	public var lightness(get, set):Float;
	inline function get_lightness():Float {
		return (max + min) / 2;
	}

	inline function set_lightness(value:Float):Float {
		setHSL(hue, saturation, value, alphaFloat);
		return value;
	}

	/**
	* The most visible channel that this colour contains.
	**/
	public var max(get, never):Float;
	function get_max():Float {
		return Math.max(redFloat, Math.max(greenFloat, blueFloat));
	}

	/**
	* The least visible channel that this colour contains.
	**/
	public var min(get, never):Float;
	function get_min():Float {
		return Math.min(redFloat, Math.min(greenFloat, blueFloat));
	}

	/**
	* Sets the cyan, magenta, yellow, and black channels of this colour.
	*
	* @param cyan The cyan channel of this colour, from 0 to 1.
	* @param magenta The magenta channel of this colour, from 0 to 1.
	* @param yellow The yellow channel of this colour, from 0 to 1.
	* @param black The black channel of this colour, from 0 to 1.
	* @param alpha The alpha channel of this colour, from 0 to 1.
	* @return The modified instance of this colour.
	**/
	public inline function setCMYB(cyan:Float, magenta:Float, yellow:Float, black:Float, ?alpha:Float = 1):Color {
		redFloat = (1 - cyan) * (1 - black);
		greenFloat = (1 - magenta) * (1 - black);
		blueFloat = (1 - yellow) * (1 - black);
		alphaFloat = alpha;

		return this;
	}

	/**
	* Sets the hue, saturation, and brightness channels of this colour.
	*
	* @param hue The hue channel of this colour, from 0 to 1.
	* @param saturation The saturation channel of this colour, from 0 to 1.
	* @param brightness The brightness channel of this colour, from 0 to 1.
	* @param alpha The alpha channel of this colour, from 0 to 1.
	* @return The modified instance of this colour.
	**/
	public inline function setHSB(hue:Float, saturation:Float, brightness:Float, alpha:Float):Color {
		var chroma:Float = brightness * saturation;
		var match:Float = brightness - chroma;

		return setHueChromaMatch(hue, chroma, match, alpha);
	}

	/**
	* Sets the hue, saturation, and lightness channels of this colour.
	*
	* @param hue The hue channel of this colour, from 0 to 1.
	* @param saturation The saturation channel of this colour, from 0 to 1.
	* @param lightness The lightness channel of this colour, from 0 to 1.
	* @param alpha The alpha channel of this colour, from 0 to 1.
	* @return The modified instance of this colour.
	**/
	public inline function setHSL(hue:Float, saturation:Float, lightness:Float, alpha:Float):Color
	{
		var chroma:Float = (1 - Math.abs(2 * lightness - 1)) * saturation;
		var match:Float = lightness - chroma / 2;

		return setHueChromaMatch(hue, chroma, match, alpha);
	}
	
	/**
	* Sets the red, green, and blue channels of this colour.
	*
	* @param red The red channel of this colour, from 0 to 1.
	* @param green The green channel of this colour, from 0 to 1.
	* @param blue The blue channel of this colour, from 0 to 1.
	* @param alpha The alpha channel of this colour, from 0 to 1.
	* @return The modified instance of this colour.
	**/
	public inline function setRGBFloat(red:Float, green:Float, blue:Float, alpha:Float = 1):Color {
		redFloat = red;
		greenFloat = green;
		blueFloat = blue;
		alphaFloat = alpha;

		return this;
	}

	/**
	* Internal function used for consistency between `setHSB` and `setHSL`.
	**/
	inline function setHueChromaMatch(hue:Float, chroma:Float, match:Float, alpha:Float):Color {
		hue %= 360;
		chroma += match;

		var hueD:Float = hue / 60;
		var mid:Float = chroma * (1 - Math.abs(hueD % 2 - 1)) + match;

		switch Std.int(hueD) {
			case 0:
				setRGBFloat(chroma, mid, match, alpha);
			case 1:
				setRGBFloat(mid, chroma, match, alpha);
			case 2:
				setRGBFloat(match, chroma, mid, alpha);
			case 3:
				setRGBFloat(match, mid, chroma, alpha);
			case 4:
				setRGBFloat(mid, match, chroma, alpha);
			case 5:
				setRGBFloat(chroma, match, mid, alpha);
		}

		return this;
	}

	/**
	* Internal function used to limit colour values between `0xFF` and `0`.
	**/
	inline function boundChannel(value:Int):Int {
		return value > 0xff ? 0xff : value < 0 ? 0 : value;
	}
}