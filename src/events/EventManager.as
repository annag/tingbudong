package events{
	
	import flash.events.EventDispatcher;
	
	public class EventManager extends EventDispatcher {
		
		public static var StartQuizEvent1:String = "startQuizEvent1";
		public static var StartQuizEvent2:String = "startQuizEvent2";
		public static var StartQuizEvent3:String = "startQuizEvent3";
		public static var StartQuizEvent4:String = "startQuizEvent4";	
		public static var StartQuizEvent5:String = "startQuizEvent5";	
		public static var OpenQuizBaseEvent:String = "OpenQuizBaseEvent";	
		public static var CloseQuizBaseEvent:String = "CloseQuizBaseEvent";
		public static var StopQuizEvent:String = "stopQuizEvent";
		public static var UpdateSettingsEvent:String = "updatesettingsevent";
		public static var ResetSettingsEvent:String = "resetsettingsevent";
		
	
		public function EventManager(enforcer:SingletonEnforcer) {}
		
		private static var _instance:EventManager;
		
		public static function getInstance():EventManager {
			if (_instance == null) {
				_instance = new EventManager(new SingletonEnforcer());
			}
			return _instance;
		}
		
	}
	
}

class SingletonEnforcer {}