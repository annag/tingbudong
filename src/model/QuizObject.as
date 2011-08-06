package model
{
	import mx.events.IndexChangedEvent;
	
	public class QuizObject extends Object
	{
		import helpers.Memory;
		
		public var quizStatus:int;
		public var myVocab:Vocab;
		public function QuizObject(vcb:Vocab)
		{
			super();
			this.myVocab = vcb;
		}
		
		public function reset():void{ quizStatus = 0; }
		public function sentenceQuized(mastered:Boolean):void{
			quizStatus = (mastered)?1:0;				
			Memory.didPracticeWord(myVocab, mastered, null, Memory.QUIZ_SENTENCE);
		}
		
		public function setQuized(type:int, mastered:Boolean, time:Number):void{
			
			quizStatus = (mastered)?1:0;
			Memory.didPracticeWord(myVocab, mastered, time, type);
		}
		
	}
}