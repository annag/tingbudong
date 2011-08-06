package model
{
	public class QuizObjectGrammar
	{
		public function QuizObjectGrammar(grmr:Grammar)
		{
			super();
			this.myGrammar = grmr;
		}
		public var myGrammar:Grammar
		public function reset():void{
			
			quizStatus = 0;
		}
		public function sentenceQuized(mastered:Boolean):void{
			
			quizStatus = (mastered)?1:0;				
			}
			Memory.didPracticeGrammar(myGrammar, true);
		}
	}
}