package model
{
	import helpers.Leitner;
	public class Word_old
	{
		//data
		public var english:String;
		public var pinyin:String;
		public var character:String;
		//metadata
		public var dateadded:Date;
		public var tagArray:Array;
		public var groupid:int;
		public var id:int;
		public var trackedForHanse:Boolean;
		public var imagePath:String;
		//quiz mettadata
		public var leitnerOrder:int;
		private var _leitnerCurrentPile:int;
		public var nextDeadline:Date;
		public var quizObj:QuizObject;
		public function set leitnerCurrentPile(pile:int):void{
			_leitnerCurrentPile = pile;
		}
		public function get leitnerCurrentPile():int{
			
			return _leitnerCurrentPile;
		}
		public function isRipe():Boolean{
			
			//today's date
			var today:Date = new Date();
			
			//leitnerCurrentPile
			var earliestDate:Date 	= Leitner.getEarliestDate(leitnerCurrentPile, nextDeadline);
			var latestDate:Date 	= Leitner.getLatestDate(leitnerCurrentPile,  nextDeadline);
		
			var beforeEnd:Boolean 	= today.day <= latestDate.day;
			var afterStart:Boolean 	= today.day >= earliestDate.day;
			if(beforeEnd && afterStart){
				return true;
			}
			return false;
		}
		public function getLastDate():Date{
			trace(this.english+", next deadline:"+nextDeadline);
			return Leitner.getLatestDate(leitnerCurrentPile,  nextDeadline);
		}
		
		
		public function Word()
		{
			super();
			this.quizObj 	= new QuizObject(this);
			this.tagArray 	= new Array();
		}
		public function settagArray(txt:String):void{
		
			if(txt == null){
				this.tagArray = new Array();
				return;
			}
			txt = txt.toLocaleLowerCase();
		 	var myPattern:RegExp = / /g;  
			txt = txt.replace(myPattern, "");
			this.tagArray = txt.split(",",20);
		}
	
		public function gettagArray():String{
			if(tagArray == null || tagArray.length == 0)
				return null;
			return tagArray.join(",");
		
		}
		
		public function getColor():String{
		
		
			var percentageRight:Number =this.leitnerCurrentPile/Leitner.NUM_PILES*100;
			
			if(percentageRight < 20){
				
				return Layout.NOIDEA_CL;//red
			}else if(percentageRight < 40){
				
				return Layout.WHATSTHAT_CL;//purple
			}else if(percentageRight < 60){
				
				return Layout.ALITTLE_CL;//blue
			}else if(percentageRight < 80){
				
				return Layout.ALMOST_CL;//green
			}else if(percentageRight <= 100){
				
				return Layout.IKNOWTHESE_CL;//green
			}
			
			return "#12d503";
		
		
		}
		public function getPercentage():Number{
			var percentageRight:Number =this.leitnerCurrentPile/Leitner.NUM_PILES*100;
			return percentageRight;
		}
	}
}