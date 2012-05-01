package com.lbineau.navigator.features.display;
import nme.text.TextFieldAutoSize;

/**
 * ...
 * @author lbineau
 */

class DebugTextBox extends DebugTextField {
	public function new(fontSize : Float = 12, color : Int = 0x000000, bold : Bool = false, italic : Dynamic = false) {
		super("Arial", fontSize, color, bold, italic);
		embedFonts = false;
		
		width = 300; 
		height = 100;
		autoSize = TextFieldAutoSize.NONE;
		wordWrap = true;
	}
}