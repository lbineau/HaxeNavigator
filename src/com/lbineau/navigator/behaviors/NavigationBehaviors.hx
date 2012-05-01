package com.lbineau.navigator.behaviors;

/**
 * ...
 * @author lbineau
 */

class NavigationBehaviors {
	/**
	 * Will show when the state matches, will hide when it doesn't
	 */
	inline public static var SHOW : String = "show";
	/** 
	 * Will hide when the state matches, even if it has a show on a higher level
	 */
	inline public static var HIDE : String = "hide";
	/** 
	 * Will update before any show method gets called
	 */
	inline public static var UPDATE : String = "update";
	/** 
	 * Will swap out and in, when the state is changed
	 */
	inline public static var SWAP : String = "swap";
	/** 
	 * Will ask for validation of the state, if a state can't be validated, it is denied
	 */
	inline public static var VALIDATE : String = "validate";
	/** 
	 * Will try to add all behaviors, based on the interface of the responder
	 */
	inline public static var AUTO : String = "auto";
	/**
	 * Used for looping through when the AUTO behavior is used.
	 */
	inline public static var ALL_AUTO : Array<String> = [SHOW, UPDATE, SWAP, VALIDATE];
}