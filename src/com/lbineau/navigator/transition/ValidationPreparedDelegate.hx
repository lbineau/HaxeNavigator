package com.lbineau.navigator.transition;
import com.lbineau.navigator.behaviors.IHasStateValidation;
import com.lbineau.navigator.behaviors.IHasStateValidationAsync;
import com.lbineau.navigator.NavigationState;
import com.lbineau.navigator.Navigator;

/**
 * ...
 * @author lbineau
 */

class ValidationPreparedDelegate {
	private var _navigator : Navigator;
	private var _validator : IHasStateValidationAsync;
	private var _truncated : NavigationState;
	private var _full : NavigationState;

	public function new(validator : IHasStateValidation, truncated : NavigationState, full : NavigationState, navigator : Navigator) {
		_validator = cast(validator,IHasStateValidationAsync);
		_truncated = truncated;
		_full = full;
		_navigator = navigator;
	}

	/**
	 * The reason this method has rest parameter, is because
	 * then you can either call it by using call() or bind it
	 * to an event handler that will send an event argument.
	 * 
	 * The arguments are ignored.
	 */
	public function call(?ignoreParameters : Array<Dynamic>) : Void {
		_navigator.notifyValidationPrepared(_validator, _truncated, _full);
		_validator = null;
		_truncated = null;
		_full = null;
		_navigator = null;
	}
}