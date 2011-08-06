package helpers
{
	import model.Layout;
	import model.Session;
	import model.Vocab;
	import model.Word;
	
	import mx.events.IndexChangedEvent;

	public class XMLParsingHelper
	{
		
		public function XMLParsingHelper()
		{ 
		}
		private static function getTitle(type:int, category:int):String{
			
			switch(category){
				case Vocab.IKNOWTHESE:
					return (type == Vocab.LONG_TERM_KNOWLEDGE)? Layout.LONGTERM_TXT : Layout.IKNOWTHESE_TXT;
				case Vocab.ALMOST:
					return (type == Vocab.LONG_TERM_KNOWLEDGE)? Layout.MIDTERM_TXT : Layout.ALMOST_TXT;
				case Vocab.ALITTLE:
					return (type == Vocab.LONG_TERM_KNOWLEDGE)? Layout.SHORTTERM_TEXT : Layout.ALITTLE_TXT;
				case Vocab.WHATSTHAT:
					return (type == Vocab.LONG_TERM_KNOWLEDGE)? Layout.TOMORROW_TXT : Layout.WHATSTHAT_TXT;
				case Vocab.NOIDEA:
					return (type == Vocab.LONG_TERM_KNOWLEDGE)? Layout.NOIDEA_TXT : Layout.NOIDEA_TXT;
				default:
					return "";
			
			}
		return "";
		}
		public static function getVocabXML(type:int, words:Array):String{
			var arr:Array = DatabaseHelper.getInstance().getAllWords();
			
			if(arr.length == 0)return "";
			var str:String = 	"<category name='"+getTitle(type,Vocab.IKNOWTHESE)+"' count='"	+getAllForWords(Vocab.IKNOWTHESE, words, type)+"' />" +
								"<category name='"+getTitle(type,Vocab.ALMOST) 	+"' count='"	+getAllForWords(Vocab.ALMOST, words, type)+"' />" +
								"<category name='"+getTitle(type,Vocab.ALITTLE) 	+"' count='"+getAllForWords(Vocab.ALITTLE, words, type)+"' />" +
								"<category name='"+getTitle(type,Vocab.WHATSTHAT) +"' count='"	+getAllForWords(Vocab.WHATSTHAT, words, type)+"' />" +
								"<category name='"+getTitle(type,Vocab.NOIDEA) 	+"' count='"	+getAllForWords(Vocab.NOIDEA, words, type)+"' />";
			trace(str);
			return  str;
		}
		public static function getSessionXML():String{
			var string:String = "";
			var sessions:Array = DatabaseHelper.getInstance().getSessions();
			
			var type:int = Vocab.LONG_TERM_KNOWLEDGE;
			var len:int = sessions.length;
			for(var i:int = 0; i<len; i++){
				var session:Session = sessions[i] as Session;
				if(session.words.length == 0)
					continue;
				var str:String = "<item name='"+session.name+"'>"+
					"<knowledge category='1' count='"+getAllForCategory(Vocab.IKNOWTHESE, type, 	session.id)+"'/>" + 
					"<knowledge category='2' count='"+getAllForCategory(Vocab.ALMOST, type, 		session.id)+"'/>" +
					"<knowledge category='3' count='"+getAllForCategory(Vocab.ALITTLE, type, 		session.id)+"'/>" +
					"<knowledge category='4' count='"+getAllForCategory(Vocab.WHATSTHAT, type, 	session.id)+"'/>" +
					"<knowledge category='5' count='"+getAllForCategory(Vocab.NOIDEA, type,		session.id)+"'/>" +
					"</item>";
				string = string.concat(str);
			}
				return string;
		}
		public static function getTagXML():String{
			var string:String = "";
			var tags:Array = DatabaseHelper.getInstance().getTags()
			var type:int = Vocab.LONG_TERM_KNOWLEDGE;
			for(var i:int = 0; i<tags.length; i++){
				var tag:String = tags[i];
				var wrds:Array = DatabaseHelper.getInstance().getWordsWithTags(new Array(tag));
				var str:String = "<item name='"+tag+"'>"+
				"<knowledge category='1' count='"+getAllForWords(Vocab.IKNOWTHESE, 	wrds, type)+"'/>" + 
				"<knowledge category='2' count='"+getAllForWords(Vocab.ALMOST, 		wrds, type)+"'/>" +
				"<knowledge category='3' count='"+getAllForWords(Vocab.ALITTLE, 		wrds, type)+"'/>" +
				"<knowledge category='4' count='"+getAllForWords(Vocab.WHATSTHAT, 	wrds, type)+"'/>" +
				"<knowledge category='5' count='"+getAllForWords(Vocab.NOIDEA, 		wrds, type)+"'/>" +
				"</item>";
				string = string.concat(str);
			}
			return string;
			//return "<category name='I know these' count='51' /><category name='almost' count='12' /><category name='a little' count='5' /><category name='whats that' count='2' /><category name='no idea' count='22' />";
		}
		public static function getAllForCategory(category:int,type:int, sessionid:Number = -1):Number{

			if(sessionid == -1){
				return getAllForWords(category,DatabaseHelper.getInstance().getAllWords(), type);
			}else{
				var session:Session = DatabaseHelper.getInstance().getSession(sessionid);
				return getAllForWords(category,session.words, type);
			}
		
		}
		public static function getAllForWords(category:int,words:Array, type:int):Number{
		
			var count:Number = 0;
			for(var i:int = 0; i<words.length; i++){
				var wrd:Vocab = words[i];
				var perc:Number = wrd.getPercentage(type);
				switch(category){
					case Vocab.IKNOWTHESE://100 - 91
						if(perc <= Vocab.IKNOWTHESE_THERSH && perc > Vocab.ALMOST_THERSH) count++;
						break;
					case Vocab.ALMOST://90-61
						if(perc <= Vocab.ALMOST_THERSH && perc > Vocab.ALITTLE_THERSH) count++;
						break;
					case Vocab.ALITTLE://60-41
						if(perc <= Vocab.ALITTLE_THERSH && perc > Vocab.WHATSTHAT_THERSH) count++;
						break;
					case Vocab.WHATSTHAT://40-21
						if(perc <= Vocab.WHATSTHAT_THERSH && perc > Vocab.NOIDEA_THERSH) count++;
						break;
					case Vocab.NOIDEA://20-0
						if(perc <= Vocab.NOIDEA_THERSH && perc >= 0) count++;
						break;
					default:
						break;
				}
			}
			return count;
		}
	}
}