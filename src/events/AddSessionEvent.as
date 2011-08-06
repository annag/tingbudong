package events
{
	import flash.events.Event;

	public class AddSessionEvent extends Event
	{
		public static const NEW_SESSION:String = "newSession";
		public var sessionName:String
		public function AddSessionEvent(type:String, session_name:String)
		{
			super(type, true, false);
			this.sessionName = session_name;
		}
		
	}
}