package mediator
{
	import events.VocabEvent;
	
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	import helpers.DatabaseHelper;
	
	import model.Grammar;
	import model.Sentence;
	import model.Session;
	import model.Word;
	
	import mx.collections.ArrayCollection;
	import mx.controls.Alert;
	import mx.events.CloseEvent;
	import mx.events.IndexChangedEvent;
	
	import views.importing.AddingSentencesView;

	public class AddSentenceMediator extends BaseMediator
	{
		private var _view:AddingSentencesView;
		private var dataGridHasChanged:Boolean = false;
		private var records:Array = new Array();
		
		public function AddSentenceMediator()
		{
			super();
		}
		public function set view(value:AddingSentencesView):void
		{
			_view = value;
		}
		
		public function get view():AddingSentencesView
		{
			return _view;
		}
		override public function register():void
		{
	
			//add eventhandlers 
			view.importbtn.addEventListener(MouseEvent.CLICK, 		importdata);
			view.selectbtn.addEventListener(MouseEvent.CLICK,		selectall);
			view.deselectbtn.addEventListener(MouseEvent.CLICK,		deselectall);
			view.cancelsinglebtn.addEventListener(MouseEvent.CLICK,	assureremove);
			//viewhandling
			view.sessions.addEventListener(Event.CHANGE, 					sessionSelected);
			view.wordscb.addEventListener(Event.CHANGE, 					wordSelected);
			view.selectedGrammar.grammarCb.addEventListener(Event.CHANGE, 	grammarSelected);
			view.vocabtabs.addEventListener(IndexChangedEvent.CHANGE,		assurechange);
			
			//adding Grammar
			view.selectedGrammar.addEventListener(VocabEvent.ADD_GRAMMAR, 	addGrammar);
			
			//session combobox:
			refreshViewData(true, false);
		}
		private function sessionSelected(evt:Event):void{
		
			// Check if a unfinished import is being uprupted
			assurechange();
			
			var selectedSession:Session = view.sessions.selectedItem as Session;
			
			//update tabselector
			view.wordscb.dataProvider = selectedSession.words;
			view.selectedGrammar.grammarCb.dataProvider = selectedSession.grammar;
			view.selectedGrammar.sessionid = selectedSession.id;
		
			refreshViewData();
		}
		private function grammarSelected(evt:Event):void{
		
			//show 
			view.datagridpanel.visible = true;
			
			//fill datagrid
			var gram:Grammar = view.selectedGrammar.grammarCb.dataProvider[view.selectedGrammar.grammarCb.selectedIndex] as Grammar;
			var sentences:Array = gram.sentences;
			fillWithSentences(sentences, 10);
		}
		private function wordSelected(evt:Event):void{
			
			//show 
			view.datagridpanel.visible = true;
			
			//fill datagrid
			var word:Word = view.wordscb.dataProvider[view.wordscb.selectedIndex] as Word;
			var sentences:Array = word.sentences;
			fillWithSentences(sentences, 10);
		}
		private function addGrammar(evt:VocabEvent):void{
			DatabaseHelper.addGrammar(evt.gramm);
			refreshViewData(true, true);
		}
		private function assurechange(evt:IndexChangedEvent = null):void{
			
			if(dataGridHasChanged)
			Alert.show('Are you sure you want to cancel this import?', 'Confirm', 3, view, endImport);
			
			if(view.wordscb.selectedIndex == -1 || view.selectedGrammar.grammarCb.selectedIndex == -1) view.datagridpanel.visible = false;
		}
		private function endImport(event:CloseEvent):void{
			if(event.detail == Alert.YES){
				//if yes, hide datagrid, empty it
				view.datagridpanel.visible = false;
				resetGrid();
			}else{
				//if no, make sure to stay on current selection
			
			}
		}
		private function resetGrid():void{
		
		
		}
		
		private function refreshViewData(refresh:Boolean = false, newGrammar:Boolean = false):void{
			
			var sel_sess:int = view.sessions.selectedIndex;
			var sel_gram:int = view.selectedGrammar.grammarCb.selectedIndex;
			
			if(refresh){
				view.sessions.dataProvider = DatabaseHelper.getInstance().getSessions();
		
				if(sel_sess != -1){
					var sess:Session = view.sessions.dataProvider[sel_sess] as Session;
					view.callLater(function():void{view.callLater(function():void{view.sessions.selectedItem = sess;})});
				
					//refresh words
					view.wordscb.dataProvider = sess.words;
				
					//refresh grammar
					var selGram:int = view.selectedGrammar.grammarCb.selectedIndex;
					view.selectedGrammar.grammarCb.dataProvider = sess.grammar;
					if(newGrammar) view.callLater(function():void{view.callLater(function():void{view.selectedGrammar.grammarCb.selectedIndex = sess.grammar.length-1;})});
				
				}
			}
			
			//update views
			if(sel_sess != -1){
				var isWordsSelected:Boolean 	= (view.vocabtabs.selectedIndex == 0 && view.wordscb.selectedIndex != -1);
				var isGrammarSelected:Boolean 	= (newGrammar)? true : (view.vocabtabs.selectedIndex == 1 && view.selectedGrammar.grammarCb.selectedIndex != -1);
				
				view.datagridpanel.visible 		= (isWordsSelected || isGrammarSelected);
				
				//fill datagrid with sentences
				if(isWordsSelected){
					var word:Word = view.wordscb.dataProvider[view.wordscb.selectedIndex] as Word;
					fillWithSentences(word.sentences, 10);
				}else if(isGrammarSelected){
					var gram:Grammar;
					if(newGrammar)
						gram = view.selectedGrammar.grammarCb.dataProvider[view.selectedGrammar.grammarCb.dataProvider.length-1] as Grammar;
					else
						gram = view.selectedGrammar.grammarCb.dataProvider[sel_gram] as Grammar;
					fillWithSentences(gram.sentences, 10);
				}
			}
			view.vocabtabs.visible 		= (sel_sess != -1);
			view.datagridpanel.visible 	= (sel_sess != -1) && (isWordsSelected || isGrammarSelected);
			
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
					obj.col5 = "1";
					obj.col6 = sentence.id;
					records.push(obj);
				}
			}

			for(var e:int = 0; e<newItems; e++){
					obj = new Object();
					obj.col2 = "";
					obj.col3 = "";
					obj.col4 = "";
					obj.col5 = "0";
					records.push(obj);
			}
			view.setData(records);
		}
		
		private function importdata(evt:MouseEvent):void{
			
			
			var arr:ArrayCollection = view.datagrid.dataProvider as ArrayCollection;
			//validate
			arr = validateItems(arr);
			//return if no words are valid
			if(arr.length == 0){
				Alert.show("No sentences ready to import.","Alert",1);
				return;
			}
			
			
			//add new data
			var isWordsSelected:Boolean 	= (view.vocabtabs.selectedIndex == 0 && view.wordscb.selectedIndex != -1);
			var isGrammarSelected:Boolean 	= (view.vocabtabs.selectedIndex == 1 && view.selectedGrammar.grammarCb.selectedIndex != -1);
			var vocabid:int;
			if(isWordsSelected){
				var word:Word = view.wordscb.dataProvider[view.wordscb.selectedIndex] as Word;
				vocabid = word.id;
			
			}else if(isGrammarSelected){
				var gram:Grammar = view.selectedGrammar.grammarCb.dataProvider[view.selectedGrammar.grammarCb.selectedIndex] as Grammar;
				vocabid = gram.id;
			}
			for(var e:int= 0; e<arr.length; e++){	
				assignSentence(arr[e], vocabid);
				var idx:int = records.indexOf(arr[e]);
				setItemSaved(idx);
			}
			
			refreshViewData(true, false);
			//show aleart of how many words were imported
			Alert.show(arr.length+" Sentences have been saved!","Alert",1);
			
		}
		private function setItemSaved(idx:int):void{
			var item:Object = records[idx] as Object;
			item.col5 = "1";
			view.setData(records);
		}
		private function assignSentence(item:Object, vocab_id:int):void{
			
			var sentence:Sentence;
			
			if(item.col5 == "0"){
				sentence = new Sentence();
				sentence.english 	= item.col2;
				sentence.character 	= item.col4;
				sentence.pinyin 	= item.col3;
				sentence.vocabid 	= vocab_id;
				DatabaseHelper.addSentence(sentence);
			}else if(item.col5 == "2"){
				
				sentence = DatabaseHelper.getInstance().getSentenceById(item.col6);
				
				sentence.english 	= item.col2;
				sentence.character 	= item.col4;
				sentence.pinyin 	= item.col3;
				DatabaseHelper.updateSentence(sentence);
				
			}

			
		}
		private function validateItems(arr:ArrayCollection):ArrayCollection{
			
			var arrnew:ArrayCollection = new ArrayCollection();
			for(var e:int= 0; e<arr.length; e++){	
				var item:Object = arr[e];
				if(item.col5 == "0" || item.col5 == "2"){
					var englishSet:Boolean 		= (item.col2 != "");
					var charorpyninSet:Boolean 	= (item.col3 != "" || item.col4 != "");
					trace(englishSet+", "+charorpyninSet);
					if(englishSet && charorpyninSet) arrnew.addItem(item);
				}
			}
			return arrnew;
		}
		private function assureremove(evt:MouseEvent):void{
			Alert.show('Are you sure you want to cancel this import?', 'Confirm', 3, view, removeSelected);
		}
		

		private function emptyDatagrid():void{
		
		//todo
		}
		private function selectall(evt:MouseEvent):void{
			trace("select all!");
			view.datagrid.selectAllItems();
		}
		
		private function deselectall(evt:MouseEvent):void{
			trace("deselect all!");
			view.datagrid.deselectAllItems();
		}
		private function removeSelected(event:CloseEvent):void{
			
			var arr:Array = view.datagrid.selectedIndices;
			
			if(arr.length == 0){
				Alert.show("Please select a row","Alert",1);
				return;
			}
			
			var tempArr:Array = new Array();
			for each(var selIndex:int in arr){
				tempArr.push(records[selIndex]);
				var obj:Object = records[selIndex] as Object;
				if(obj.col6 != "") DatabaseHelper.deleteSentence(obj.col6);
			}	
			
			for(var w:int= 0; w<tempArr.length; w++){
				var idx:int = records.indexOf(tempArr[w]);
				records.splice(idx, 1);
			}
			
			refreshViewData(true, false);
			view.setData(records);
			
			Alert.show(arr.length+" Sentences have been deleted!","Alert",1);
		}
	}
	
}