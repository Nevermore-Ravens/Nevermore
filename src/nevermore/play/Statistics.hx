package nevermore.play;

@:structInit
@:publicFields
class NoteHitData {
	var time:Int = 0;
	var deviation:Float = 0;
	var count:Bool = true;
}

@:structInit
class Statistics {
	public var songName:String = 'Unknown';
	public var difficulty:String = '';

	public var hitData:Array<NoteHitData> = [];

	var _currentHit:Int = 0;
	public function registerHit(data:NoteHitData) {
		hitData[_currentHit++] = data;
	}

	public var judgements:Array<Judgement> = Judgement.current;

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

	// ty etterna server for helping <3
	// (i was NOT good at math back in high school
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

	public var noteHits:Int = 0;

	// combo breaks and misses are NOT the same thing !!
	// misses are for when you completely *miss* hitting a note and it goes off screen
	//
	// combo breaks are the more broader term for that
	// it includes both misses *and* judgements that cause you to lose a combo
	// (in n2x's case, shits break your combo)
	// hence the name "combo breaks"
	// it's how many times your combo has been set to 0, or "broken"
	public var comboBreaks:Int = 0;
	public var misses:Int = 0;

	public var maxCombo:Int = 0;
	public var combo(default, set):Int = 0;
	function set_combo(v:Int):Int {
		if (v > maxCombo) maxCombo = v;
		return combo = v;
	}

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

	public function miss() {
		comboBreaks++;
		combo = 0;
		
		misses++;
	}

	public var nps(default, set):Int = 0;
	function set_nps(v:Int):Int {
		if (v > maxNPS) maxNPS = v;
		return nps = v;
	}
	public var maxNPS:Int = 0;

	var _timer:Float = 0;
	var _nps:Int = 0;
	public function update(delta:Float) {
		_timer += delta;
		if (_timer < 1) return;

		nps = _nps;
		_nps = 0;
	}
}