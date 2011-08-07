package mediator
{
	import helpers.DatabaseHelper;
	
	import model.Sentence;
	
	import mx.collections.ArrayCollection;
	import mx.controls.Alert;
	import mx.events.CloseEvent;
	
	import views.viewcomponents.SentenceWidget;

	public class SentenceMediator
	{
		public function SentenceMediator()
		{
		}
		private static var _instance:SentenceMediator;
		public var sentenceWidget:SentenceWidget;
		private var records:Array = new Array();
		private var _sentences:Array = new Array();
		private var sentencesToDelete:Array = new Array();
		public static function getInstance():SentenceMediator
		{
			if(!_instance)
				_instance = new SentenceMediator;
			
			return _instance;
			
		}
		public function set sentences(sen:Array):void{
			
			_sentences = sen;
			fillWithSentences(_sentences, 10);
		}
		public function saveSentences(vocabid:int):void{
		
			var arr:ArrayCollection = sentenceWidget.datagrid.dataProvider as ArrayCollection;
			arr = validateRecords(arr);
			
			//delete sentences removed
			for(var i:int= 0; i<sentencesToDelete.length; i++){
				DatabaseHelper.deleteSentence(sentencesToDelete[i]);
			}
			sentencesToDelete = new Array();
			
			//save others
			for(var e:int= 0; e<arr.length; e++){	
				assignSentence(arr[e], vocabid);
				var idx:int = records.indexOf(arr[e]);
				setItemSaved(idx);
			}
			
		}
		private function fillWithSentences(sentences:Array, newItems:int):void{

			
			var obj:Object;
			records = new Array();
			if(sentences.length > 0){
				for(var i:int = 0; i<sentences.length; i++){
					
					var sentence:Sentence = sentences[i] as Sentence;
					
					obj = new Object();
					
					obj.col2 = sentence.english;
					obj.col3 = sentence.pinyin;
					obj.col4 = sentence.character;
					obj.col5 = SentenceWidget.SAVED_SEN;
					obj.col6 = sentence.id;
					records.push(obj);
				}
			}
			
			for(var e:int = 0; e<newItems; e++){
				obj = new Object();
				obj.col2 = "";
				obj.col3 = "";
				obj.col4 = "";
				obj.col5 = SentenceWidget.NEW_SEN;
				records.push(obj);
			}
			sentenceWidget.setData(records);
		}
		
		
		private function assignSentence(item:Object, vocab_id:int):void{
			
			var sentence:Sentence;
			
			if(item.col5 == SentenceWidget.NEW_SEN){
				sentence = new Sentence();
				sentence.english 	= item.col2;
				sentence.character 	= item.col4;
				sentence.pinyin 	= item.col3;
				sentence.vocabid 	= vocab_id;
				DatabaseHelper.addSentence(sentence);
				
			}else if(item.col5 == SentenceWidget.EDITED_SEN){
				
				sentence = DatabaseHelper.getInstance().getSentenceById(item.col6);
				
				sentence.english 	= item.col2;
				sentence.character 	= item.col4;
				sentence.pinyin 	= item.col3;
				DatabaseHelper.updateSentence(sentence);
				
			}else if(item.col5 == SentenceWidget.DELETED_SEN){
				
				//sentence = DatabaseHelper.getInstance().getSentenceById(item.col6);
				DatabaseHelper.deleteSentence(item.col6);
				
			}
			
			
		}
		//find all new 0 or edited items 2 or items that have been deleted/emptied
		private function validateRecords(arr:ArrayCollection):ArrayCollection{
			
			var arrnew:ArrayCollection = new ArrayCollection();
			var arrtodelete:ArrayCollection = new ArrayCollection();
			for(var e:int= 0; e<arr.length; e++){	
				var item:Object = arr[e];
				if(item.col5 == SentenceWidget.NEW_SEN || item.col5 == SentenceWidget.EDITED_SEN){
					var englishSet:Boolean 		= (item.col2 != "");
					var charorpyninSet:Boolean 	= (item.col3 != "" || item.col4 != "");

					if(englishSet && charorpyninSet) arrnew.addItem(item);
					else if(!englishSet && !charorpyninSet && item.col5 == SentenceWidget.EDITED_SEN){
						item.col5 = SentenceWidget.DELETED_SEN;
						arrtodelete.addItem(item);
					} 
						
				}
			}
			arrnew.source = arrnew.source.concat(arrtodelete.source);
			return arrnew;
		}
		private function setItemSaved(idx:int):void{
			var item:Object = records[idx] as Object;
			item.col5 = "1";
			sentenceWidget.setData(records);
		}
		public function removeSelected():void{
			
			var arr:Array = sentenceWidget.datagrid.selectedIndices;
	
			if(arr.length == 0){
				Alert.show("Please select a row","Alert",1);
				return;
			}

			var tempArr:Array = new Array();
			for each(var selIndex:int in arr){
				tempArr.push(records[selIndex]);
				var obj:Object = records[selIndex] as Object;
				if(obj.col6 != "") sentencesToDelete.push(obj.col6);
			}	
			
			for(var w:int= 0; w<tempArr.length; w++){
				var idx:int = records.indexOf(tempArr[w]);
				records.splice(idx, 1);
			}
			
			sentenceWidget.setData(records);
		}
	}
}