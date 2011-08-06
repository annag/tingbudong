package model
{
	public class Session
	{
		public static var MAX_CHAR:int = 50;
		public var id:int;
		public var name:String;
		public var words:Array;
		public var grammar:Array;
		public var dateadded:Date;
		public var _wordlen:Number;
		public var isOpen:Boolean;
		private var _level:Number;
		public function Session()
		{
			
		}
	public function get wordlen():Number{
		
			return words.length;
		}

		public function get level():Number{
			
			return 2;
		}
	public function get vocabulary():Array{
	
		return words.concat(grammar);
	}
	}
}