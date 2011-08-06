package events
{
	import flash.events.Event;
	
	public class SessionHeaderEvent extends Event
	{
		public static const EDIT:String = "edit";
		public static const DELETE:String = "delete";
		public static const TOGGLE_OPEN:String = "toggleOpen";
		
		
		public var action:String;
		
		public function SessionHeaderEvent(action:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			this.action = action;
			super("onAction", bubbles, cancelable);
		}
	}
}