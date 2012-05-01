package com.lbineau.navigator;
import nme.events.Event;
import com.lbineau.utils.ObjectHash;

/**
 * ...
 * @author lbineau
 */

class NavigatorEvent extends Event {
	inline public static var TRANSITION_STATUS_UPDATED : String = "TRANSITION_STATUS_UPDATED";
	inline public static var STATE_REQUESTED : String = "STATE_REQUESTED";
	inline public static var STATE_CHANGED : String = "STATE_CHANGED";
	inline public static var TRANSITION_STARTED : String = "TRANSITION_STARTED";
	inline public static var TRANSITION_FINISHED : String = "TRANSITION_FINISHED";
	//
	// public properties:
	public var statusByResponder : ObjectHash<Dynamic,Dynamic>;
	public var state : NavigationState;

	public function new(type : String, ?statusByResponder:ObjectHash<Dynamic,Dynamic>) {
		super(type, false);
		this.statusByResponder = statusByResponder;
	}

	override public function toString() : String {
		return Type.getClassName(NavigatorEvent);
	}
}