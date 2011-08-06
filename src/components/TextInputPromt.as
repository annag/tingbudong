package components
{
	import flash.events.FocusEvent;
	import flash.events.KeyboardEvent;
	
	import mx.controls.TextInput;
	
	public class TextInputPromt extends TextInput
	{
		
		private var __prompt:String = null;
		private var __firstTime:Boolean = true;
		
		/**
		 * Getter for prompt
		 */
		public function get prompt():String
		{
			return __prompt;
		}
		
		/**
		 * Setter for prompt
		 */
		public function set prompt( prompt:String ):void
		{
			__prompt = prompt;
			showPrompt();
		}
		
		/**
		 * Getter for text
		 */
		override public function get text():String
		{
			return super.text;
		}
		
		/**
		 * Setter for text
		 */
		override public function set text( text:String ):void
		{
			hidePrompt();
			super.text = text;
		}
		
		/**
		 * Constructor
		 */
		public function TextInputPromt()
		{
			super();
			
			if (prompt != null && prompt != "")
			{
				showPrompt();
			}
			
			// Event listeners
			this.addEventListener(FocusEvent.FOCUS_IN, onFocusIn);
			this.addEventListener(FocusEvent.FOCUS_OUT, onFocusOut);
		}
		
		private function showPrompt():void
		{
			// If promopt is set, add it to the text property and set style
			if (prompt != null && prompt != "" && text.length <= 0)
			{
				super.text = prompt;
				
				// Style
				this.setStyle("color", "#AAAAAA");
			}
		}
		
		private function hidePrompt():void 
		{
			// Remove prompt from text string and set style to default
			super.text = null;
			
			// Style
			this.setStyle("color", "#333333");
		}
		
		private function onFocusIn( e:FocusEvent ):void
		{
			// Add listener for keys so we can hide prompt
			this.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
			hidePrompt();
		}
		
		private function onFocusOut( e:FocusEvent ):void
		{
			// Remove listener for keys
			this.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
			
			// Show prompt if text is blank
			if (super.text == null || super.text == "")
			{
				showPrompt();
			}
			
			__firstTime = true;
		}
		
		private function onKeyDown( e:KeyboardEvent ):void
		{
			// Remove prompt if keyCode is a valid text character
			if ((e.keyCode >=48 && e.keyCode <=57) ||
				(e.keyCode >=65 && e.keyCode <=90) ||
				(e.keyCode >=96 && e.keyCode <=107) ||
				(e.keyCode >=109 && e.keyCode <=111) ||
				(e.keyCode >=186 && e.keyCode <=192) ||
				(e.keyCode >=219 && e.keyCode <=222))
			{
				hidePrompt();
				
				// Remove listener for keys
				this.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
			}
		}
	}
}