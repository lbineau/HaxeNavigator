package examples.simple.utils;
import nme.display.StageAlign;
import nme.display.StageScaleMode;
import nme.display.Sprite;
import nme.events.Event;
import nme.geom.Point;
import nme.Lib;

/**
 * ...
 * @author lbineau
 */

class BaseExample extends Sprite {
	public var pixelSnapping : Bool;
	//
	private var _spacing : Point;
	private var _origin : Point;
	private var _offset : Point;
	public function new(inOriginX : Float = 10, inOriginY : Float = 10, inSpacingX : Float = 10, inSpacingY : Float = 10) {
		super();
		_spacing = new Point(inSpacingX, inSpacingY);
		_origin = new Point(inOriginX, inOriginY);
		_offset = new Point(0, 0);

		var stage = Lib.current.stage;
		if (stage != null) {
			setupStage();
		} else {
			addEventListener(Event.ADDED_TO_STAGE, setupStage);
		}
	}

	private function setupStage(e:Event = null) : Void {
		var stage = Lib.current.stage;
		stage.align = StageAlign.TOP_LEFT;
		stage.scaleMode = StageScaleMode.NO_SCALE;
	}

	public function addRow(inRowElements : Array<Dynamic>) : Void {
		addRowAt(inRowElements);
	}

	public function addRowBehind(inRowElements : Array<Dynamic>) : Void {
		addRowAt(inRowElements, 0);
	}

	private function addRowAt(inRowElements : Array<Dynamic>, ?inDepth : Int) : Void {
		var height : Float = 0;
		_offset.x = 0;
		
		for (obj in inRowElements) {
			obj.x = getNextX();
			obj.y = getNextY();
			if (inDepth == null) {
				addChild(obj);
			} else {
				addChildAt(obj, inDepth);
			}
			height = Math.max(obj.height, height);

			_offset.x += obj.width + _spacing.x;
		}

		_offset.x = 0;
		_offset.y += height + _spacing.y;
	}

	public function reset(?inOriginX : Float, ?inOriginY : Float, ?inSpacingX : Float, ?inSpacingY) : Void {
		_origin.x = Math.isNaN(inOriginX) ? _origin.x : inOriginX;
		_origin.y = Math.isNaN(inOriginY) ? _origin.y : inOriginY;

		_spacing.x = Math.isNaN(inSpacingX) ? _spacing.x : inSpacingX;
		_spacing.y = Math.isNaN(inSpacingY) ? _spacing.y : inSpacingY;

		_offset.x = 0;
		_offset.y = 0;
	}

	public function getSpacingX() : Float {
		return _spacing.x;
	}

	public function setSpacingX(inPixels : Float) : Void {
		_spacing.x = inPixels;
	}

	public function getSpacingY() : Float {
		return _spacing.y;
	}

	public function setSpacingY(inPixels : Float) : Void {
		_spacing.y = inPixels;
	}

	public function getNextX() : Float {
		if (pixelSnapping) return Math.round(_origin.x + _offset.x);
		return _origin.x + _offset.x;
	}

	public function getNextY() : Float {
		if (pixelSnapping) return Math.round(_origin.y + _offset.y);
		return _origin.y + _offset.y;
	}
}