package helpers
{
	import flash.events.Event;
	import flash.media.Video;
	
	import model.Grammar;
	import model.Vocab;
	import model.Word;
	
	import mx.collections.ArrayCollection;
	import mx.collections.Sort;
	import mx.controls.Alert;
	import mx.core.Application;

	
	public class Memory extends Object
	{
		public static var QUIZ_REVIEW:int 		= 0;
		public static var QUIZ_PICTURE:int 		= 1;
		public static var QUIZ_TIME:int 		= 2;
		public static var QUIZ_FLASHCARDS_1:int = 3;
		public static var QUIZ_FLASHCARDS_2:int = 4;
		public static var QUIZ_SENTENCE:int 	= 5;
		
		
		public static var THRESHHOLD:int = 90;
		private static var DECAY_VALUES:Array = [0.6, //short term
												0.9,// forgotten tomorrow
												0.9486832980505138,//short term
												0.9791483623609768,//mid term
												0.9850612054411155, //mid term
												0.9947458259305311,//long term
												0.9982455322867291,//long term
												0.9994148350777138,//long term
												0.9998049069670882]; //long term
		
		
		public function Memory()
		{
			super();
		}
		
		public static function onAppStart(today:Date, lastopeneddate:Date):void{
			
			trace(today+" //  "+lastopeneddate);
			var days:int = getDaysBetweenDates(lastopeneddate,today);
				
				//go through all words 
				var allwords:Array = DatabaseHelper.getInstance().getAllWords();
				var allGrammar:Array = DatabaseHelper.getInstance().getAllGrammar();
				allwords = allwords.concat(allGrammar);
				for(var i:int=0; i<allwords.length;i++){
					var w:Vocab = allwords[i];
					
					//update knowledge
					overTime(days, w);	
					
					w._ripe = (w.knowledge <=THRESHHOLD);
					if(w is Word) DatabaseHelper.updateWord(w as Word);
					else DatabaseHelper.updateGrammar(w as Grammar);
				}
			}
		
		public static function didPracticeWord(word:Vocab, correct:Boolean, time:Number, type:int):void
		{
			
			word.rec.recordResults(correct, time);
			word.level = -1;
			if(correct){
				
				word.old_k = word.knowledge; 
				
				//TODO: adjust and compare to actual knowledge
				switch(type){
					case QUIZ_REVIEW:
						//has it been succeeded before in this session? dont count up, if not, count up.
						word.knowledge  =  (word.knowledge < Vocab.WHATSTHAT_THERSH)? Vocab.WHATSTHAT_THERSH : word.knowledge;//20
						break;
					case QUIZ_PICTURE:
						word.knowledge =  (word.knowledge < Vocab.ALITTLE_THERSH)? Vocab.ALITTLE_THERSH : word.knowledge;//40
						break;
					case QUIZ_TIME:
						word.knowledge =  (word.knowledge < Vocab.ALITTLE_THERSH)? Vocab.ALITTLE_THERSH : word.knowledge;//40
						break;
					case QUIZ_FLASHCARDS_1:
						word.knowledge =  (word.knowledge < Vocab.ALMOST_THERSH)? Vocab.ALMOST_THERSH : word.knowledge;//60
						break;
					case QUIZ_FLASHCARDS_2:
						if(word.knowledge < Vocab.ALMOST_THERSH)
							word.knowledge = Vocab.ALMOST_THERSH;
						else if(word.knowledge < Vocab.IKNOWTHESE_THERSH)
							word.knowledge = Vocab.IKNOWTHESE_THERSH;
						break;
					case QUIZ_SENTENCE:
						if(word.knowledge < Vocab.ALITTLE_THERSH)
							word.knowledge = Vocab.ALITTLE_THERSH;
						else if(word.knowledge < Vocab.ALMOST_THERSH)
							word.knowledge = Vocab.ALMOST_THERSH;
						else if(word.knowledge < Vocab.IKNOWTHESE_THERSH)
							word.knowledge = Vocab.IKNOWTHESE_THERSH;
						break;
					default:
						break;
				}
				
				if(word.knowledge > 100)word.knowledge=100;
				
				//check if decay rate has changed
				checkDecayRate(word);
			}
			
			//save word to db
			if(word is Grammar){
				DatabaseHelper.updateGrammar(word as Grammar);
			}else{
		  		DatabaseHelper.updateWord(word as Word);
			}
		}
		private static function checkDecayRate(word:Vocab):void{
			trace(word.old_k+" <="+ THRESHHOLD +" && "+ word.knowledge +" > "+THRESHHOLD);
			if (word.old_k <= THRESHHOLD && word.knowledge>THRESHHOLD) {
				word.decayRate_index = (word.decayRate_index >=DECAY_VALUES.length-1)? DECAY_VALUES.length-1 : word.decayRate_index+1;
			}
			trace(word.decayRate_index );
		}
		private static function overTime(days:int, w:Vocab):void{
			var decayRate:Number = DECAY_VALUES[w.decayRate_index];
			if(w.knowledge == 0)return;
			for(var i:int=0;i<days;i++){
				w.knowledge *= decayRate;
			}
			
		}
		private static function getDaysBetweenDates(date1:Date,date2:Date):int
		{
			var one_day:Number = 1000 * 60 * 60 * 24
			var date1_ms:Number = date1.getTime();
			var date2_ms:Number = date2.getTime();
			var difference_ms:Number = Math.abs(date1_ms - date2_ms)
			return Math.round(difference_ms/one_day);
		}
			
	}
}