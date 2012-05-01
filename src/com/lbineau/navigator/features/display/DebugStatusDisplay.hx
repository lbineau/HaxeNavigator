package com.lbineau.navigator.features.display;
import com.lbineau.navigator.Navigator;

/**
 * ...
 * @author lbineau
 */


class DebugStatusDisplay extends DebugConsole {
	public function new(navigator : Navigator, alignMode : String = "BL") {
		super(navigator, alignMode);
	}
}