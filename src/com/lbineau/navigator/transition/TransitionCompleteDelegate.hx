package com.lbineau.navigator.transition;
import com.lbineau.navigator.behaviors.INavigationResponder;
import com.lbineau.navigator.Navigator;
import nme.errors.Error;

/**
 * ...
 * @author lbineau
 */

class TransitionCompleteDelegate {
	private var _navigator : Navigator;
	private var _behavior : String;
	private var _status : Int;
	private var _responder : INavigationResponder;
	private var _called : Bool;

	public function new(responder : INavigationResponder, status : Int, behavior:String, navigator : Navigator) {
		_responder = responder;
		_status = status;
		_behavior = behavior;
		_navigator = navigator;
	}

	/**
	 * The reason this method has rest parameter, is because
	 * then you can either call it by using call() or bind it
	 * to an event handler that will send an event argument.
	 * 
	 * The arguments are ignored.
	 */
	public function call(?ignoreParameters:Array<Dynamic>) : Void {
		if (_called) throw new Error("Illegal second call to transition complete. This instance is already prepared for garbage collection!");
		
		_called = true;
		_navigator.notifyComplete(_responder, _status, _behavior);
		_responder = null;
		_navigator = null;
	}
}