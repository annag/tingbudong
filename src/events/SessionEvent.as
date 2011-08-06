package events
{
	import flash.events.Event;

	public class SessionEvent extends Event
	{
		public static const NEW_SESSION:String = "newSession";
		public static const UPDATE_SESSION:String = "uSession";
		public static const DELETE_SESSION:String = "dSession";
		public var sessionName:String;
		public var updateId:String;
		public var deleteId:String;
		public function SessionEvent(type:String, session_name:String=null, u_id:String = null, d_id:String = null)
		{
			super(type, true, false);
			
			this.sessionName 	= session_name;
			this.updateId 		= u_id;
			this.deleteId 		= d_id;
		}
		
	}
}