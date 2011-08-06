package model
{
	import flash.filesystem.File;
	
	import helpers.AIRUtils;
	import helpers.DatabaseHelper;

	[Bindable]
	[RemoteClass(alias="model.QuizSettings")]
	public class QuizSettings
	{

		//storing the settings
		public static const fileName:String = "quizSettings.dat";
		public static var quizSettingsFile:File = File.applicationStorageDirectory.resolvePath(fileName);
		
		//what is being quized:
		public static var SHOW_ALL:int 			= 0;
		public static var CHINESE_ENGLISH:int 	= 1;
		public static var ENGLISH_CHINESE:int	= 2;
		public static var PINYIN_CHARACTER:int	= 3;
		
		//limit words to index:
		public static var WORDS_10:int 	= 0;
		public static var WORDS_20:int 	= 1;
		public static var WORDS_30:int	= 2;
		public static var ALL_WORDS:int	= 3;
		
		//what is given/quized
		public var quiz1_type:int;
		public var quiz2_type:int;
		
		public var tagArray:Array;
		public var sessionArray:Array;

		public var tArray:Array;
		public var sArray:Array;
		
		public var quizedType:int;
		
		public var selectedRipenessRipe:Boolean;
		public var selectedRipenessNotRipe:Boolean;
		
		public var mainQuizContent:int;
		
		public var limitWordsIndex:int;
		
		public function QuizSettings()
		{
			
		}
		
		public function save():void
		{
			AIRUtils.writeFileObject(quizSettingsFile, this);
		}
		
		
		public function setWordArrays():void{
			
			var sessions:Array = DatabaseHelper.getInstance().getSessions()
			var selectedSess:Array = new Array();
			var indicies:Array = this.sArray;
			
			for(var i:int=0; i<indicies.length;i++){
				var sess:Session = sessions[indicies[i]];
				if(sess){
					selectedSess.push(sess);
				}
			}
			
			var tagsArr:Array = DatabaseHelper.getInstance().getTags();
			var selectedTags:Array = new Array();
			indicies = this.tArray;
			
			for(var e:int=0; e<indicies.length;e++){
				selectedTags.push(tagsArr[indicies[e]]);
			}
			
			this.sessionArray 	= selectedSess;
			this.tagArray 		= selectedTags;
			
		}
		public static function getDefaultSettings():QuizSettings{
	
			var qs:QuizSettings = new QuizSettings();
			
			qs.quiz1_type = CHINESE_ENGLISH;
			qs.quiz2_type = CHINESE_ENGLISH;
			
			qs.tagArray 			= new Array();
			qs.sessionArray 		= new Array();
			//qs.wordArray 			= new Array();
			
			qs.tArray 			= new Array();
			qs.sArray 			= new Array();
			//qs.wArray 			= new Array();
			
			qs.selectedRipenessRipe 	= true;
			qs.selectedRipenessNotRipe 	= false;
			
			qs.limitWordsIndex = ALL_WORDS;
			
			return qs;
		}
		
	}
}