package com.lbineau.navigator;
import nme.errors.Error;

/**
 * ...
 * @author lbineau
 * 
 * The NavigationState is the most important part of the Navigator system.
 * It is essentially a wrapper to substitute passing around a string for path comparisons.
 * Instead, you use this class and it will handle all the issues with slashes, letter case,
 * wildcards, path segments and comparison/manipulation of two states.
 * 
 *
 */
class NavigationState {
	inline public static var WILDCARD : String = "*";
	inline public static var DOUBLE_WILDCARD : String = WILDCARD + WILDCARD;
	inline public static var DELIMITER : String = "/";
	//
	public var path(getPath,setPath) : String;
	private var _path : String;

	public static function make(stateOrPath : Dynamic) : NavigationState {
		return Std.is(stateOrPath,NavigationState) ? stateOrPath : new NavigationState(stateOrPath);
	}

	/**
	 * @param ...inSegements: Pass the desired path segments as a list of arguments, or pass it all at once, as a ready-made path, it's up to you.
	 * 
	 * Examples:
	 * 
	 * 		new NavigationState("beginning/end");
	 * 		new NavigationState("beginning", "end");
	 */
	public function new(path : String = "") {
		//trace('init '+ segments.join("/"));
		this.setPath(path);
		//path = segments.join("/");
	}

	/**
	 * A path will always start and end with a slash /
	 * All double slashes // will be removed and white spaces are 
	 * replaced by dashes -.
	 */
	public function getPath() : String {
		return _path;
	}
	public function setPath(path : String) : String {
		_path = DELIMITER + path.toLowerCase() + DELIMITER;
		var regSlashes : EReg = ~/[\/\/]+/g;
		var regSpaces : EReg = ~/\s+/g;
		_path = regSlashes.replace(_path,"/");
		_path = regSpaces.replace(_path,"-");
		return _path;
	}
	/**
	 * Set the path as a list of segments (or path components).
	 * Example: ["a", "b", "c"] will result in a path /a/b/c/
	 */
	public function setSegments(segments : Array<Dynamic>) : Void {
		path = segments.join(DELIMITER);
	}

	/**
	 * Returns the path cut up in segments (or path components).
	 */
	public function getSegments() : Array<String> {
		var s : Array<String> = path.split(DELIMITER);
		// pop emtpy string off the back.
		if (s[s.length - 1] == null || s[s.length - 1] == "")
			s.pop();

		// shift empty string off the start.
		if (s[0] == null || s[0] == "")
			s.shift();

		return s;
	}

	public function getLength() : Int {
		return getSegments().length;
	}

	public function setLength(length : Int) : Void {
		if (length > getSegments().length) throw new Error("Can't extend the segment length by number, use segments = [...]");

		var s : Array<String> = getSegments();
		setSegments(s.slice(0, length));
	}

	/**
	 * Convenience method for not having to call segments[0] all the time.
	 */
	public function getFirstSegment() : String {
		return getSegments()[0];
	}

	/**
	 * Convenience method for not having to call segments[segments.length-1] all the time.
	 */
	public function getLastSegment() : String {
		var s : Array<String> = getSegments();
		return s[s.length - 1];
	}

	/**
	 * @return whether the path of the foreign state is contained by this state's path, wildcards may be used.
	 * @example:
	 * 
	 * 	a = new State("/bubble/gum/");
	 * 	b = new State("/bubble/");
	 * 	
	 * 	a.contains(b) will return true.
	 * 	b.contains(a) will return false.
	 * 	
	 */
	public function contains(foreignState : NavigationState) : Bool {
		var foreignSegments : Array<String> = foreignState.getSegments();
		var nativeSegments : Array<String> = getSegments();

		if (foreignSegments.length > nativeSegments.length) {
			// foreign segment length too big
			return false;
		}

		// check to see if the overlapping segments match.
		// since the foreign segment count has to be smaller than the native,
		// the foreign count is used to limit the loop:
		var leni : Int = foreignSegments.length;
		for (i in 0...leni) {
			var foreignSegment : String = foreignSegments[i];
			var nativeSegment : String = nativeSegments[i];

			if (foreignSegment == WILDCARD || nativeSegment == WILDCARD) {
				// mathes because of the wildcard.
			} else if (foreignSegment != nativeSegment) {
				// native [" + nativeSegment + "] does not match foreign [" + foreignSegment + "]
				return false;
			} else {
				// native  [" + nativeSegment + "] matches foreign [" + foreignSegment + "]
			}
		}

		return true;
	}

	/**
	 * Will test for equality between states. This comparison is wildcard safe!
	 * @example: 
	 * 		a/b/c equals a/b/*
	 */
	public function equals(state : NavigationState) : Bool {
		var sub : NavigationState = subtract(state);
		if (sub == null)
			return false;
		return sub.getSegments().length == 0;
	}

	/**
	 * Subtracts the path of the operand from the current state and returns it as a new state instance.
	 * Subtraction uses containment as the main method of comparison, therefore wildcard safe!
	 * @example
	 * 		/portfolio/editorial/84/3 - /portfolio/ = /editorial/84/3
	 * 		/portfolio/editorial/84/3 - * = /editorial/84/3
	 */
	public function subtract(operand : NavigationState) : NavigationState {
		if (!contains(operand))
			return null;

		var ns : NavigationState = new NavigationState();
		var subtract : Array<String> = getSegments();
		subtract.splice(0, operand.getSegments().length);
		ns.setSegments(subtract);
		return ns;
	}

	public function add(trailingStateOrPath : Dynamic) : NavigationState {
		return new NavigationState(path + "/" + make(trailingStateOrPath).path);
	}

	public function addSegments(trailingSegments : Array<Dynamic>) : NavigationState {
		var trailingState : NavigationState = new NavigationState();
		trailingState.setSegments(trailingSegments);
		return add(trailingState);
	}

	public function prefix(leadingStateOrPath : Dynamic) : NavigationState {
		return new NavigationState(make(leadingStateOrPath) + "/" + path);
	}

	public function hasWildcard() : Bool {
		return path.indexOf(WILDCARD) >= 0;
	}

	/**
	 * Will mask wildcards with values from the provided state.
	 */
	public function mask(source : NavigationState) : NavigationState {
		if (source == null)
			return clone();

		var unmaskedSegments : Array<String> = getSegments();
		var sourceSegments : Array<String> = source.getSegments();
		var leni : Int = cast(Math.min(sourceSegments.length, unmaskedSegments.length), Int);
		for (i in 0...leni) {
			if (unmaskedSegments[i] == NavigationState.WILDCARD && unmaskedSegments[i] == sourceSegments[i]) {
				unmaskedSegments[i] = sourceSegments[i];
			}
		}

		var masked : NavigationState = new NavigationState();
		masked.setSegments(unmaskedSegments);
		return masked;
	}

	public function clone() : NavigationState {
		return new NavigationState(path);
	}

	public function toString() : String {
		return path;
	}
}
