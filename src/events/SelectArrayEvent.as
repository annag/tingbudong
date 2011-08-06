package events
{
	import flash.events.Event;

	public class SelectArrayEvent extends Event
	{
		public static const SESSIONS:String = "session";
		public static const TAGS:String = "tag";
		public static const TAGS_MIX:String = "tagmix";
		public var selectArray:Array;
		public function SelectArrayEvent(type:String, arr:Array)
		{
			this.selectArray = arr;
			super(type, false, false);
		}
		
	}
}