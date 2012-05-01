package com.lbineau.navigator.features.display;
import com.lbineau.navigator.behaviors.IHasStateInitialization;
import com.lbineau.navigator.behaviors.IHasStateTransition;
import com.lbineau.navigator.behaviors.INavigationResponder;
import com.lbineau.navigator.INavigator;
import com.lbineau.navigator.NavigationState;
import com.lbineau.navigator.Navigator;
import com.lbineau.navigator.NavigatorEvent;
import com.lbineau.navigator.transition.TransitionStatus;
import nme.display.Sprite;
import nme.errors.Error;
import nme.events.Event;
import nme.events.KeyboardEvent;
import nme.text.TextFieldType;
import nme.text.TextField;
import nme.text.TextFormat;
import nme.text.TextFieldAutoSize;
import nme.text.AntiAliasType;
import nme.ui.Keyboard;


import com.lbineau.utils.ObjectHash;
/**
 * ...
 * @author lbineau
 */

class DebugConsole extends Sprite
{
	private var _boxLeft : DebugTextBox;
	private var _boxRight : DebugTextBox;
	private var _boxHeader : DebugTextField;
	private var _navigator : INavigator;
	private var _alignMode : String;

	public function new(navigator : INavigator, alignMode : String = "BL") {
		super();
		_navigator = navigator;
		_alignMode = alignMode;

		_boxHeader = new DebugTextField("Arial", 12, 0x00FF00, true);
		_boxHeader.type = TextFieldType.INPUT;
		_boxHeader.background = true;
		_boxHeader.backgroundColor = 0x222222;
		_boxHeader.embedFonts = false;
		_boxHeader.selectable = true;
		_boxHeader.restrict = "-_/A-Za-z0-9";
		_boxHeader.addEventListener(KeyboardEvent.KEY_DOWN, handleInputKeystroke);

		_boxLeft = new DebugTextBox(12, 0xFF9900);
		_boxLeft.background = true;
		_boxLeft.backgroundColor = 0x222222;
		_boxLeft.wordWrap = false;
		_boxLeft.autoSize = TextFieldAutoSize.LEFT;

		_boxRight = new DebugTextBox(12, 0xFF9900);
		_boxRight.background = true;
		_boxRight.backgroundColor = 0x222222;
		_boxRight.wordWrap = false;
		_boxRight.autoSize = TextFieldAutoSize.NONE;
		_boxRight.width = 110;

		addChild(_boxLeft);
		addChild(_boxRight);
		addChild(_boxHeader);

		addEventListener(Event.ADDED_TO_STAGE, handleAddedToStage);
	}

	private function handleInputKeystroke(event : KeyboardEvent) : Void {
		if (event.keyCode == Keyboard.ENTER) {
			_navigator.request(_boxHeader.text);
		}
	}

	private function handleAddedToStage(event : Event) : Void {
		_navigator.addEventListener(NavigatorEvent.STATE_CHANGED, handleStatusUpdated);
		_navigator.addEventListener(NavigatorEvent.TRANSITION_STATUS_UPDATED, handleStatusUpdated);
		stage.addEventListener(Event.RESIZE, handleStageResize);
		stage.addEventListener(KeyboardEvent.KEY_DOWN, handleKeyDown);
		removeEventListener(Event.ADDED_TO_STAGE, handleAddedToStage);
		updateDisplay(cast(_navigator, Navigator)._statusByResponder);
		layout(stage.stageWidth, stage.stageHeight);
	}

	private function updateContextMenu() : Void {
		/*var cm : ContextMenu = new ContextMenu();
		cm.hideBuiltInItems();

		cm.customItems.push(new ContextMenuItem("States with registered responders:", false, false, true));

		var separate : Boolean = true;
		var paths : Array = _navigator.hidden::getKnownPaths();
		for each (var path : String in paths) {
			var menuItem : ContextMenuItem = new ContextMenuItem(path, separate);
			separate = false;
			menuItem.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, new ContextMenuHandler(path, _navigator).handleEvent);
			cm.customItems.push(menuItem);
		}

		contextMenu = cm;*/
	}

	private function handleStageResize(event : Event) : Void {
		layout(stage.stageWidth, stage.stageHeight);
	}

	private function handleStatusUpdated(event : NavigatorEvent) : Void {
		updateDisplay(event.statusByResponder);
		layout(stage.stageWidth, stage.stageHeight);
	}

	private function updateDisplay(statusByResponder : ObjectHash<Dynamic,Dynamic>) : Void {
		var currentState : NavigationState = _navigator.getCurrentState();
		if (currentState == null) return;

		var sLeft : String = "<font color=\"#AAAAAA\">Path:</font>\n";
		var sRight : String = "\n";
		var sHeader : String = currentState.path;

		for (key in statusByResponder) {
			var responder : INavigationResponder = cast(key, INavigationResponder);
			if (Std.is(responder, IHasStateTransition) || Std.is(responder, IHasStateInitialization)) {
				sLeft += responder + " \t\n";
				var color : String = getColorByStatus(cast(statusByResponder.get(responder),Int));
				sRight += "<font color=\"" + color + "\"><b>" + TransitionStatus.toString(cast(statusByResponder.get(responder),Int)) + "</b></font>\n";
			}
		}
		_boxHeader.replaceText(0, _boxHeader.text.length, sHeader);
		_boxHeader.setSelection(_boxHeader.text.length, _boxHeader.text.length);
		_boxLeft.text = sLeft;
		_boxRight.text = sRight;
		_boxRight.height = _boxLeft.height;

		try {
			updateContextMenu();
		} catch (ei : Error) {
			trace("[i]: " + ei.message);
		}
	}

	private function getColorByStatus(status : Int) : String {
		var color : String = "";

		switch(status) {
			case TransitionStatus.UNINITIALIZED:
				color = "#AAAAAA";
			case TransitionStatus.INITIALIZED:
				color = "#FFFFFF";
			case TransitionStatus.HIDDEN:
				color = "#FF0000";
			case TransitionStatus.APPEARING, TransitionStatus.DISAPPEARING:
				color = "#FFFF00";
			case TransitionStatus.SHOWN:
				color = "#00FF00";
			default:
		}

		return color;
	}

	private function layout(stageWidth : Float, stageHeight : Float) : Void {
		switch (_alignMode) {
			case "BR":
				_boxRight.x = stageWidth - _boxRight.width - 10;
				_boxRight.y = stageHeight - _boxRight.height - 10;
				_boxLeft.x = _boxRight.x - _boxLeft.width;
				_boxLeft.y = _boxRight.y;
			case "BL":
				_boxLeft.x = 10;
				_boxLeft.y = stageHeight - _boxLeft.height - 10;
				_boxRight.x = _boxLeft.x + _boxLeft.width;
				_boxRight.y = _boxLeft.y;
			case "TR":
				_boxRight.x = stageWidth - _boxRight.width - 10;
				_boxRight.y = 10;
				_boxLeft.x = _boxRight.x - _boxLeft.width;
				_boxLeft.y = _boxRight.y;
			default:
		}

		_boxHeader.x = _boxLeft.x + 40;
		_boxHeader.y = _boxLeft.y;
	}

	private function handleKeyDown(event : KeyboardEvent) : Void {
		switch(String.fromCharCode(event.charCode)) {
			case "~":
			case "$":
			case "`":
				if (stage.focus == _boxHeader || !visible) {
					visible = !visible;
				} else if (visible) {
					_boxHeader.stage.focus = _boxHeader;
				}
			default:
		}
	}
}
/*
class ContextMenuHandler {
	private var _path : String;
	private var _navigator : INavigator;

	public function ContextMenuHandler(path : String, navigator : INavigator) {
		_path = path;
		_navigator = navigator;
	}

	public function handleEvent(event : ContextMenuEvent) : Void {
		_navigator.request(_path);

		// and clean up.
		_path = null;
		_navigator = null;
		EventDispatcher(event.target).removeEventListener(ContextMenuEvent.MENU_ITEM_SELECT, handleEvent);
	}
}*/