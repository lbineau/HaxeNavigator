package ;
import com.lbineau.navigator.features.history.NavigatorHistory;
import com.lbineau.navigator.INavigator;
import com.lbineau.navigator.NavigationState;
import com.lbineau.navigator.Navigator;
import com.lbineau.navigator.NavigatorEvent;
import com.lbineau.navigator.transition.TransitionStatus;
import com.lbineau.utils.ObjectHash;
import examples.simple.components.Circle;
import examples.simple.components.Square;
import examples.simple.utils.BaseExample;
import flash.display.Sprite;
import nme.display.Graphics;
import nme.events.MouseEvent;
import nme.events.TextEvent;
import nme.Lib;
import nme.display.StageAlign;
import nme.display.StageScaleMode;
#if flash
import examples.simple.components.ExampleTextBox;
import com.lbineau.navigator.features.display.DebugConsole;
#end
#if js
#end

/**
 * ...
 * @author lbineau
 */

class SimpleNavigatorExample extends BaseExample
{
	private var navigator : Navigator;
	private var i : Int;

	static public function main() 
	{
		new SimpleNavigatorExample();
	}
	public function new() {
		super();
		var stage = Lib.current.stage;
		stage.scaleMode = StageScaleMode.NO_SCALE;
		stage.align = StageAlign.TOP_LEFT;
		stage.addChild(this);
				
		navigator = new Navigator();

		#if flash
			// Navigator debug console, very nice for development. Toggle with the tilde key, "~". You can type in new states by hand!
			var display : DebugConsole = new DebugConsole(navigator);
			addChild(display);
			
			// Example description and menu
			var intro = new ExampleTextBox();
			intro.addEventListener(TextEvent.LINK, handleTextLinkEvent);
			addRow([intro]);
		#end
		
		#if js
			trace("Click for change the Shape width HaxeNavigator", "information");
			stage.addEventListener(MouseEvent.CLICK, _shownNext);
		#end

		// These components implement Navigator interfaces to become state responders. Look at comments in the shape classes.
		var redSquare:Square = new Square(0x990000);
		var greenSquare:Square = new Square(0x009900);
		var blueSquare = new Circle(0x000099);
		var blackCircle = new Circle(0x000000);
		addRow([redSquare, greenSquare, blueSquare, blackCircle]);
		
		// Here we add the responders to the navigation states they represent.
		navigator.add(redSquare, "red");
		navigator.add(greenSquare, "green");
		navigator.add(blueSquare, "blue");
		navigator.add(blackCircle, "black");
		
		// We can add one responder to as many states as we like.
		navigator.add(redSquare, "*/red");
		navigator.add(greenSquare, "*/green");
		navigator.add(blueSquare, "*/blue");
		navigator.add(blackCircle, "*/black");
		
		// And then we decide the point at which the Navigator takes over
		navigator.start("black");
	}
	
	#if js
	// fallback for JS demo
	private function _shownNext(e:MouseEvent):Void 
	{
		switch(i % 4) {
			case 0:navigator.request("red");
			case 1:navigator.request("green");
			case 2:navigator.request("blue");
			case 3:navigator.request("black");
		}
		i++;
	}
	#end
	
	private function handleTextLinkEvent(e:TextEvent):Void 
	{
		// New states are 'requested' at the Navigator. It will run a few validation tests on your requested state.
		// States that make no sense to the Navigator are denied, but if you stick to the states we added
		// responders to, we'll be perfectly fine.

		navigator.request(e.text);

		// You can influence the validation of states by adding components that implement IHasStateValidation*** interfaces.
	}
}