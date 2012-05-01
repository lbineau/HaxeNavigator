package com.lbineau.navigator.features.history;
import com.lbineau.navigator.INavigator;
import com.lbineau.navigator.NavigationState;
import com.lbineau.navigator.NavigatorEvent;
/**
 * ...
 * @author lbineau
 * Provides history management for the Navigator package. 
 *
 * @example 
 * 	<code>
 * 		
 * 		// Create the normal navigator
 * 		var myNavigator : Navigator = new Navigator();
 * 		
 * 		// Create the history and supply the navigator it should manage
 * 		var myHistory : NavigatorHistory = new NavigatorHistory(myNavigator);
 * 		
 * 		-----
 * 		
 * 		// Go back in time
 * 		myHistory.back();
 * 		
 * 	</code>
 * @created 20 okt 2010
 */
class NavigatorHistory {
	// Default max history length
	inline public static var MAX_HISTORY_LENGTH : Int = 100;
	// Navigation direction types
	inline public static var DIRECTION_BACK : Int = -1;
	inline public static var DIRECTION_NORMAL : Int = 0;
	inline public static var DIRECTION_FORWARD : Int = 1;
	//
	// The navigator it is controlling
	private var _navigator : INavigator;
	// The history, last state is at start of Array
	private var _history(default,null) : Array<Dynamic>;
	// The current position in history
	private var _historyPosition : Int;
	// The navigator doesn't know anything about going forward or back.
	// Therefore, we need to keep track of the direction.
	// This is changed when the forward or back methods are called.
	private var _navigationDirection(default, null) : Int;
	// The max number of history states
	private var _maxLength(default,default) : Int;

	/**
	 * Create the history manager. When navigating back and forword, the history is maintained. 
	 * It is truncated when navigating to a state naturally
	 * 
	 * @param navigator Navigator reference
	 */
	public function new(navigator : INavigator) {
		_navigator = navigator;
		_navigator.addEventListener(NavigatorEvent.STATE_CHANGED, handleStateChange);
		_navigationDirection = DIRECTION_NORMAL;
		_maxLength = MAX_HISTORY_LENGTH;
		_history = new Array();
		_historyPosition = 0;
	}

	/**
	 * Go back in the history and return that NavigationState
	 * 
	 * @param steps The number of steps to go back in history
	 * @return The found state or null if no state was found
	 */
	public function getPreviousState(steps : Int = 1) : NavigationState {
		if (_historyPosition == _history.length - 1) {
			return null;
		}

		var pos : Int = cast Math.min(_history.length - 1, _historyPosition + steps);
		return _history[pos];
	}

	/**
	 * Go forward in the history and return that NavigationState
	 * 
	 * @param steps The number of steps to go back in history
	 * @return The found state or null if no state was found
	 */
	public function getNextState(steps : Int = 1) : NavigationState {
		if (_historyPosition == 0) {
			return null;
		}

		var pos : Int = cast Math.max(0, _historyPosition - steps);
		return _history[pos];
	}

	/**
	 * Clear up navigation history
	 */
	public function clearHistory() : Void {
		_history = new Array();
		_historyPosition = 1;
	}

	/**
	 * Go back in the history
	 * 
	 * @param steps The number of steps to go back in history
	 * @return Returns false if there was no previous state
	 */
	public function back(steps : Int = 1) : Bool{
		if (_historyPosition == _history.length - 1) {
			return false;
		}
		_historyPosition = cast Math.min(_history.length - 1, _historyPosition + steps);
		_navigationDirection = Reflect.field(NavigatorHistory,"DIRECTION_BACK");
		navigateToCurrentHistoryPosition();
		return true;
	}

	/**
	 * Go forward in the history
	 * 
	 * @param steps The number of steps to go forward in history
	 * @return Returns false if there was no next state
	 */
	public function forward(steps : Int = 1) : Bool {
		if (_historyPosition == 0) {
			return false;
		}
		_historyPosition = cast Math.max(0, _historyPosition - steps);
		_navigationDirection = Reflect.field(NavigatorHistory,"DIRECTION_FORWARD");
		navigateToCurrentHistoryPosition();
		return true;
	}

	/**
	 * Get the state by historyposition
	 * 
	 * @param position The position in history
	 * @return The found state or null if no state was found
	 */
	public function getStateByPosition(position : Int) : NavigationState {
		if (position < 0 || position > _history.length - 1) {
			return null;
		}
		return cast(_history[position], NavigationState);
	}

	/**
	 * Get the first occurence of a state in the history
	 * 
	 * @param state The state in history
	 * @return The found position or -1 if no position was found
	 */
	public function getPositionByState(state : NavigationState) : Int {
		return Lambda.indexOf(_history,state);
	}

	/**
	 * Tell the navigator to go the current historyPosition
	 */
	private function navigateToCurrentHistoryPosition() : Void {
		var newState : NavigationState = _history[_historyPosition];
		_navigator.request(newState);
	}

	/**
	 * Check what to do with the new state
	 */
	private function handleStateChange(event : NavigatorEvent) : Void {
		var state : NavigationState = event.state;
		
		switch (_navigationDirection) {
			case Reflect.getProperty(NavigatorHistory,"DIRECTION_BACK"):
				_navigationDirection = Reflect.getProperty(NavigatorHistory,"DIRECTION_NORMAL");
			case Reflect.getProperty(NavigatorHistory,"DIRECTION_NORMAL"):
				// Strip every history state before current
				_history.splice(0, _historyPosition);
				// Add the state at the beginning of the history array
				_history.unshift(state);
				_historyPosition = 0;
				// Truncate the history to the max allowed items
				//_history.length = Math.min(_history.length, _maxLength); TODO
				_history.shift();
			case Reflect.getProperty(NavigatorHistory,"DIRECTION_FORWARD"):
				_navigationDirection = Reflect.getProperty(NavigatorHistory,"DIRECTION_NORMAL");
		}
	}
}