package mediator
{
	import events.VocabEvent;
	
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.IEventDispatcher;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.ui.Keyboard;
	
	import helpers.CDictHelper;
	import helpers.DatabaseHelper;
	
	import model.Grammar;
	import model.Vocab;
	import model.Word;
	
	import mx.containers.TitleWindow;
	import mx.controls.Alert;
	import mx.core.Application;
	import mx.events.CloseEvent;
	import mx.managers.PopUpManager;
	
	import views.Main;
	import views.VocabSearch;
	import views.searchresults.AddGramWindow;
	import views.searchresults.AddVocabWindow;
	
	public class VocabSearchMediator extends BaseMediator
	{
		private var _mainView:Main;
		private var _view:VocabSearch;
		
		public function VocabSearchMediator()
		{
			super();
		}
		
		override public function register():void{
			
			//vocab search event listeners
			view.searchButton.addEventListener(MouseEvent.CLICK, onSearchButtonClick );
			view.searchInput.addEventListener(KeyboardEvent.KEY_UP, keyUpListener);
			view.searchDictionary.addEventListener(MouseEvent.CLICK, onSearchButtonClick);
			view.searchMyWords.addEventListener(MouseEvent.CLICK, onSearchButtonClick);
			view.resultscontainer.addEventListener(VocabEvent.ADD_VOCAB, openWord);
			view.resultscontainer.addEventListener(VocabEvent.DELETE_VOCAB, deleteVocab);
			view.resultscontainer.addEventListener(VocabEvent.UPDATE_VOCAB, openWord);
			view.resultscontainer.addEventListener(VocabEvent.UPDATE_GRAMMAR, openGrammar);
			view.resultscontainer.addEventListener(VocabEvent.RESET_VOCAB, resetVocab,false,0,true);
			view.addButton.addEventListener(MouseEvent.CLICK, openWordAdd );
			view.addgButton.addEventListener(MouseEvent.CLICK, openGrammarAdd );
			
		}
		private function keyUpListener(e:KeyboardEvent):void{
		
			if(e.keyCode == Keyboard.ENTER){
				onSearchButtonClick();
			
			}
		}
		public function set view( value:VocabSearch ):void
		{
			_view = value;
		}
		
		public function get view( ):VocabSearch
		{
			return _view;
		}
		private function deleteVocab(e:VocabEvent):void{
		
			if(e.vocab is Word)
				DatabaseHelper.deleteWord(e.vocab.id);
			else if(e.vocab is Grammar)
				DatabaseHelper.deleteGrammar(e.vocab.id);
			onSearchButtonClick();
		
		}
		
		private function openWord(e:VocabEvent):void{
			openPopup( "word",e)
			
		}
		private function openGrammar(e:VocabEvent):void{
			openPopup("grammar",e)
			
		}
		private function resetVocab(e:VocabEvent):void{
			DatabaseHelper.resetVocab(e.vocab.id);
			onSearchButtonClick();
			//_view.resultscontainer.dataProvider = new Array(new Array(), new Array());
			//this.dataProvider = DatabaseHelper.getInstance().getSession(Session(_dataProvider).id);
			//cleanView();
			//populateView();
			
		}
		private function openPopup( type:String, e:VocabEvent = null):void{
			
			
			if(type == "grammar"){
				var gWin:AddGramWindow = new AddGramWindow();
				gWin.container = _view;
				if(e== null){
					gWin.activeGrammar = new Grammar();
					gWin.update = false;
				}else{
					gWin.activeGrammar = e.gramm;
					gWin.update = (e.type == VocabEvent.UPDATE_GRAMMAR);
				}
				gWin.addEventListener("close", didClose);
				PopUpManager.addPopUp( gWin, Application.application as DisplayObject, true );
				PopUpManager.centerPopUp( gWin );
			}else{
				var wWin:AddVocabWindow = new AddVocabWindow();
				wWin.container = _view;
				if(e== null){
					wWin.activeWord = new Word();
					wWin.update = false;
				}else{
					wWin.activeWord = e.vocab as Word;
					wWin.update = (e.type == VocabEvent.UPDATE_VOCAB);
				}
				wWin.addEventListener("close", didClose);
				PopUpManager.addPopUp( wWin, Application.application as DisplayObject, true );
				PopUpManager.centerPopUp( wWin );
			}

		}
		private function didClose(e:Event):void{
			
			var sWin:DisplayObject = e.target as DisplayObject;
			sWin.removeEventListener("close", didClose);
			onSearchButtonClick();
			//_view.resultscontainer.dataProvider = new Array(new Array(), new Array());
			
		}
		protected function onSearchButtonClick(event:Event=null):void
		{
			
			var response:Array;
			var testresponse:Array ;
			var res:Array; 
			if(view.searchInput.text == "" || view.searchInput.text == " ") return;
			
			if(view.searchWords.selected){
			if(view.searchDictionary.selected && view.searchMyWords.selected)
			{
				response 		= DatabaseHelper.getInstance().getWordsWithSearchString(view.searchInput.text, 100);
				testresponse 	= CDictHelper.getInstance().search(view.searchInput.text, 100);
			}
			else if(view.searchDictionary.selected)
			{
				response		= new Array();
				testresponse 	= CDictHelper.getInstance().search(view.searchInput.text, 100);
			}
			else if(view.searchMyWords.selected)
			{
				response 		= DatabaseHelper.getInstance().getWordsWithSearchString(view.searchInput.text, 100);
				testresponse 	= new Array();
			}
			else
			{
				response 		= new Array();
				testresponse 	= new Array();
				
			}
		
			
			}else{
				response 		= DatabaseHelper.getInstance().getGrammarWithSearchString(view.searchInput.text, 100);
				testresponse = new Array();
			}
			view.resultsNr.text = response.length+" words found in your words, "+testresponse.length+" found in the dictionairy.";
			
			res = new Array(response, testresponse);
			_view.resultscontainer.dataProvider = res;
		}
		private function openGrammarAdd(event:MouseEvent):void{ openPopup( "grammar");  }
		private function openWordAdd(event:MouseEvent):void{ openPopup("word");  }
	}
}