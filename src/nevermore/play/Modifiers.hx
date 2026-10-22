package nevermore.play;

@:structInit
@:publicFields
class Modifiers {
	#if !NEVERMORE_NO_MODIFIERS

	var sustains:Bool = true;
	var scrollVelocities:Bool = true;
	var randomizedNotes:Bool = false;
	var mirroredNotes:Bool = false;

	#else

	var sustains:Bool = true;
	var scrollVelocities:Bool = false;
	var randomizedNotes:Bool = false;
	var mirroredNotes:Bool = false;
	
	#end
}