package com.lbineau.navigator.behaviors;
import com.lbineau.navigator.NavigationState;
/**
 * ...
 * @author lbineau
 */

interface IHasStateSwap implements INavigationResponder {
	/**
	 * Transitions show or hide an entire object based on the state it's registered at.
	 * A Swap however, will keep the object visible and swap it's contents, when the willSwapAtState() method returns true.
	 * You should *not* assume that a willSwapAtState call is immediately followed by a swap call, because some validation may
	 * prevent the state from changing.
	 */
	function willSwapToState(truncated : NavigationState, full : NavigationState) : Bool;

	/**
	 * This method should perform the actual swap.
	 * The swap will wait for the inSwapComplete call before the swapIn is called.
	 */
	function swapOut(swapOutComplete : Dynamic) : Void;

	/**
	 * Called with full options.
	 * Swapping in has no completion callback.
	 */
	function swapIn(truncated : NavigationState, full:NavigationState) : Void;
}