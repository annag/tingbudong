package mediator
{

	import events.EventManager;
	import events.SessionEvent;
	import events.SessionHeaderEvent;
	
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	import helpers.DatabaseHelper;
	import helpers.Memory;
	import helpers.XMLParsingHelper;
	
	import model.Vocab;
	
	import mx.controls.Alert;
	import mx.core.Application;
	import mx.events.IndexChangedEvent;
	
	import views.Main;
	import views.SessionView;
	
	// ActionScript file
	public class VocabViewManager extends BaseMediator
	{
		private var _view:Main;
		private static var VOCAB_VIEW_TAB:int 	=0;
		private static var VOCAB_INPUT_TAB:int 	=1;
		private static var SETTINGS_TAB:int 	=2;
		private static var IMPORT_VIEW:int 		=3;
		public function VocabViewManager()
		{
			super();
		}
		
		override public function register():void
		{
		
			//quiz
		//	view.removedata_btn.addEventListener(MouseEvent.CLICK, flushVocabData );
		//	view.removevocab_btn.addEventListener(MouseEvent.CLICK, flushVocabData);
		//	view.removevocab_btn.addEventListener(MouseEvent.CLICK,function():void{EventManager.getInstance().dispatchEvent(new Event(EventManager.ResetSettingsEvent));} );
		
			var arr:Array = DatabaseHelper.getInstance().getAllWords();
			view.vocabView.graphvocabview.dataXML 		= XMLParsingHelper.getVocabXML(Vocab.LONG_TERM_KNOWLEDGE, arr);		
			view.vocabView.graphvocabview.start();
			
			view.vocabView.graphsessionsview.dataXML 	= XMLParsingHelper.getSessionXML();		
			view.vocabView.graphsessionsview.start();
			
			view.vocabView.graphtagsview.dataXML 		= XMLParsingHelper.getTagXML();		
			view.vocabView.graphtagsview.start();
			
			
			view.vocabView.addEventListener(SessionEvent.UPDATE_SESSION, updateSession );
			view.vocabView.addEventListener(SessionEvent.DELETE_SESSION, deteleSession );
			
			view.maintabs.addEventListener(IndexChangedEvent.CHANGE, refreshSessionView);
			
			EventManager.getInstance().addEventListener(EventManager.StopQuizEvent, refreshSessionView);
			EventManager.getInstance().addEventListener(EventManager.OpenQuizBaseEvent, hideTabView);
			EventManager.getInstance().addEventListener(EventManager.CloseQuizBaseEvent, showTabView);
			
		
			refreshSessionView();
			onAppStart();
		}
		
		private function deteleSession(evt:SessionEvent):void
		{ 
			
			DatabaseHelper.deleteSession(evt.deleteId); 
			refreshSessionView();
		}
		
		private function updateSession(evt:SessionEvent):void
		{ 
			DatabaseHelper.updateSession(evt.updateId, evt.sessionName);
			refreshSessionView();
		}
		
		private function onAppStart():void
		{
			
			//check last open date
			//if LAST date in the FUTURE - stop process and give a alert
			var lastOpenDate:Date = DatabaseHelper.getLastOpenDate();
			var now:Date = new Date();
			
			if(lastOpenDate>now){
				//SHOW ALERT 
				
				Alert.show("Tingbudong works with the current date and time, it looks like your system time is set in the past, please check","Alert", 4, Application.application.main  , closeApp);
				return;
			}
			DatabaseHelper.refreshLastOpenDate();
		
			Memory.onAppStart(now,lastOpenDate);
		}
		
		private static function closeApp(e:Event):void
		{
			//force close app
			Application.application.close();
				
		}
		
		private function hideTabView(e:Event):void
		{
		
			view.maintabs.visible = false;
			//view.removedata_btn.visible = false;
			view.quizBase.visible = true;
		}
		
		private function showTabView(e:Event):void
		{
			
			view.maintabs.visible = true;
		//	view.removedata_btn.visible = true;
			view.quizBase.visible = false;
			refreshSessionView();
		}
		
		private function refreshSessionView(event:Event =null):void{
			
			var selected_tab:int = view.maintabs.selectedIndex;
			
			switch(selected_tab){
			
				case VOCAB_VIEW_TAB:
					var sessions:Array = DatabaseHelper.getLatestSessions();
					sessions.sort(DatabaseHelper.sessionsSortFunction);
					view.vocabView.sessionView.dataProvider = sessions;
					
					var arr:Array = DatabaseHelper.getInstance().getAllWords();
					view.vocabView.graphvocabview.dataXML = XMLParsingHelper.getVocabXML(Vocab.LONG_TERM_KNOWLEDGE, arr);		
					view.vocabView.graphvocabview.start();
					
					view.vocabView.graphsessionsview.dataXML = XMLParsingHelper.getSessionXML();		
					view.vocabView.graphsessionsview.start();
					
					view.vocabView.graphtagsview.dataXML = XMLParsingHelper.getTagXML();		
					view.vocabView.graphtagsview.start();
					break;
				case VOCAB_INPUT_TAB:
					//do
					view.vocabSearch.searchInput.setFocus();
					break;
				case SETTINGS_TAB:
					EventManager.getInstance().dispatchEvent(new Event(EventManager.UpdateSettingsEvent));
					break;
				case IMPORT_VIEW:
					//view.importvocab.updateData();
					break;
				default:
					break;
			}	
			
		}
		
		public function set view( value:Main ):void
		{
			_view = value;
		}
		
		public function get view( ):Main
		{
			return _view;
		}
		
		private function flushStudyData(event:Event =null):void{
		
			//TODO implement:
			//KEEP ALL WORDS, RESET STUDYVALUES
		
		}
		
		private function flushVocabData(event:Event =null):void{
			DatabaseHelper.clearDatabase();
			refreshSessionView();
		}
		
		
	}
}