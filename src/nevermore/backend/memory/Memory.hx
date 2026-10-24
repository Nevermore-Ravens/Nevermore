package nevermore.backend.memory;

#if cpp
/**
 * Memory class to properly get accurate memory counts
 * for the program.
 * @author Leather128 (Haxe Bindings) - David Robert Nadeau (Original C Header)
 */
@:buildXml('
<pragma once="true" />
<set name="NEVERMORE_MEMORY_DIR" value="${haxelib:nevermore}/src/nevermore/backend/memory" />
<files id="haxe">
	<compilervalue name="-I" value="${NEVERMORE_MEMORY_DIR}" />
</files>
<files id="__main__">
	<compilervalue name="-I" value="${NEVERMORE_MEMORY_DIR}" />
</files>
<files id="memory">
	<compilervalue name="-I" value="${NEVERMORE_MEMORY_DIR}" />
	<file name="${NEVERMORE_MEMORY_DIR}/Memory.c" />
</files>
<target id="haxe">
    <files id="memory" />
</target>
')
@:include("Memory.h")
extern class Memory {
	/**
	 * Returns the peak (maximum so far) resident set size (physical
	 * memory use) measured in bytes, or zero if the value cannot be
	 * determined on this OS.
	 */
	@:native("getPeakRSS")
	public static function getPeakUsage():cpp.SizeT;

	/**
 	 * Returns the current resident set size (physical memory use) measured
 	 * in bytes, or zero if the value cannot be determined on this OS.
	 */
	@:native("getCurrentRSS")
	public static function getCurrentUsage():cpp.SizeT;
}
#else
/**
 * Hxcpp only
 * @author Leather128
 */
class Memory {
	/**
	 * Fallback
	 * Returns 0.
	 */
	public static function getPeakUsage():UInt return 0;

	/**
	 * Fallback
	 * Returns 0.
	 */
	public static function getCurrentUsage():UInt return 0;
}
#end