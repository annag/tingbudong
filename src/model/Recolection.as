package model
{
	public class Recolection
	{
		//
		public var recolection_rate:Number = 0.0;
		public var average_time:Number = 0;
		//secondary metadata
		public  var _today_quized:int = 0;
		public var today_correct:Array = new Array();
		public var all_times:Array = new Array();
		
		
		public function Recolection()
		{
		}
		public function init(lastcorrect:String, lasttimes:int, alltimes:String):void{
				
				this._today_quized	= lasttimes;
				this.today_correct 	= (lastcorrect == null)?new Array() : lastcorrect.split(",");
				this.all_times 		= (alltimes == null)?	new Array() 	: alltimes.split(",");
				
				
				if(_today_quized == 0){
					average_time 		= 0;
					recolection_rate 	= 0;
				} else{
		
					average_time 		= all_times.length/_today_quized;
					recolection_rate 	= today_correct.length/_today_quized;
				
				}
		
		}
		public function recordResults(correct:Boolean, time:Number = 0):void{
			
			_today_quized  = (_today_quized >= 5)?5:_today_quized+1;
			all_times.push(time);
			if(all_times.length > 5) all_times.shift();
			today_correct.push(correct);
			if(today_correct.length > 5) today_correct.shift();

			average_time 		= all_times.length/_today_quized;
			recolection_rate 	= today_correct.length/_today_quized;
		
		}
		public function get today_quized():int{	return _today_quized; }
	}
}