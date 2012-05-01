package com.lbineau.navigator.features.display;
import nme.text.TextField;
import nme.text.TextFormat;
import nme.text.TextFieldAutoSize;
import nme.text.AntiAliasType;


/**
 * ...
 * @author lbineau
 */

class DebugTextField extends TextField {
	private var _color : Int;

	public function new(font : String, fontSize : Float = 12, color : Int = 0x000000, bold : Bool = false, italic : Dynamic = false) {
		super();
		embedFonts = true;
		tabEnabled = false;
		focusRect = false;
		width = 100;
		autoSize = TextFieldAutoSize.LEFT;
		antiAliasType = AntiAliasType.ADVANCED;
		_color = color;
		defaultTextFormat = new TextFormat(font, fontSize, _color, bold, italic);
		selectable = false;
	}

	@:setter(text)
	public function setText(value : String) : Void {
		if (value == null) {
			setHtmlText("*text supplied as null object*");
			return;
		}
		
		setHtmlText(value);
	}

	public function setHtmlText(value : String) : Void {
		//multiline = value.match(/\<br *\/\>/gi).length ? true : false;
		htmlText = value; 
	}
	
	@:getter(color)
	public function getColor() : Int {
		return _color;
	}
	
	@:setter(color)
	public function setColor(color : Int) : Void {
		
		if (styleSheet != null) return;

		_color = color;
		
		var fmt : TextFormat = getTextFormat();
		fmt.color = color;
		setTextFormat(fmt);

		defaultTextFormat = fmt;
	}
}