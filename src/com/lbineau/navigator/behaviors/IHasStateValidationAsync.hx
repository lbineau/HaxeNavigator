package com.lbineau.navigator.behaviors;
import com.lbineau.navigator.NavigationState;
/**
 * ...
 * @author lbineau
 */

 interface IHasStateValidationAsync implements IHasStateValidation {
	/**
	 * This method is called instead of the regular validate() method, when a new state gets requested.
	 * The navigator will wait for the inCallOnPrepared function call to actually execute validate().
	 * This may happen instantly, or asynchronously.
	 * 
	 * Typically, you would store your validation data in a kind of model, which your validate() method can
	 * poll when actually validating the data.
	 */
	function prepareValidation(truncated : NavigationState, full : NavigationState, callOnPrepared:Dynamic):Void;
}