package model
{
	import mx.events.IndexChangedEvent;

	public class QuizVocabulary
	{
		//imports
		import helpers.DatabaseHelper;
		/***********************************************/
		/*VARIABLES*/
		/***********************************************/
		private static var RARLYASKED_DEFINED:int = 4;

		[Bindable]
		public var quizWords:Array;
		private var _hanziArray:Array;
		private var _grammarArray:Array;
		private var _wordArray:Array;
		private var _picArray:Array;
		public var settings:QuizSettings;
		private var mainQuizWords:Array;
		public var ripeWords:Array;
		public var notRipeWords:Array;
		
		public var allGrammar:Array;
		public var allWords:Array;
		/***********************************************/
		/*CONSTRUCTOR*/
		/***********************************************/
		
		private static var _instance:QuizVocabulary;
		
		public static function getInstance():QuizVocabulary {
			if (_instance == null) {
				_instance = new QuizVocabulary();
			}
			return _instance;
		}
		
		public function QuizVocabulary()
		{
			
			quizWords = new Array();
			mainQuizWords = new Array();
		}
		/***********************************************/
		/*PUBLIC FUNCTIONS*/
		/***********************************************/
		public function getQuizWordsForHanzi():Array{
			
			if(_hanziArray.length > 0) return _hanziArray;
			
			_hanziArray= new Array();
			for(var i:int=0;i<quizWords.length;i++){
				if(quizWords[i] is Word){
					var word:Word = quizWords[i];
					if(word.trackedForHanse) _hanziArray.push(word);
				}
			}
			return _hanziArray;
		}
		public function getQuizGrammarNoWords():Array{
			
			if(_grammarArray.length > 0) return _grammarArray;
			_grammarArray = new Array();
			for(var i:int=0;i<quizWords.length;i++){
				if(quizWords[i] is Grammar) _grammarArray.push(quizWords[i]);
			}
			return _grammarArray;
		}
		public function getQuizWordsNoGrammar():Array{
			if(_wordArray.length > 0) return _wordArray;
			_wordArray = new Array();
			for(var i:int=0;i<quizWords.length;i++){
				if(quizWords[i] is Word)  _wordArray.push(quizWords[i]);
			}
			return _wordArray;
		}
		public function getQuizWordsWithPictures():Array{
			if(_picArray.length > 0) return _picArray;
			_picArray = new Array();
			for(var i:int=0;i<quizWords.length;i++){
				if(quizWords[i] is Word){
					var word:Word = quizWords[i];
					if(word.imagePath != "") _picArray.push(word);	
				}
			}
			return _picArray;
		}
		public function getQuizSentences(arr:Array):Array{
			var sentArray:Array = new Array();
			for(var i:int=0; i<arr.length;i++){
					var word:Vocab = arr[i];
					sentArray = sentArray.concat(word.sentences);
			}
			return sentArray;
		}
		public function update(_settings:QuizSettings):void{
		
			if(_settings == null)return;
			settings = _settings;
			
			//get main quiz content (words/vocab):
			mainQuizWords = getMainQuizedWords();

			quizWords = checkRipeness();
			
			//reset:
			_hanziArray = new Array();
			_grammarArray = new Array();
			_wordArray = new Array();
			_picArray = new Array();
			
			if(quizWords.length == 0)return;

			limitWords();
		}
		
		/***********************************************/
		/*PRIVATE FUNCTIONS*/
		/***********************************************/
		private function limitWords():void{
			
			switch(settings.limitWordsIndex){
			case QuizSettings.WORDS_10:
				quizWords.splice(10);
				break;
			case QuizSettings.WORDS_20:
				quizWords.splice(20);
				break;
			case QuizSettings.WORDS_30:
				quizWords.splice(30);
				break;
			case QuizSettings.ALL_WORDS:
				break;
			}
		}
		private function checkRipeness():Array{

			ripeWords 		= new Array();
			notRipeWords 	= new Array();
			
			var allripe:int = 0;
	
			for(var i:int=0; i<mainQuizWords.length;i++){
				var w:Vocab = mainQuizWords[i];
				if(w.isRipe()) ripeWords.push(w);
				else notRipeWords.push(w);
			}
			
			if(!settings.selectedRipenessRipe && !settings.selectedRipenessNotRipe || settings.selectedRipenessRipe && settings.selectedRipenessNotRipe)
				return mainQuizWords.concat();
			if(settings.selectedRipenessRipe){
				return ripeWords.concat();
			}
			return notRipeWords.concat();
		
		}
		public function getVocabsByKnowledge(type:int, words:Array):Array{
		
			var arr2:Array = new Array();
			
			for(var i:int = 0; i<words.length; i++){
				var wrd:Vocab = words[i];
				var perc:Number = wrd.getPercentage(Vocab.CURRENT_KNOWLEDGE);
				switch(type){
					case Vocab.IKNOWTHESE:
						if(perc <= Vocab.IKNOWTHESE_THERSH && perc > Vocab.ALMOST_THERSH) arr2.push(wrd);
						break;
					case Vocab.ALMOST:
						if(perc <= Vocab.ALMOST_THERSH && perc > Vocab.ALITTLE_THERSH) arr2.push(wrd);
						break;
					case Vocab.ALITTLE:
						if(perc <= Vocab.ALITTLE_THERSH && perc > Vocab.WHATSTHAT_THERSH) arr2.push(wrd);
						break;
					case Vocab.WHATSTHAT:
						if(perc <= Vocab.WHATSTHAT_THERSH && perc > Vocab.NOIDEA_THERSH) arr2.push(wrd);
						break;
					case Vocab.NOIDEA:
						if(perc <= Vocab.NOIDEA_THERSH && perc >= 0) arr2.push(wrd);
						break;
					default:
						break;
				}
			}
			return arr2;
		}
		
		private function getMainQuizedWords():Array{	
			
			var all_words:Array = new Array();
			
			//check if user selected "all"
			if(settings.mainQuizContent ==0){
				return allGrammar.concat(allWords);
			}
			
			//check if user selected specific sessions
			if(settings.sessionArray){
			//get all words/grammar from selected sessions
			all_words = addUniques(all_words,getAllWords(settings.sessionArray) );
			}
			if(settings.tagArray.length > 0){
			//get all words from selected tags
			var withTags:Array = DatabaseHelper.getInstance().getWordsWithTags(settings.tagArray);
			all_words = addUniques(all_words,withTags );
			}
			
			
			return all_words;
		}
		private function getAllWords(all_sessions:Array):Array{
			var all_words:Array = new Array();
			for(var i:int = 0; i<all_sessions.length; i++){
				all_words = all_words.concat(all_sessions[i].words);
				all_words = all_words.concat(all_sessions[i].grammar);
			}
			return all_words;
		}
		private function addUniques(all_words:Array, new_words:Array):Array
		{
			for each(var w:Vocab in new_words)
			{
				var test:int = all_words.indexOf(w); 
				var tt:Boolean = false;
				for each(var aw:Vocab in all_words)
				{
					if(w.id == aw.id)
					{
						tt = true;
						break;
					}
				}
				if(!tt)
				all_words.push(w);
			}
			return all_words;
		}
		
		private function shuffle(a:Array):Array {
			for (var i:uint = 0; i < a.length; i++) {
				var tmp:Object = a[i];
				// generate a random number between (inclusive) 0 and the length of the array to shuffle
				var randomNum:Number = Math.round(Math.random() * (a.length-1));
				// the switch
				a[i] = a[randomNum];
				a[randomNum] = tmp;
			}
			return a;
		}
		
		private function sortArray(arr:Array):Array{
			
				return shuffle(arr);
		}
				
	}
}