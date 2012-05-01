package examples.simple.components;
import com.eclecticdesignstudio.motion.Actuate;
import com.lbineau.navigator.behaviors.IHasStateInitialization;
import com.lbineau.navigator.behaviors.IHasStateTransition;
import haxe.Timer;
import nme.display.Graphics;
import nme.display.Sprite;

/**
 * ...
 * @author lbineau
 */

class Circle extends BaseShape, implements IHasStateTransition
{
	public function new(color : Int = 0xFF9900) {
		super(color);

		// Because this class does not implement the IHasStateInitialization, we'll take care of that part here.
		// Be sure to end your initialization with a non-visible component.
		draw();
		this.alpha = 0;
		visible = true;
	}
	
	override private function draw() : Void {
		var g : Graphics = graphics;
		g.beginFill(_color, _alpha);
		g.drawCircle(_size / 2, _size / 2, _size / 2);
		g.endFill();
	}
		
	public function transitionIn(callOnComplete:Dynamic):Void 
	{
		Actuate.tween(this, 1, { alpha:1 } );
		// Here we execute the complete callback immediately, which is also possible, and has
		// an added side effect of simultaneous transitions.
		//callOnComplete();
		Timer.delay(callOnComplete,1); // FIXME Why just calling callOnComplete doesn't works ?
	}
	
	public function transitionOut(callOnComplete:Dynamic):Void 
	{
		Actuate.tween(this, 1, { alpha:0 } );
		// Same as transitionIn, instant complete call.
		Timer.delay(callOnComplete,1);  // FIXME Why just calling callOnComplete does'nt works ?
	}
	
}