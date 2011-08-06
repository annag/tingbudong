package model
{

	public class Layout
	{
		public static var headerheight:int  = 120;
		public static var verticalspacer:int  = 20;
		public static var horizontalspacer:int = 20;
		
		public static var tab1title:String = "My Vocabulary";
		public static var tab2title:String = "Find Words";
		public static var tab3title:String = "Quiz Settings";
		public static var tab4title:String = "Import Sentences";
		
		public static var NOIDEA_CL:String 		= "#ff0000";//pink
		public static var WHATSTHAT_CL:String 	= "#e9109a";//red
		public static var ALITTLE_CL:String 	= "#705492";//purple
		public static var ALMOST_CL:String 		= "#597bd";//blue
		public static var IKNOWTHESE_CL:String 	= "#12d503";//green
		
		[Bindable]
		public static var NOIDEA_TXT:String 	= "No idea";
		[Bindable]
		public static var WHATSTHAT_TXT:String 	= "Whats that?";
		[Bindable]
		public static var ALITTLE_TXT:String 	= "A little";
		[Bindable]
		public static var ALMOST_TXT:String 	= "Almost";
		[Bindable]
		public static var IKNOWTHESE_TXT:String	= "I know these";
		[Bindable]
		public static var TOMORROW_TXT:String 	= "Forgotten tomorrow";
		[Bindable]
		public static var SHORTTERM_TEXT:String 	= "Shortterm memory";
		[Bindable]
		public static var MIDTERM_TXT:String 	= "Midterm memory";
		[Bindable]
		public static var LONGTERM_TXT:String	= "Longterm memory";
		
		public static var APP_HEIGHT:int = 600
		public static var APP_WIDTH:int = 800
			
		public function Layout()
		{
		}
		public static function getHorSpace():int{
		
		return 10;
		}
		public static function getColors():Array{
			return new Array("0x12d503", "0x597bd", "0x705492", "0xe9109a", "0xff0000");
		}
	}
}