package com.lbineau.navigator.behaviors;
import com.lbineau.navigator.NavigationState;
/**
 * ...
 * @author lbineau
 * Note that this interface extends IHasStateValidation.
 */

interface IHasStateRedirection implements IHasStateValidation
{
	/**
	 * This forms a pair with the validate() method of the super interface.
	 * Any responder that implements this interface and returns `false` for validate() call, will 
	 * get the opportunity to redirect the navigation request to another state.
	 * 
	 * If you do not want to redirect, just return the full argument.
	 * 
	 * Pseudo code example:
	 * 
	 *  Consider a responder added to `/account/` and the state `/account/profile/` being requested.
	 * 
	 *  function validate(...) {
	 *  	return truncated.firstSegment != "profile";
	 *  }
	 *  
	 *  The validate method will return false and redirect will be called: 
	 *  
	 *  function redirect(...) {
	 *  	return new NavigationState("account/login");
	 *  }
	 *  
	 */
	function redirect(truncated : NavigationState, full : NavigationState) : NavigationState;
}