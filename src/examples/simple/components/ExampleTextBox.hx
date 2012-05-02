package examples.simple.components;
import com.lbineau.navigator.features.display.DebugTextBox;

/**
 * ...
 * @author lbineau
 */

class ExampleTextBox extends DebugTextBox {
	private var t : String;
	
	public function new() {
		super();
		
		width = 620;
		height = 160;
		
		t = "<b>Simple Navigator Example (no dependencies)</b>\n\n";
		t+= "Welcome to the first example of the Haxe-Navigator library.\n";
		t+= "Added to this example are 4 elements. A red, green and blue square, and a black circle. By clicking the menu, you can change the navigation state.\n";
		t+= "You can also type in a path in the debug console.\n\n";
		t+= "<a href='event:red'><u>Red Square</u></a> | <a href='event:green'><u>Green Square</u></a> | <a href='event:blue'><u>Blue Square</u></a> | <a href='event:black'><u>Black Circle</u></a>\n\n";
		t+= "But what you can also do is show two shapes at the same time, by using state cascading:\n\n";
		t+= "<a href='event:red/blue'><u>Red and Blue</u></a> | <a href='event:green/black'><u>Green and Black</u></a>";
		
		setHtmlText(t);
	}
}