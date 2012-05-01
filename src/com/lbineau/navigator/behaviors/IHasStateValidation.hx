package com.lbineau.navigator.behaviors;
import com.lbineau.navigator.NavigationState;
/**
 * ...
 * @author lbineau
 */

interface IHasStateValidation implements INavigationResponder {
	/**
	 * Synchronous validation.
	 * Will provide the result of subtracting the registered state from the requested (inFull) state to give you the inTruncated state.
	 */
	function validate(truncated:NavigationState, full : NavigationState):Bool;
}