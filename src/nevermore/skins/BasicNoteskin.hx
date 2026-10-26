package nevermore.skins;

import nevermore.play.Note;

/**
	Not actually a instance of Noteskin but instead a loader for basic/sparrow only noteskins.
**/
class BasicNoteskin {
	/**
	* The scale to use basic noteskin creation.
	*/
	public static var scale:Float = 0.7;

	public static var directionList:Array<Array<Int>> = [
		[2], // later on, we may add a `diamond` to the basic but....
		[0, 3],
		[0, 2, 3],
		[0, 1, 2, 3],
		[0, 1, 2, 2, 3],
		[3, 2, 1, 1, 2, 3],
		[3, 2, 1, 2, 1, 2, 3],
		[0, 1, 2, 3, 3, 2, 1, 0],
		[0, 1, 2, 3, 2, 3, 2, 1, 0]
	];
	public static var angleList:Array<Array<Float>> = [
		null,
		null,
		null,
		null,
		[-45, 135, 0, 45, 45],
		[180, -45, 0, 180, 45, 0],
		[180, -45, 0, 0, 180, 45, 0],
		[0, 0, 0, 0, 180, 180, 180, 180],
		[0, 0, 0, 0, 0, 180, 180, 180, 180],
	];

	/**
	* Loads a skin using only a sparrow atlas.
	*
	* @param key Which sparrow atlas to load.
	* @param keyCount Which keyCount this is meant for. Will determine the animation list.
	* @param luminized Whether this is using a luminized varient.
	*/
	public static function create(key:String, keyCount:Int, luminized:Bool) {
		var directions = [for (idx in directionList[keyCount - 1]) Note.directions[idx]];
		var colors = [for (idx in directionList[keyCount - 1]) Noteskin.colors[idx]];
		var angles = angleList[keyCount - 1];

		return new Noteskin({
			spacing: 160 * scale,
			scale: scale,

			receptor: {
				style: "sparrow", // this one actually isnt necessary but....
				spritesheet: key,
				angles: angles,
				animations: [
					{
						name: "standard",
						prefixes: [for (dir in directions) 'arrow${dir.toUpperCase()}'],
						looped: true
					},
					{
						name: "pressed",
						prefixes: [for (dir in directions) '$dir press']
					},
					{
						name: "glow",
						prefixes: [for (dir in directions) '$dir confirm']
					},
				]
			},

			note: {
				style: "sparrow",
				spritesheet: key,
				angles: angles,
				animations: [{
					name: "standard",
					prefixes: [for (col in colors) '${col}0'],
					looped: true
				}]
			},

			sustain: {
				style: "sparrow",
				spritesheet: key,
				angles: angles,
				animations: [
					{
						name: "piece",
						prefixes: [for (col in colors) '${col} hold piece'],
						looped: true
					},
					{
						name: "tail",
						prefixes: [for (col in colors) '${col} hold end'],
						looped: true
					}
				]
			},

			roll: {
				style: "sparrow",
				spritesheet: key,
				angles: angles,
				animations: [
					{
						name: "piece",
						prefixes: [for (col in colors) '${col} roll piece'],
						looped: true
					},
					{
						name: "tail",
						prefixes: [for (col in colors) '${col} roll end'],
						looped: true
					}
				]
			}
		}, "", luminized, key, keyCount);
	}
}