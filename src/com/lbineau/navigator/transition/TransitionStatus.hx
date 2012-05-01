package com.lbineau.navigator.transition;

/**
 * ...
 * @author lbineau
 */

class TransitionStatus 
{
	inline public static var UNINITIALIZED : Int = -2;
	inline public static var INITIALIZED : Int = -1;
	inline public static var HIDDEN : Int = 1;
	inline public static var APPEARING : Int = 2;
	inline public static var SHOWN : Int = 3;
	inline public static var SWAPPING : Int = 4;
	inline public static var DISAPPEARING : Int = 5;
	
	public static function toString(status:Int):String {
	switch (status) {
		case UNINITIALIZED:
			return "UNINITIALIZED";
		case INITIALIZED:
			return "INITIALIZED";
		case HIDDEN:
			return "HIDDEN";
		case APPEARING:
			return "APPEARING";
		case SHOWN:
			return "SHOWN";
		case SWAPPING:
			return "SWAPPING";
		case DISAPPEARING:
			return "DISAPPEARING";
	}
	
	return "UNKNOWN";
}
	
}