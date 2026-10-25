package nevermore.play;

@:structInit
@:publicFields
class NoteHitData {
	/**
	* The time at which this hit occurs, in milliseconds.
	**/
	var time:Int = 0;

	/**
	* The deviation of this note relative to the song clock, in milliseconds.
	**/
	var deviation:Float = 0;

	/**
	* Whether this hit should count towards number calculation.
	* (ie. mean, standard deviation)
	**/
	var count:Bool = true;
}

/**
* A class that offers additional info about the player's current play.
**/
@:structInit
class Statistics {
	/**
	* The current song being played.
	**/
	public var songName:String = 'Unknown';

	/**
	* The current difficulty being played.
	**/
	public var difficulty:String = '';

	/**
	* A list of hits + misses for extra data calculation.
	* Can be used in a hitgraph to show deviation data.
	**/
	public var hitData:Array<NoteHitData> = [];

	var _currentHit:Int = 0;

	/**
	* Registers a hit for the statistics to read.
	* @param data The data for this hit.
	**/
	public function registerHit(data:NoteHitData) {
		hitData[_currentHit++] = data;
	}

	/**
	* The current judgements being used for this play.
	**/
	public var judgements:Array<Judgement> = Judgement.current;

	/**
	* The average deviation of all of the player's hits combined.
	**/
	public var mean(get, never):Float;
	function get_mean():Float {
		if (hitData.length == 0) return 0.0;

		var deviation:Float = 0.0;
		var amount:Int = 0;
		for (hit in hitData) {
			if (!hit.count) continue;

			amount++;
			deviation += hit.deviation;
		}

		return deviation / amount;
	}

	/**
	* The standard deviation of all of the player's hits combined.
	*
	* (ty etterna server for helping <3)
	* (i was NOT good at math back in high school)
	**/
	public var standardDeviation(get, never):Float;
	function get_standardDeviation():Float {
		if (hitData.length == 0) return 0.0;

		var totalDeviation:Float = 0.0;
		var squaredDeviation:Float = 0.0;
		var amount:Int = 0;
		for (hit in hitData) {
			if (!hit.count) continue;

			amount++;
			totalDeviation += hit.deviation;
			squaredDeviation += Math.pow(hit.deviation, 2);
		}

		var what:Float = (squaredDeviation / amount);
		return Math.sqrt(what - Math.pow(totalDeviation / amount, 2));
	}

	/**
	* How many notes have been hit by the player.
	**/
	public var noteHits:Int = 0;

	/**
	* How many times your combo has been reset to 0.
	*
	* Not to be mistaken for `misses`, although this
	* *does* include misses.
	**/
	public var comboBreaks:Int = 0;

	/**
	* How many times a note has gone past the screen,
	* and not been hit by the player.
	* Not to be mistaken with `comboBreaks`.
	**/
	public var misses:Int = 0;

	/**
	* The max combo this play has reached.
	**/
	public var maxCombo:Int = 0;

	/**
	* The amount of notes this player has hit
	* in a row, without breaking combo.
	**/
	public var combo(default, set):Int = 0;
	function set_combo(v:Int):Int {
		if (v > maxCombo) maxCombo = v;
		return combo = v;
	}

	/**
	* Should be called whenever a note has been hit.
	* @param behavior The corresponding note's behavior.
	* @param judge The judge that was obtained upon hitting this note.
	**/
	public function hit(behavior:NoteBehavior, judge:Judgement) {
		noteHits++;
		judge.hits++;

		if (judge.breaksCombo || behavior.punishable) {
			comboBreaks++;
			combo = 0;
		} else {
			combo++;
		}

		_nps++;
	}

	/**
	* Should be called whenever a note has been missed.
	**/
	public function miss() {
		comboBreaks++;
		combo = 0;
		
		misses++;
	}

	/**
	* The max amount of notes per second
	* this play has achieved.
	**/
	public var maxNPS:Int = 0;

	/**
	* The amount of times this player has been
	* hitting notes for the last second.
	**/
	public var nps(default, set):Int = 0;
	function set_nps(v:Int):Int {
		if (v > maxNPS) maxNPS = v;
		return nps = v;
	}

	var _timer:Float = 0;
	var _nps:Int = 0;

	/**
	* Updates the statistics for calculating NPS.
	* Preferably, call this in your `update()` override.
	**/
	public function update(delta:Float) {
		_timer += delta;
		if (_timer < 1) return;
		_timer = 0.0;

		if (_nps == 0) return;
		nps = _nps;
		_nps = 0;
	}
}