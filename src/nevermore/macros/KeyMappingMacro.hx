package nevermore.macros;

import haxe.macro.Context;

class KeyMappingMacro {
	public static macro function mapFields(fieldClass:String, func:String, invert:Bool) {
		var type = Context.getType(fieldClass);
		var fields:Array<String> = [];

		switch (Context.follow(type)) {
			case TAbstract(cls, _):
				for (field in cls.get().impl.get().statics.get()) {
					switch (field.kind) {
						case FVar(_, __):
							fields.push(field.name);
						default: // nothin
					}
				}
			default: // nothin
		}

		var splitCls = fieldClass.split(".");
		var splitFunc = func.split(".");
		return macro $a{invert ?
			fields.map((field) -> macro $p{splitFunc}($p{splitCls}.$field) => $p{splitCls}.$field) :
			fields.map((field) -> macro $p{splitCls}.$field => $p{splitFunc}($p{splitCls}.$field))
		};
	}
}