package nevermore.modchart;

class ModchartConfig extends BaseModifier {
	public var spiralHolds:ModifierValue = 1;
	public var longHolds:ModifierValue = 0;
	public var straightHolds:ModifierValue = 0;
	public var gayHolds:ModifierValue = 0;

	public var orientOffset:ModifierValue = 0;
	public var orient:ModifierValue = 0;

	public var hideStealthGlow:ModifierValue = 0;
	public var hideDarkGlow:ModifierValue = 0;

	public var cosClip:ModifierValue = 0;
	public var sinClip:ModifierValue = 0;
	//public var cosecant:ModifierValue = 0; TODO: Add if/when we add tangent variants of modifiers

	// shitpost, dont use LMFAO
	public var extraStraightHolds:ModifierValue = 0;
}