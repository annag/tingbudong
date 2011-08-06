package helpers
{
	import flash.events.Event;
	
	import model.Vocab;
	import model.Word;
	
	import mx.collections.ArrayCollection;
	import mx.collections.Sort;
	import mx.controls.Alert;
	import mx.core.Application;
	
	import utils.ArrayUtils;

	
	public class Leitner extends Object
	{
		
		public static var NUM_PILES:int = 5;
		private static var pileNo:int = 0;
		public function Leitner()
		{
			super();
		}
		private static function getAllPiles(items:ArrayCollection):ArrayCollection{
			var possiblePiles:ArrayCollection = new ArrayCollection();
			for each(var w:Vocab in items)
			{
				if(!(possiblePiles.contains(w.level)))
				{
					possiblePiles.addItem(w.level);
				}
			}
			return possiblePiles;
		}
/*
 * 
		public static var IKNOWTHESE:Number 	= 1;
		public static var ALMOST:Number 		= 2;
		public static var ALITTLE:Number 		= 3;
		public static var WHATSTHAT:Number 		= 4;
		public static var NOIDEA:Number 		= 5;
		*/
		
		private static function getPropabilities(level:int):Array{
			
			switch(level){
				case Vocab.IKNOWTHESE:
					return new Array(500, 200, 100,  50,  20);
					break;
				case Vocab.ALMOST:
					return new Array(50, 500, 300,  50,  20);
					break;
				case Vocab.ALITTLE:
					return new Array(50, 50, 500,  300,  20);
					break;
				case Vocab.WHATSTHAT:
					return new Array(50, 50, 50,  500,  300);
					break;
				case Vocab.NOIDEA:
					return new Array(50, 50, 50,  100,  500);
					break;

			}
			return new Array(50, 50, 50,  100,  500);
		}
		
		public static function sortArray(arr:Array, level:int):Array{
			
			pileNo = level;
			
			var items:Array = arr.slice();
			var picker:Array = new Array();
			var ratios:Array = [7,1];
			
			var totalnum:int = items.length;
			var totalratio:int = 7+1;
			
			//all items with the chosen level.
			var wordsInPile:ArrayCollection = new ArrayCollection(items);
			wordsInPile.filterFunction = wordfilterfunction;
			wordsInPile.refresh();
			wordsInPile.source = ArrayUtils.shuffleArray(wordsInPile.source);
			
			//all other items
			var wordsNotInPile:ArrayCollection = new ArrayCollection(items);
			wordsNotInPile.filterFunction = wordfilterfunction2;
			wordsNotInPile.refresh();
			wordsNotInPile.source = ArrayUtils.shuffleArray(wordsNotInPile.source);
			
			var arrays:Array = [wordsInPile.source,wordsNotInPile.source];
			
			for(var i:int= 0;i<totalnum; i++){
				var chosenArray:Array;
				do {
					//pick a number between 0 and (1+4)-1
					var pick:Number = Math.floor(Math.random()*totalratio);
					//find corresponding array
					var cumulative:int = 0;
					var e:int;
					for (e=0;e<arrays.length;e++) {
						cumulative+=ratios[e];
						if (cumulative>pick) {
							break;
						}
					}
					chosenArray=arrays[e];
				} while (chosenArray.length==0);
				
				picker.push(chosenArray.pop())
			}
			return picker;
		}

		private static function wordfilterfunction(obj:Vocab):Boolean {
			return (obj.level == pileNo);
		}
		private static function wordfilterfunction2(obj:Vocab):Boolean {
			return (obj.level != pileNo);
		}
	
		/* returns a number between 0 and 1*/
		private static function prob():Number { return Math.random(); }
		
		private function randomElement(arr:Array):int { return Math.random() % arr.length; }
		
		private static function sortByLeitnerOrder(a:Object, b:Object, fields:Array = null):int
		{
			var diff:int = Vocab(a).level - Vocab(b).level;
			if (diff==0) {
				return 0;
			} else if (diff>0) {
				return -1;
			} else {
				return 1;
			}
		}
	
	
	}
}