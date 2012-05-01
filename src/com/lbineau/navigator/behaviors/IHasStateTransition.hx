package com.lbineau.navigator.behaviors;

/**
 * ...
 * @author lbineau
 */

interface IHasStateTransition implements INavigationResponder {
	/**
	 * Called when the responder is needs to show itself.
	 * 
	 * Call @param inCallOnComplete when the transition is ready. This may be instant or asynchronous.
	 */
	function transitionIn(callOnComplete:Dynamic):Void;
	/**
	 * Called when the responder needs to hide itself.
	 * The transitionOut() is never called before a transitionIn().
	 * 
	 * Call @param inCallOnComplete when the transition is  ready. This may be instant or asynchronous.
	 */
	function transitionOut(callOnComplete:Dynamic):Void;
}