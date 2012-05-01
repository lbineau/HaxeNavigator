package examples.simple.components;
import com.eclecticdesignstudio.motion.Actuate;
import com.lbineau.navigator.behaviors.IHasStateInitialization;
import com.lbineau.navigator.behaviors.IHasStateTransition;

/**
 * ...
 * @author lbineau
 */

class Square extends BaseShape, implements IHasStateInitialization, implements IHasStateTransition 
{
	public function new(color : Int = 0xFF9900) {
		super(color);
	}

	public function initialize() : Void {
		draw();
		alpha = 0;
		visible = true;
	}

	public function transitionIn(callOnComplete : Dynamic) : Void {
		Actuate.tween(this, 1, { alpha:1 } ).onComplete(callOnComplete);
	}

	public function transitionOut(callOnComplete : Dynamic) : Void {
		Actuate.tween(this, 1, { alpha:0 } ).onComplete(callOnComplete);
	}
}