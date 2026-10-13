package nevermore.modchart;

// TODO:
// please for the love of god make this smaller holy shit
// also make it so we don't have to do `parent = this;` every frame
#if !NEVERMORE_NO_MODCHARTS
import flixel.graphics.frames.FlxFrame;
import flixel.FlxCamera;
import openfl.geom.ColorTransform;
import openfl.display.BlendMode;
import nevermore.play.*;
import nevermore.modchart.drawing.*;
import nevermore.modchart.mods.*;
import nevermore.modchart.timeline.*;
import nevermore.backend.Vector3;

using flixel.util.FlxColorTransformUtil;

@:structInit class ModRedirect {
	@:optional public var toClass:Class<BaseModifier>;
	@:optional public var toInstance:BaseModifier;
	public var index:Int;
	public var lane:Int = -1;
}

typedef NodeFunc = (values:Array<Float>, Int) -> Array<Float>; // otherwise it dont look pretty
@:structInit class AuxNode {
	public var inputs:Array<ModRedirect>;
	public var outputs:Array<ModRedirect>;

	public var func:NodeFunc;
}

class ModchartManager {
	static final digitRegex = ~/\d/g;
	static var drawColor:ColorTransform = new ColorTransform();
	public static var modifiersToAttach:Array<Class<BaseModifier>>;
	public static var defaultRedirects:Map<String, ModRedirect> = [];
	public var replacedRedirects:Map<String, ModRedirect> = [];
	public var redirects:Map<String, ModRedirect> = [];

	public var allMods:Array<BaseModifier> = [];
	public var allAuxes:Array<AuxModifier> = []; // so they can cache their values
	public var nodes:Array<AuxNode> = [];
	public var config:ModchartConfig;

	public var timeline:ModchartTimeline;
	public var strumlineCount:Int = 0;

	public var parent:BaseField;
	public var laneCount:Int = 4;
	public var curLane:Int = 0;
	public var curField:Int = 0;

	public var queuedDraws:Array<QueuedDraw> = [];
	public var proxies:Array<ProxyField> = [];

	public var scrollMult:Float = 1;
	public var stealthColor:Vector3 = new Vector3(1.0, 1.0, 1.0);

	public var arrowPath:ArrowPath = null;

	public function new() {
		timeline = new ModchartTimeline();
		addStrumlineSets(2);

		config = cast getInstance(ModchartConfig); // use getInstance to auto-add/allow .getRedirect to grab it properly
	}

	function getInstance(inputCls:Class<BaseModifier>) {
		for (mod in allMods) {
			if (Std.isOfType(mod, inputCls))
				return mod;
		}
		return addMod(Type.createInstance(inputCls, [this]));
	}

	function getRedirect(name:String, ?silent:Bool = false) {
		if (!redirects.exists(name)) {
			var grabName = name;
			if (digitRegex.match(grabName)) {
				var matchedOne = false;
				function digitMap(e) {
					final result = matchedOne ? "" : "LANE";
					matchedOne = true;
					return result;
				}
				grabName = digitRegex.map(grabName, digitMap);
			}
			if (!defaultRedirects.exists(grabName)) {
				if (!silent)
					Sys.println('UNABLE TO FIND MODIFIER: $name (grabbing "$grabName" and failed)');
				return null;
			}

			var staticRedirect = defaultRedirects.get(grabName);
			var instance = getInstance(staticRedirect.toClass);

			if (staticRedirect.lane < 0) {
				redirects.set(name, {
					toInstance: instance,
					index: staticRedirect.index,
					lane: -1
				});
			}
		}
		return redirects[name];
	}

	function addMod(mod:BaseModifier) {
		// fuck it, only sort 1 thingy
		var i = allMods.length;
		while (i > 0 && allMods[i - 1].priority > mod.priority)
			--i;
		allMods.insert(i, mod);
		return mod;
	}

	public function addStrumlineSets(amount:Int) {
		strumlineCount += amount;

		for (mod in allMods) {
			while (mod.active.length < strumlineCount)
				mod.addStrumlineSet();
		}
		for (aux in allAuxes) {
			while (aux.active.length < strumlineCount)
				aux.addStrumlineSet();
		}
		for (node in nodes) {
			for (input in node.inputs) {
				while (input.toInstance.active.length < strumlineCount)
					input.toInstance.addStrumlineSet();
			}
		}
	}
	public function addLanes(amount:Int) {
		laneCount += amount;
		for (mod in allMods) {
			for (i in 0...amount)
				mod.addLane();
		}
	}

	public function get(name:String, ?strumline:Int = 0) {
		name = name.toLowerCase();
		strumline = strumline < 0 ? 0 : strumline;
		var redirect = getRedirect(name);
		if (redirect == null) return 0.0;

		final ogLane = curLane;
		curLane = redirect.lane;
		final result = redirect.toInstance.getValue(redirect.index, strumline);
		curLane = ogLane; // reset it since some mods use .get
		return result;
	}

	public function setNow(name:String, value:Float, ?strumline:Int = -1) {
		name = name.toLowerCase();
		var redirect = getRedirect(name);
		if (redirect == null) return;

		final ogLane = curLane;
		curLane = redirect.lane;
		redirect.toInstance.setValue(redirect.index, value, strumline);
		curLane = ogLane; // less likely but why not
	}

	public function setAt(beat:Float, name:String, value:Float, ?strumline:Int = -1) {
		name = name.toLowerCase();
		var redirect = getRedirect(name);
		if (redirect == null) return;

		var event = new ModEvent(beat, 0, redirect, value, null, strumline);
		timeline.add(event);
	}

	public function setMultiAt(beat:Float, values:Dynamic, ?strumline:Int = -1) {
		if (!Reflect.isObject(values)) return;
		var valFields = Reflect.fields(values);

		for (val in valFields) {
			var endVal:Dynamic = Reflect.field(values, val);
			if (endVal is Float)
				setAt(beat, val, cast endVal, strumline);
		}
	}

	public function easeNow(length:Float, name:String, value:Float, ?ease:Float->Float, ?strumline:Int = -1, ?startVal: Float) { // why not
		name = name.toLowerCase();
		var redirect = getRedirect(name);
		if (redirect == null) return;
		
		var event = new ModEvent(Conductor.beat, length, redirect, value, ease, strumline, startVal);
		event.start();
		timeline.running.push(event);
	}

	public function easeAt(beat:Float, length:Float, name:String, value:Float, ?ease:Float->Float, ?strumline:Int = -1, ?startVal: Float) {
		name = name.toLowerCase();
		var redirect = getRedirect(name);
		if (redirect == null) return;

		var event = new ModEvent(beat, length, redirect, value, ease, strumline, startVal);
		timeline.add(event);
	}

	public function easeMultiAt(beat:Float, length:Float, values:Dynamic, ?ease:Float->Float, ?strumline:Int = -1, ?startVals:Dynamic) {
		if (!Reflect.isObject(values)) return;
		var valFields = Reflect.fields(values);
		var startFields = (startVals != null && Reflect.isObject(startVals)) ? Reflect.fields(startVals) : [];

		for (val in valFields) {
			var endVal:Dynamic = Reflect.field(values, val);
			if (!(endVal is Float)) continue;

			var startValDyn:Dynamic = (startFields.contains(val)) ? Reflect.field(startVals, val) : null;
			easeAt(beat, length, val, cast endVal, ease, strumline, (startValDyn is Float ? cast(startValDyn, Float) : null));
		}
	}

	public function oneshotFuncAt(beat:Float, func:Float -> Float -> Void) {
		var event = new FuncEvent(beat, 0, func, null);
		timeline.add(event);
	}

	public function continuousFuncAt(beat:Float, length:Float, func:Float -> Float -> Void) {
		var event = new FuncEvent(beat, length, func, FlxEase.linear);
		timeline.add(event);
	}

	public function easedFuncAt(beat:Float, length:Float, func:Float -> Float -> Void, ?ease:Float -> Float, ?startVal:Float, ?endVal:Float) {
		var event = new FuncEvent(beat, length, func, ease, startVal, endVal);
		timeline.add(event);
	}


	public function makeAux(name:String, ?defaultValue:Float = 0) {
		name = name.toLowerCase();
		var toReplace = getRedirect(name, true);
		if (toReplace != null) {
			if (toReplace.toInstance is AuxModifier)
				return toReplace; // no need to make a new aux

			replacedRedirects.set(name, toReplace);
		}

		var auxMod = new AuxModifier(this, defaultValue);
		allAuxes.push(auxMod);

		var aux:ModRedirect = {toInstance: auxMod, index: 0, lane: -1};
		redirects.set(name, aux);
		return aux;
	}

	public function makeNode(inputs:Array<String>, func:NodeFunc, ?outputs:Array<String>) {
		var nodeInputs:Array<ModRedirect> = [];
		var nodeOutputs:Array<ModRedirect> = [];

		if (outputs != null) {
			for (output in outputs) {
				output = output.toLowerCase();
				if (replacedRedirects.exists(output))
					nodeOutputs.push(replacedRedirects[output]);
				else
					nodeOutputs.push(getRedirect(output));
			}
		}

		for (input in inputs) {
			input = input.toLowerCase();
			var redirect = getRedirect(input, true);
			if (!Std.isOfType(redirect.toInstance, AuxModifier)) {
				replacedRedirects.set(input, redirect);
				redirect = {toInstance: new AuxModifier(this, 0), index: 0, lane: -1};
				redirects.set(input, redirect);
			}
			nodeInputs.push(redirect);
		}

		nodes.push({
			inputs: nodeInputs,
			func: func,
			outputs: nodeOutputs
		});
	}


	public function getLongHolds(from:Int) {
		curField = from; // this is how the special getter knows which field to grab from
		return config.longHolds;
	}

	public function update() {
		
		for (mod in allMods)
			mod.releaseCache();
		for (aux in allAuxes)
			aux.releaseCache();
		
		timeline.update();

		for (mod in allMods) {
			//mod.emptyPreparations();
			mod.startCache();
		}
		for (aux in allAuxes) {
			//aux.emptyPreparations();
			aux.startCache();
		}

		for (node in nodes) {
			for (strumline in 0...strumlineCount) {
				var inputs = [];
				var canRun = false;

				for (input in node.inputs) {
					canRun = canRun || input.toInstance.active[strumline];
					curLane = input.lane;
					inputs.push(input.toInstance.getValue(input.index, strumline));
				}

				if (!canRun) continue;

				try {
					var outputs = node.func(inputs, strumline);
					for (i in 0...(outputs != null ? outputs.length : 0)) {
						var nodeOutput = node.outputs[i];
						if (nodeOutput == null) continue;

						curLane = nodeOutput.lane;
						var curValue = nodeOutput.toInstance.getValue(nodeOutput.index, strumline);
						nodeOutput.toInstance.setValue(nodeOutput.index, curValue + outputs[i], strumline);
					}
				} catch(e:haxe.Exception) {
					trace('node (inputs = ${inputs}, outputs = ${node.outputs}) error, ${e.message}');
				}
			}
		}
	}


	public function prepare() {
		for (strumline in 0...strumlineCount) {
			curField = strumline;

			for (mod in allMods) {
				if (!mod.active[strumline]) continue;
				mod.prepare(strumline, Conductor.beat);
			}
		}
	}

	public function adjustDistance(sprite:FlxSprite, distance:Float, lane:Int, strumline:Int, field:Strumline, type:ObjectType): Float {
		var newDistance:Float = distance;
		for (mod in allMods) {
			if (!mod.active[strumline] || !mod.modifiesDistance(strumline)) continue;
			newDistance = mod.adjustDistance(sprite, newDistance, distance, Conductor.beat, lane, strumline, field, type);
		}
		return newDistance;
	}

	public function adjustPos(sprite:FlxSprite, pos:Vector3, distance:Float, unadjustedDistance:Float, lane:Int, strumline:Int, field:Strumline, type:ObjectType) {
		for (mod in allMods) {
			if (!mod.active[strumline] || !mod.modifiesPosition(strumline)) continue;
			mod.adjustPos(sprite, pos, distance, unadjustedDistance, Conductor.beat, lane, strumline, field, type);
		}
	}
	public function adjustScale(sprite:FlxSprite, scale:FlxPoint, distance:Float, lane:Int, strumline:Int, field:Strumline, type:ObjectType) {
		for (mod in allMods) {
			if (!mod.active[strumline] || !mod.modifiesScale(strumline)) continue;
			mod.adjustScale(sprite, scale, distance, Conductor.beat, lane, strumline, field, type);
		}
	}
	public function adjustVertex(sprite:FlxSprite, vertex:Vector3, pos:Vector3, distance:Float, unadjustedDistance:Float, lane:Int, strumline:Int, field:Strumline, type:ObjectType) {
		for (mod in allMods) {
			if (!mod.active[strumline] || !mod.modifiesVertex(strumline)) continue;
			mod.adjustVertex(sprite, vertex, pos, distance, unadjustedDistance, Conductor.beat, lane, strumline, field, type);
		}
	}
	public function getStealth(sprite:FlxSprite, distance:Float, unadjustedDistance:Float, pos:Vector3, lane:Int, strumline:Int, field:Strumline, type:ObjectType) {
		var stealth:Float = 0;
		for (mod in allMods) {
			if (!mod.active[strumline] || !mod.modifiesStealth(strumline)) continue;
			stealth = mod.getStealth(sprite, stealth, distance, unadjustedDistance, pos, Conductor.beat, lane, strumline, field, type);
		}
		return stealth;
	}

	public function pushDraw(player:Int, strumline:Strumline, cameras:Array<FlxCamera>, scroll:FlxPoint, frame:FlxFrame, vertices:Array<Vector3>, transform:ColorTransform, blend:BlendMode, antialiasing:Bool, quantization:Bool, stealth:Float, layer:Float, isStrum:Bool = false) {
		final halfWidth = FlxG.width * 0.5;
		final halfHeight = FlxG.height * 0.5;

		// TODO: Move this into the stealth modifier so we can add hidesuddenglow and hidehiddenglow from nITG
		var stealthAlpha:Float = 1;
		if (!isStrum && config.hideStealthGlow == 1 || isStrum && config.hideDarkGlow == 1) {
			stealthAlpha = 1 - stealth;
			stealth = 0;
		}

		for (proxy in proxies) {
			if (proxy.targetIdx != player || !proxy.visible || proxy.alpha <= 0.0) continue;

			final verts:Array<Float> = [];
			for (vert in vertices) {
				verts.push((vert.x - halfWidth) * proxy.scaleX + halfWidth + proxy.x);
				verts.push((vert.y - halfHeight) * proxy.scaleY + halfHeight + proxy.y);
			}

			queuedDraws.push({
				layer: layer + proxy.layer,

				quantization: quantization,
				blend: blend,
				antialiasing: antialiasing,

				scrollX: scroll.x * proxy.scrollX,
				scrollY: scroll.y * proxy.scrollY,

				cameras: (proxy._cameras == null || proxy._cameras.length == 0) ? cameras : proxy._cameras,
				frame: frame,
				verts: verts,

				red: transform.redMultiplier,
				green: transform.greenMultiplier,
				blue: transform.blueMultiplier,
				alpha: transform.alphaMultiplier * proxy.alpha * stealthAlpha,
				stealth: stealth,
				stealthGR: stealthColor.x,
				stealthGG: stealthColor.y,
				stealthGB: stealthColor.z
			});
		}

		if (strumline.modchartAlpha <= 0.0) return;

		final verts:Array<Float> = [];
		for (vert in vertices) {
			verts.push(vert.x + strumline.modchartX);
			verts.push(vert.y + strumline.modchartY);
		}

		queuedDraws.push({
			layer: layer,

			quantization: quantization,
			blend: blend,
			antialiasing: antialiasing,

			scrollX: scroll.x,
			scrollY: scroll.y,

			cameras: cameras,
			frame: frame,
			verts: verts,

			red: transform.redMultiplier,
			green: transform.greenMultiplier,
			blue: transform.blueMultiplier,
			alpha: transform.alphaMultiplier * strumline.modchartAlpha * stealthAlpha,
			stealth: stealth,
			stealthGR: stealthColor.x,
			stealthGG: stealthColor.y,
			stealthGB: stealthColor.z
		});
	}

	var drawnOnce = false;
	public function drawQueues() {
		if (!drawnOnce) // no need to sort if its already been sorted
			queuedDraws.sort(sortQueues);

		for (queue in queuedDraws) {
			for (camera in queue.cameras) {
				var camX = camera.scroll.x * queue.scrollX;
				var camY = camera.scroll.y * queue.scrollY;
				for (i in 0...4) {
					queue.verts[i * 2] = queue.verts[i * 2] - camX;
					queue.verts[i * 2 + 1] = queue.verts[i * 2 + 1] - camY;
				}

				var minX = Math.min(Math.min(queue.verts[0], queue.verts[2]), Math.min(queue.verts[4], queue.verts[6]));
				var maxX = Math.max(Math.max(queue.verts[0], queue.verts[2]), Math.max(queue.verts[4], queue.verts[6]));
				var minY = Math.min(Math.min(queue.verts[1], queue.verts[3]), Math.min(queue.verts[5], queue.verts[7]));
				var maxY = Math.max(Math.max(queue.verts[1], queue.verts[3]), Math.max(queue.verts[5], queue.verts[7]));

				if (minX <= camera.viewMarginRight && maxX >= camera.viewMarginLeft && minY <= camera.viewMarginBottom && maxY >= camera.viewMarginTop) {
					stealthColor.set(queue.stealthGR, queue.stealthGG, queue.stealthGB);
					drawColor.setMultipliers(queue.red, queue.green, queue.blue, 1);
					camera.drawNoteVertices(queue.frame, queue.verts, drawColor, queue.blend, queue.antialiasing, queue.quantization, queue.stealth, queue.alpha, stealthColor);
				}

				for (i in 0...4) {
					queue.verts[i * 2] = queue.verts[i * 2] + camX;
					queue.verts[i * 2 + 1] = queue.verts[i * 2 + 1] + camY;
				}
			}
		}
		drawnOnce = true;
	}

	public function killAllQueues() {
		if (queuedDraws != null)
			queuedDraws.resize(0);
		drawnOnce = false;
	}

	function sortQueues(a:QueuedDraw, b:QueuedDraw) {
		return a.layer < b.layer ? -1 : (a.layer > b.layer ? 1 : 0); // idk if this is much diff from the old one bbut idc!!!
	}

	// dw too much about this
	public static function setupRedirects() {
		for (modifier in modifiersToAttach) {
			final func = Reflect.field(modifier, "attachToRedirects");
			if (func != null)
				Reflect.callMethod(null, func, []);
		}
	}
}
#end