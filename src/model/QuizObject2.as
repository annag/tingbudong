package model
{
	public class QuizObjxxxect extends Object
	{
		import helpers.Memory;
		
		public var quizStatus:int;
		public var myVocab:Vocab;
		public function QuizOxxbject(vcb:Vocab)
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
		
			if(myVocab is Grammar) return;
			quizStatus = (mastered)?1:0;
			Memory.didPracticeWord(myVocab as Word, mastered, time, type);
		}
		
	}
}