package nevermore.input;

/**
* An input instance to handle/contain bindings for this type of input.
*
* For example: adding `DFJK` as default keyboard inputs:
* ```hx
* var keyboard:Input = new Input([
*	 0 => [KeyCode.D],
*	 1 => [KeyCode.S],
*	 2 => [KeyCode.SEMICOLON],
*	 3 => [KeyCode.SINGLE_QUOTE],
* ], [
*	 [0],         // 1K has its bindings set as `D`
*	 [0, 1],      // 2K has its bindings set as `DF`
*	 [0, 1, 2],   // 3K has its bindings set as `DFJ`
*	 [0, 1, 2, 3] // 4K has its bindings set as `DFJK`
* ]);
* ```
**/
class Input {
	/**
	* Makes a new binding instance for this type of input.
	* @param binds The available keys/buttons to be used for this instance
	* linked to a specific ID.
	*
	* @param kGroups A list of an array of IDs that correspond to the bindings listed in `binds`.
	* The specific length of that array is the key count those bindings are linked to.
	* @return This new input bindings instance.
	**/
	public function new(binds:Map<Int, Array<InputType>>, kGroups:Array<Array<Int>>) {
		default_binds = binds.copy();
		this.kGroups = kGroups.copy();
		this.binds = [
			for (bind in binds.keys()) {
				bind => binds[bind].copy();
			}
		];
	}

	public var default_binds(default, null):Map<Int, Array<InputType>>;
	public var kGroups:Array<Array<Int>>;
	public var binds:Map<Int, Array<InputType>>;

	public var direction:Array<Map<InputType, Int>> = [];
	public function bind() {
		direction.resize(0);
		for (kg in kGroups) {
			var list:Map<InputType, Int> = [];
			var it = 0;
			for (k in kg) {
				for (i in binds.get(k)) {
					list.set(i, it);
				}
				it++;
			}
			direction.push(list);
		}
	}

	/**
	* Converts a specific input button to a direction, spanning from 0 to the key count.
	* @param keyCount The amount of keys being used.
	* @param key The key that is being converted.
	* @return A number spanning from 0 to the key count.
	**/
	public inline function get(keyCount:Int = 4, key:InputType):Int {
		return direction[keyCount - 1][key] ?? -1;
	}
}