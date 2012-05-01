package examples.simple.components;
import nme.display.Graphics;
import nme.display.Sprite;

/**
 * ...
 * @author lbineau
 */

class BaseShape extends Sprite {
	private var _color : Int;
	private var _size : Float;
	private var _alpha : Float;
	
	public function new(color : Int = 0xFF9900, size : Float = 99, alpha : Float = 1) {
		super();
		_color = color;
		_size = size;
		_alpha = alpha;
	}
	
	@:getter(width)
	public function getWidth():Float {
		return _size;
	}
	
	@:getter(height)
	public function getHeight():Float {
		return _size;
	}

	private function draw() : Void {
		var g : Graphics = graphics;
		g.beginFill(_color, _alpha);
		g.drawRect(0, 0, _size, _size);
		g.endFill();
	}
}