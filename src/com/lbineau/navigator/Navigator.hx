package com.lbineau.navigator;
import com.lbineau.navigator.transition.TransitionCompleteDelegate;
import com.lbineau.navigator.transition.ValidationPreparedDelegate;
import com.lbineau.utils.ObjectHash;
import com.lbineau.navigator.behaviors.IHasStateInitialization;
import com.lbineau.navigator.NavigatorEvent;
import com.lbineau.navigator.behaviors.IHasStateRedirection;
import com.lbineau.navigator.behaviors.IHasStateSwap;
import com.lbineau.navigator.behaviors.IHasStateTransition;
import com.lbineau.navigator.behaviors.IHasStateUpdate;
import com.lbineau.navigator.behaviors.IHasStateValidation;
import com.lbineau.navigator.behaviors.IHasStateValidationAsync;
import com.lbineau.navigator.behaviors.IHasStateValidationOptional;
import com.lbineau.navigator.behaviors.INavigationResponder;
import com.lbineau.navigator.behaviors.NavigationBehaviors;
import nme.errors.Error;
import nme.events.EventDispatcher;
import nme.events.IEventDispatcher;
import com.lbineau.navigator.transition.TransitionStatus;
/**
 * ...
 * @author lbineau
 */

class Navigator extends EventDispatcher, implements INavigator {

	private static var INSTANCE_COUNT : Int = 0;
	private var _current : NavigationState;
	private var _previous : NavigationState;
	private var _defaultState : NavigationState;
	private var _isTransitioning(default,null) : Bool;
	//
	private var _responders : ResponderLists;
	public var _statusByResponder(default,null) : ObjectHash<Dynamic,Dynamic>;
	private var _redirects : ObjectHash<Dynamic,Dynamic>;
	private var _disappearing : AsynchResponders;
	private var _appearing : AsynchResponders;
	private var _swapping : AsynchResponders;
	private var _validating : AsynchResponders;
	private var _inlineRedirection : NavigationState;
	//
	private var _asyncInvalidated : Bool;
	private var _asyncValidated : Bool;
	private var _asyncValidationOccurred : Bool;
	
	public function new(?target:IEventDispatcher) 
	{
		super(target);
		INSTANCE_COUNT++;
		trace("Navigator " + INSTANCE_COUNT + " constructed");

		_responders = new ResponderLists();
		_statusByResponder = new ObjectHash<INavigationResponder,Int>();
	}
		
	public function add(responder:INavigationResponder, pathsOrStates:Dynamic, ?behavior:String):Void 
	{
		modify(true, responder, pathsOrStates, behavior);
	}
	
	public function remove(responder:INavigationResponder, pathsOrStates:Dynamic, ?behavior:String):Void 
	{
		modify(false, responder, pathsOrStates, behavior);
	}
	
	public function registerRedirect(fromStateOrPath:Dynamic, toStateOrPath:Dynamic):Void 
	{
		if(_redirects == null) _redirects = new ObjectHash<Dynamic,Dynamic>(); // attention orginal : _redirects ||= new Dictionary();
		_redirects.set(NavigationState.make(fromStateOrPath).path, NavigationState.make(toStateOrPath));
	}
	
	public function start(defaultStateOrPath:Dynamic = "", ?startStateOrPath:Dynamic):Void 
	{
		_defaultState = NavigationState.make(defaultStateOrPath);
		request(startStateOrPath != null ? startStateOrPath : _defaultState);
	}
	
	public function request(stateOrPath:Dynamic):Void 
	{
		if (stateOrPath == null) {
			trace("Requested a null state. Aborting request.");
			return;
		}

		// Store and possibly mask the requested state
		var requested : NavigationState = NavigationState.make(stateOrPath);

		if (requested.hasWildcard()) {
			requested = requested.mask(_current != null ? _current : _defaultState);
		}

		// Check for exact match of the requested and the current state
		if (_current != null && _current.path == requested.path) {
			trace("Already at the requested state: " + requested);
			return;
		}

		if (_redirects != null) {
			for (path in _redirects) {
				var from : NavigationState = new NavigationState(path);
				if (from.equals(requested)) {
					var to : NavigationState = cast (_redirects.get(path),NavigationState);
					trace("Redirecting " + from + " to " + to);
					request(to);
					return;
				}
			}
		}

		// this event makes it possible to add responders just in time to participate in the validation process.
		var ne : NavigatorEvent = new NavigatorEvent(NavigatorEvent.STATE_REQUESTED);
		ne.state = requested;
		dispatchEvent(ne);

		// Inline redirection is reset with every request call.
		// It can be changed by a responder implementing the IHasStateRedirection interface.
		_inlineRedirection = null;

		performRequestCascade(requested);
	}
	public function getCurrentState() : NavigationState {
		// not returning the _current instance to prevent possible reference conflicts.
		if (_current == null) {
			if (_defaultState != null)
				return _defaultState.clone();

			return null;
		}

		return _current.clone();
	}
	

	private function modify(addition : Bool, responder : INavigationResponder, pathsOrStates : Dynamic, ?behavior : String) : Void {
		if (relayModification(addition, responder, pathsOrStates, behavior)) return;
		// Using the path variable as dictionary key to break instance referencing.
		var path : String = NavigationState.make(pathsOrStates).path;
		//trace("path " + path + " -> responder " + responder + " -> behavior " + behavior);
		var list : Array<Dynamic>;
		var matchingInterface : Class<Dynamic>;

		// Create, store and retrieve the list that matches the desired behavior.
		switch(behavior) {
			case NavigationBehaviors.SHOW:
				matchingInterface = IHasStateTransition;
				if(_responders.showByPath.exists(path))
					list = _responders.showByPath.get(path);
				else {
					_responders.showByPath.set(path, []);
					list = _responders.showByPath.get(path);
				}

			case NavigationBehaviors.HIDE:
				matchingInterface = IHasStateTransition;
				if(_responders.hideByPath.exists(path))
					list = _responders.hideByPath.get(path);
				else {
					_responders.hideByPath.set(path, []);
					list = _responders.hideByPath.get(path);
				}

			case NavigationBehaviors.VALIDATE:
				matchingInterface = IHasStateValidation;
				if(_responders.validateByPath.exists(path))
					list = _responders.validateByPath.get(path);
				else {
					_responders.validateByPath.set(path, []);
					list = _responders.validateByPath.get(path);
				}
				
			case NavigationBehaviors.UPDATE:
				matchingInterface = IHasStateUpdate;
				if(_responders.updateByPath.exists(path))
					list = _responders.updateByPath.get(path);
				else {
					_responders.updateByPath.set(path, []);
					list = _responders.updateByPath.get(path);
				}
				
			case NavigationBehaviors.SWAP:
				matchingInterface = IHasStateSwap;
				if(_responders.swapByPath.exists(path))
					list = _responders.swapByPath.get(path);
				else {
					_responders.swapByPath.set(path, []);
					list = _responders.swapByPath.get(path);
				}
				
			default:
				throw new Error("Unknown behavior: " + behavior);
		}

		if (!(Std.is(responder,matchingInterface))) {
			throw new Error("Responder " + responder + " should implement " + matchingInterface + " to respond to " + behavior);
		}

		if (addition) {
			// add
			if (Lambda.indexOf(list, responder) < 0) {
				list.push(responder);

				// If the responder has no status yet, initialize it to UNINITIALIZED:
				if (_statusByResponder.get(responder) == null) _statusByResponder.set(responder, TransitionStatus.UNINITIALIZED);
			} else return;
		} else {
			// remove
			var index : Int = Lambda.indexOf(list, responder);
			if (index >= 0) {
				list.splice(index, 1);

				_statusByResponder.delete(responder);
			} else return;

			if (matchingInterface == IHasStateSwap && _responders.swappedBefore.get(responder)) {
				// cleanup after the special swap case
				_responders.swappedBefore.delete(responder);
			}
		}

		dispatchEvent(new NavigatorEvent(NavigatorEvent.TRANSITION_STATUS_UPDATED, _statusByResponder));
	}
	private function relayModification(addition : Bool, responder : INavigationResponder, pathsOrStates : Dynamic, ?behaviors : String) : Bool {
		if (responder == null)
			throw new Error("add: responder is null");

		if (Std.is(pathsOrStates,Array)) {
			for (pathOrState in cast(pathsOrStates,Array<Dynamic>)) {
				modify(addition, responder, pathOrState, behaviors);
			}
			return true;
		}

		if(behaviors == null) behaviors = NavigationBehaviors.AUTO;
		if (behaviors == NavigationBehaviors.AUTO) {
			for (behavior in NavigationBehaviors.ALL_AUTO) {
				try {
					modify(addition, responder, pathsOrStates, behavior);
				} catch(e : Error) {
					// ignore 'should implement xyz' errors
				}
			}
			return true;
		}

		return false;
	}
	private function performRequestCascade(requested : NavigationState, startAsyncValidation : Bool = true) : Void {
		if (_defaultState == null) throw new Error("No default state set. Call start() before the first request!");
		// Request cascade starts here.
		//
		if (requested.path == _defaultState.path && !_defaultState.hasWildcard()) {
			// Exact match on default state bypasses validation.
			grantRequest(_defaultState);
		} else if (_asyncValidationOccurred && (_asyncValidated && !_asyncInvalidated)) {
			// Async operation completed
			grantRequest(requested);
		} else if (validate(requested, true, startAsyncValidation)) {
			// HERE
			// Any other state needs to be validated.
			grantRequest(requested);
		} else if (_validating != null && _validating.isBusy()) {
			// Waiting for async validation.
			// FIXME: What do we do in the mean time, dispatch an event or sth?
			trace("waiting for async validation to complete");
		} else if (startAsyncValidation && _asyncValidationOccurred) {
			// any async prepration happened instantaneuously
		} else if (_inlineRedirection != null) {
			request(_inlineRedirection);
		} else if (_current != null) {
			// If validation fails, the notifyStateChange() is called with the current state as a parameter,
			// mainly for subclasses to respond to the blocked navigation (e.g. SWFAddress).
			notifyStateChange(_current);
		} else if (requested.hasWildcard()) {
			// If we get here, after validateWithWildcards has failed, this means there are still
			// wildcards in the requested state that didn't match the previous state. This,
			// unfortunately means your application has a logic error. Go fix it!
			throw new Error("Check wildcard masking: " + requested);
		} else if (_defaultState != null) {
			// If all else fails, we'll put up the default state.
			grantRequest(_defaultState);
		} else {
			// If you don't provide a default state, at least make sure your first request makes sense!
			throw new Error("First request is invalid: " + requested);
		}

	}
	/**
	 * FIXME: The notifyComplete logic is incorrect when two parallel transitions (e.g. both 'in') of the same responder report back with a non-chronological order. 
	 * This will not happen in regular use, but brute-force testing reveals it. The result is elements being visible when they shouldn't and vice versa.
	 */
	public function notifyComplete(responder : INavigationResponder, status : Int, behavior : String) : Void {
		if (_statusByResponder.get(responder)) {
			_statusByResponder.set(responder, status);
			dispatchEvent(new NavigatorEvent(NavigatorEvent.TRANSITION_STATUS_UPDATED, _statusByResponder));
		}

		var asynch : AsynchResponders;
		var method : Dynamic;

		switch(behavior) {
			case NavigationBehaviors.HIDE:
				asynch = _disappearing;
				method = performUpdates;

			case NavigationBehaviors.SHOW:
				asynch = _appearing;
				method = startSwapOut;

			case NavigationBehaviors.SWAP:
				asynch = _swapping;
				method = swapIn;

			default:
				throw new Error("Don't know how to handle notification of behavior " + behavior);
		}

		// If the notifyComplete is called instantly, the array of asynchronous responders is not yet assigned, and therefore not busy.
		if (asynch.isBusy()) {
			asynch.takeOutResponder(responder);

			// isBusy counts the number of responders, so it might have changed after takeOutResponder().
			if (!asynch.isBusy()) {
				method();
			} else {
				trace("waiting for " + asynch.getLength() + " responders to " + behavior);
			}
		}
	}

	public function hasResponder(responder : INavigationResponder) : Bool {
		if (_statusByResponder.get(responder)) return true;

		for (respondersByPath in _responders.all) {
			for (existingResponders in respondersByPath) {
				if (Lambda.indexOf(existingResponders, responder) >= 0) return true;
			}
		}

		return false;
	}

	public function getStatusByResponder() : ObjectHash<Dynamic, Dynamic> {
		return _statusByResponder;
	}

	public function getStatus(responder : IHasStateTransition) : Int {
		return _statusByResponder.get(responder);
	}

	public function getKnownPaths() : Array<Dynamic> {
		var list : ObjectHash<Dynamic, Dynamic> = new ObjectHash<Dynamic, Dynamic>();
		list.set(_defaultState.path, true);

		var path : String;
		for (path in _responders.showByPath) {
			list.set(new NavigationState(path).path, true);
		}

		var known : Array<Dynamic> = [];
		for (path in list) {
			known.push(path);
		}

		//known.sort(); // TODO sort method
		return known;
	}

	private function grantRequest(state : NavigationState) : Void {

		_asyncInvalidated = false;
		_asyncValidated = false;
		_previous = _current;
		_current = state;

		notifyStateChange(_current);

		startTransition();
	}

	public function notifyStateChange(state : NavigationState) : Void {
		trace("Navigator.notifyStateChange "+state);

		// Do call the super.notifyStateChange() when overriding.
		if (state != _previous) {
			var ne : NavigatorEvent = new NavigatorEvent(NavigatorEvent.STATE_CHANGED, _statusByResponder);
			ne.state = getCurrentState();
			dispatchEvent(ne);
		}
	}

	public function notifyValidationPrepared(validator : IHasStateValidationAsync, truncated : NavigationState, full : NavigationState) : Void {
		// If the takeOutResponder() method returns false, it was not in the responder list to begin with.
		// This happens if a second navigation state is requested before the async validation preparation of the first completes.
		if (_validating.takeOutResponder(validator)) {
			if (validator.validate(truncated, full)) {
				_asyncValidated = true;
			} else {
				trace("Asynchronously invalidated by " + validator);
				_asyncInvalidated = true;

				if (Std.is(validator, IHasStateRedirection)) {
					_inlineRedirection = cast(validator,IHasStateRedirection).redirect(truncated, full);
				}
			}

			if (!_validating.isBusy()) {
				performRequestCascade(full, false);
			} else {
				trace("Waiting for " + _validating.getLength() + " validators to prepare");
			}
		} else {
			// ignore async preparations of former requests.
		}
	}

	/**
	 * Validation is done in two steps.
	 * 
	 * Firstly, the @param inNavigationState is checked against all registered
	 * state paths in the _responders.showByPath list. If that already results in a
	 * valid path, it will grant the request.
	 * 
	 * Secondly, if not already granted, it will continue to look for existing validators in the _responders.validateByPath.
	 * If found, will call those and have the grant rely on the external validators.
	 */
	public function validate(stateToValidate : NavigationState, allowRedirection : Bool = true, allowAsyncValidation : Bool = true) : Bool {
		var unvalidatedState : NavigationState = stateToValidate;
		// check to see if there are still wildcards left
		if (unvalidatedState.hasWildcard()) {
			// throw new Error("validateState: Requested states may not contain wildcards " + NavigationState.WILDCARD);
			return false;
		}

		if (unvalidatedState.equals(_defaultState)) {
			return true;
		}

		if (allowAsyncValidation) {
			// This conditional is only true if we enter the validation the first (synchronous) time.
			_asyncValidationOccurred = false;
			_asyncInvalidated = false;
			_asyncValidated = false;

			// reset asynchronous validation for every new state.
			_validating = new AsynchResponders();
		}
		var implicit : Bool = validateImplicitly(unvalidatedState);
		var invalidated : Bool = false;
		var validated : Bool = false;

		for (path in _responders.validateByPath) {
			// create a state object for comparison:
			var state : NavigationState = new NavigationState(path);

			if (unvalidatedState.contains(state)) {
				var remainder : NavigationState = unvalidatedState.subtract(state);

				// the lookup path is contained by the new state.
				var list : Array<Dynamic> = _responders.validateByPath.get(path);
				var responder : INavigationResponder;

				initializeIfNeccessary(list);

				if (allowAsyncValidation) {
					// check for async validators first. If this does not
					for (responder in list) {
						var asyncValidator : IHasStateValidationAsync = cast(responder, IHasStateValidationAsync);

						// check for optional validation
						if (Std.is(asyncValidator, IHasStateValidationOptional) && !cast(asyncValidator, IHasStateValidationOptional).willValidate(remainder, unvalidatedState)) {
							continue;
						}

						if (asyncValidator != null) {
							_asyncValidationOccurred = true;
							_validating.addResponder(asyncValidator);
							trace("Preparing validation (total of " + _validating.getLength() + ")");

							//use namespace validation;
							asyncValidator.prepareValidation(remainder, unvalidatedState, new ValidationPreparedDelegate(asyncValidator, remainder, unvalidatedState, this).call);
						}
					}

					if (_asyncValidationOccurred) {
						//						//  If there are active async validators, stop the validation chain and wait for the prepration to finish.
						// if (_validating.isBusy()) return false;
						// if (_asyncValidationOccurred && (_asyncValidated || _asyncInvalidated) {
						// async validation was instantaneous, which means that the validation was approved or denied elsewhere
						// in the stack. this method should return false any which way.
						return false;
					}
				}

				// check regular validators
				for (responder in list) {
					var validator : IHasStateValidation = cast(responder, IHasStateValidation);

					// skip async validators, we handled them a few lines back.
					if (Std.is(validator, IHasStateValidationAsync)) continue;

					// check for optional validation
					if (Std.is(validator, IHasStateValidationOptional) && !cast(validator, IHasStateValidationOptional).willValidate(remainder, unvalidatedState)) {
						continue;
					}

					if (validator.validate(remainder, unvalidatedState)) {
						validated = true;
					} else {
						trace("Invalidated by validator: " + validator);
						invalidated = true;

						if (allowRedirection && Std.is(validator, IHasStateRedirection)) {
							_inlineRedirection = cast(validator, IHasStateRedirection).redirect(remainder, unvalidatedState);
						}
					}
				}
			}
		}

		if (_validating.isBusy()) {
			// the request cascade will double check the asynch validators and act accordingly.
			return false;
		}

		// invalidation overrules any validation
		if (invalidated || _asyncInvalidated) {
			return false;
		}

		if (validated || _asyncValidated) {
			return true;
		}

		if (!implicit) {
			trace("Validation failed. No validators or transitions matched the requested " + unvalidatedState);
		}

		return implicit;
	}

	// Check hard wiring of states to transition responders in the show list.
	private function validateImplicitly(state : NavigationState) : Bool {	
		for (path in _responders.showByPath) {
			if (new NavigationState(path).equals(state)) {
				// info("Validation passed based on transition responder.");
				return true;
			}
		}

		return false;
	}

	public function startTransition() : Void {
		_isTransitioning = true;
		dispatchEvent(new NavigatorEvent(NavigatorEvent.TRANSITION_STARTED));

		_disappearing = new AsynchResponders();
		_disappearing.addResponders(transitionOut());

		if (!_disappearing.isBusy()) {
			performUpdates();
		}
	}

	public function transitionOut() : Array<Dynamic> {
		var toShow : Array<Dynamic> = getRespondersToShow();

		// This initialize call is to catch responders that were put on stage to show,
		// yet still need to wait for async out transitions before they actually transition in.
		initializeIfNeccessary(toShow);

		var waitFor : Array<Dynamic> = [];

		for (key in _statusByResponder) {
			var responder : IHasStateTransition = cast(key, IHasStateTransition);

			if (Lambda.indexOf(toShow, responder) < 0) {
				// if the responder is not already hidden or disappearing, trigger the transitionOut:
				if (TransitionStatus.HIDDEN < _statusByResponder.get(responder) && _statusByResponder.get(responder) < TransitionStatus.DISAPPEARING) {
					_statusByResponder.set(responder, TransitionStatus.DISAPPEARING);
					waitFor.push(responder);

					//use namespace transition;
					responder.transitionOut(new TransitionCompleteDelegate(responder, TransitionStatus.HIDDEN, NavigationBehaviors.HIDE, this).call);
				} else {
					// already hidden or hiding
				}
			}
		}

		// loop backwards so we can splice elements off the array while in the loop.
		for (i in waitFor.length...0) {
			if (_statusByResponder.get(waitFor[i]) == TransitionStatus.HIDDEN) {
				waitFor.splice(i, 1);
			}
		}

		if (waitFor.length > 0) {
			dispatchEvent(new NavigatorEvent(NavigatorEvent.TRANSITION_STATUS_UPDATED, _statusByResponder));
		}

		return waitFor;
	}

	public function performUpdates() : Void {
		_disappearing.reset();

		for (path in _responders.updateByPath) {
			// create a state object for comparison:
			var state : NavigationState = new NavigationState(path);

			if (_current.contains(state)) {
				// the lookup path is contained by the new state.
				var list : Array<Dynamic> = _responders.updateByPath.get(path);

				initializeIfNeccessary(list);

				// check for existing validators.
				for (responder in list) {
					responder.updateState(_current.subtract(state), _current);
				}
			}
		}

		startTransitionIn();
	}

	public function startTransitionIn() : Void {
		_appearing = new AsynchResponders();
		_appearing.addResponders(transitionIn());

		if (!_appearing.isBusy()) {
			startSwapOut();
		}
	}

	public function transitionIn() : Array<Dynamic> {
		var toShow : Array<Dynamic> = getRespondersToShow();

		initializeIfNeccessary(toShow);

		var waitFor : Array<Dynamic> = [];

		for (responder in toShow) {
			var status : Int = _statusByResponder.get(responder);

			if (status < TransitionStatus.APPEARING || TransitionStatus.SHOWN < status) {
				// then continue with the transitionIn() call.
				_statusByResponder.set(responder, TransitionStatus.APPEARING);
				waitFor.push(responder);

				//use namespace transition;
				responder.transitionIn(new TransitionCompleteDelegate(responder, TransitionStatus.SHOWN, NavigationBehaviors.SHOW, this).call);
			}
		}

		// loop backwards so we can splice elements off the array while in the loop.
		for (i in waitFor.length...0) {
			if (_statusByResponder.get(waitFor[i]) == TransitionStatus.SHOWN) {
				waitFor.splice(i, 1);
			}
		}

		if (waitFor.length > 0) {
			dispatchEvent(new NavigatorEvent(NavigatorEvent.TRANSITION_STATUS_UPDATED, _statusByResponder));
		}

		return waitFor;
	}

	public function startSwapOut() : Void {
		_swapping = new AsynchResponders();
		_swapping.addResponders(swapOut());

		if (!_swapping.isBusy()) {
			swapIn();
		}
	}

	public function swapOut() : Array<Dynamic> {
		_appearing.reset();

		var waitFor : Array<Dynamic> = [];

		for (path in _responders.swapByPath) {
			// create a state object for comparison:
			var state : NavigationState = new NavigationState(path);

			if (_current.contains(state)) {
				// the lookup path is contained by the new state.
				var list : Array<Dynamic> = _responders.swapByPath.get(path);

				initializeIfNeccessary(list);

				// check for existing swaps.
				for (responder in list) {
					if (!_responders.swappedBefore.get(responder))
						continue;

					var truncated : NavigationState = _current.subtract(state);
					if (responder.willSwapToState(truncated, _current)) {
						_statusByResponder.set(responder, TransitionStatus.SWAPPING);
						waitFor.push(responder);

						//use namespace transition;
						responder.swapOut(new TransitionCompleteDelegate(responder, TransitionStatus.SHOWN, NavigationBehaviors.SWAP, this).call);
					}
				}
			}
		}

		// loop backwards so we can splice elements off the array while in the loop.
		for (i in waitFor.length...0) {
			if (_statusByResponder.get(waitFor[i]) == TransitionStatus.SHOWN) {
				waitFor.splice(i, 1);
			}
		}

		if (waitFor.length > 0) {
			dispatchEvent(new NavigatorEvent(NavigatorEvent.TRANSITION_STATUS_UPDATED, _statusByResponder));
		}

		return waitFor;
	}

	public function swapIn() : Void {
		_swapping.reset();

		for (path in _responders.swapByPath) {
			// create a state object for comparison:
			var state : NavigationState = new NavigationState(path);

			if (_current.contains(state)) {
				// the lookup path is contained by the new state.
				var list : Array<Dynamic> = _responders.swapByPath.get(path);

				initializeIfNeccessary(list);

				// check for existing swaps.
				for (responder in list) {
					var truncated : NavigationState = _current.subtract(state);
					if (responder.willSwapToState(truncated, _current)) {
						_responders.swappedBefore.set(responder, true);
						responder.swapIn(truncated, _current);
					}
				}
			}
		}

		finishTransition();
	}

	public function finishTransition() : Void {
		_isTransitioning = false;
		dispatchEvent(new NavigatorEvent(NavigatorEvent.TRANSITION_FINISHED));
	}

	private function getRespondersToShow() : Array<Dynamic> {
		var toShow : Array<Dynamic> = getResponderList(_responders.showByPath, _current);
		var toHide : Array<Dynamic> = getResponderList(_responders.hideByPath, _current);

		// remove elements from the toShow list, if they are in the toHide list.
		for (hide in toHide) {
			var hideIndex : Int = Lambda.indexOf(toShow, hide);
			if (hideIndex >= 0) {
				toShow.splice(hideIndex, 1);
			}
		}

		return toShow;
	}

	private function initializeIfNeccessary(responderList : Array<Dynamic>) : Void {
		for (responder in responderList) {
			if (_statusByResponder.get(responder) == TransitionStatus.UNINITIALIZED && Std.is(responder, IHasStateInitialization)) {
				// first initialize the responder.
				cast(responder, IHasStateInitialization).initialize();
				_statusByResponder.set(responder, TransitionStatus.INITIALIZED);
			}
		}
	}

	private function getResponderList(list : ObjectHash < Dynamic, Dynamic > , state : NavigationState) : Array<Dynamic> {
		var responders : Array<Dynamic> = [];

		for (path in list) {
			if (state.contains(new NavigationState(path))) {
				responders = responders.concat(list.get(path));
			}
		}

		return responders;
	}
}

class ResponderLists {
	public var validateByPath : ObjectHash<Dynamic,Dynamic>;
	public var updateByPath : ObjectHash<Dynamic,Dynamic>;
	public var swapByPath : ObjectHash<Dynamic,Dynamic>;
	public var showByPath : ObjectHash<Dynamic,Dynamic>;
	public var hideByPath : ObjectHash<Dynamic,Dynamic>;
	public var swappedBefore : ObjectHash<Dynamic,Dynamic>;
	public var all : Array<ObjectHash<Dynamic,Dynamic>>;

	/*public function toString() : String {
		var described : XML = describeType(this);
		var variables : XMLList = described.child("variable");
		var s : String = "ResponderLists [";
		for each (var variable : XML in variables) {
			if (variable.@type == getQualifiedClassName(Dictionary)) {
				var list : Dictionary = this[variable.@name];
				var contents : Array = [];
				for (var key:* in list) {
					contents.push("[" + key + " = " + list[key] + "]");
				}
				s += "\n\t[" + variable.@name + ": " + contents.join(", ") + "], ";
			}
		}

		s += "]";
		return s;
	}*/
	public function new() {
		validateByPath = new ObjectHash<Dynamic,Dynamic>();
		updateByPath = new ObjectHash<Dynamic,Dynamic>();
		swapByPath = new ObjectHash<Dynamic,Dynamic>();
		showByPath = new ObjectHash<Dynamic,Dynamic>();
		hideByPath = new ObjectHash<Dynamic,Dynamic>();
		swappedBefore = new ObjectHash<Dynamic,Dynamic>();
		all = [validateByPath, updateByPath, swapByPath, showByPath, hideByPath, swappedBefore];
	}

}

class AsynchResponders {
	private var responders : Array<Dynamic>;

	public function getLength() : Int {
		return responders.length;
	}

	public function isBusy() : Bool {
		return getLength() > 0;
	}

	public function hasResponder(responder : INavigationResponder) : Bool {
		return Lambda.indexOf(responders, responder) >= 0;
	}

	public function addResponder(responder : INavigationResponder) : Void {
		responders.push(responder);
	}

	public function addResponders(additionalResponders : Array<Dynamic>) : Void {
		if (additionalResponders != null && additionalResponders.length > 0) { // TODO Original additionalResponders && additionalResponders.length
			responders = responders.concat(additionalResponders);
		}
	}

	public function takeOutResponder(responder : INavigationResponder) : Bool {
		var index : Int = Lambda.indexOf(responders, responder);
		if (index >= 0) {
			responders.splice(index, 1);
			return true;
		}

		return false;
	}

	public function reset() : Void {
		if (responders.length > 0)
			trace("Resetting too early? Still have responders marked for asynchronous tasks");
			
		responders = [];
	}
	public function new() {
		responders = [];
	}
}