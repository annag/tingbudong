package mediator
{
	import events.SessionEvent;
	import events.VocabEvent;
	
	import flash.events.MouseEvent;
	
	import helpers.DatabaseHelper;
	
	import model.Session;
	import model.Word;
	
	import mx.controls.Alert;
	import mx.events.ListEvent;
	
	import views.Main;
	import views.VocabInput;

	
	public class VocabInputMediator extends BaseMediator
	{
		private var _mainView:Main;
		private var _view:VocabInput;
		private var editedWord:Word;
		
		public function VocabInputMediator()
		{
			super();
		}
		
		override public function register():void{
			
			//vocab input event listeners
			view.submitBtn.addEventListener(MouseEvent.CLICK, validate );
			view.addEventListener(SessionEvent.NEW_SESSION, addSession );
			view.clearBtn.addEventListener(MouseEvent.CLICK, clearInputForm );
			view.sessionwidget.sessionsCb.addEventListener(ListEvent.CHANGE, onSelectedSession);
			//vocab listenings event listeners
		
			view.deleteessionbtn.addEventListener(MouseEvent.CLICK, deleteSession);
			view.editsessionbtn.addEventListener(MouseEvent.CLICK, updateSession);
			view.sessionView.addEventListener(VocabEvent.DELETE_VOCAB, deleteVocab);
			view.sessionView.addEventListener(VocabEvent.UPDATE_VOCAB, editWord);
			
			view.sessionwidget.dataProvider = DatabaseHelper.getInstance().getSessions();
		//	view.submitBtn.enabled = false;
			refreshSessionView();
			
		
		}
		/*****************************************ITNERFACE HANDLING*************************************/
		
		private function onSelectedSession(evt:ListEvent):void{
		
			view.submitBtn.enabled = true;
			var sess:Session = view.sessionwidget.sessionsCb.selectedItem as Session;
			refreshSessionView(sess.id);
		}
		private function refreshSessionView(sessId:int = -1):void{
			
			if(sessId !=-1){
				var session:Session = DatabaseHelper.getInstance().getSession(sessId);
				view.sessionView.session = session;
			}else if(view.sessionView.session != null){
				var session2:Session = DatabaseHelper.getInstance().getSession(view.sessionView.session.id);
				view.sessionView.session = session2;
			}
			
		}
		/************************************** SESSION CRUD*********************************************/
		private function addSession(evt:SessionEvent):void{
			var session:Session = new Session();
				session.name = evt.sessionName;
			
			DatabaseHelper.addSession(session);
			
			view.setSessionsArray(DatabaseHelper.getInstance().getSessions());	
			view.sessionwidget.dataProvider = DatabaseHelper.getInstance().getSessions();
			session = DatabaseHelper.getInstance().getSessionByName(evt.sessionName);
		//	view.sessionwidget.selectedItemCandidate=session;
			view.callLater(function():void{view.callLater(function():void{view.sessionwidget.sessionsCb.selectedItem = session;})});
			Alert.show("Session has been added","Notification",1);
			this.refreshSessionView();	
		}
		private function deleteSession(evt:MouseEvent):void{
			if(view.sessionwidget.sessionsCb.selectedIndex == -1){
				Alert.show("Please choose a session to delete it.", "Alert", 4, null);
			}else{
			Alert.show("Do you really want to delete this session?", "Alert", 4, view, processDelete);
			}
		}
		
		private function processDelete(evt:Event):void{
			
			//remove from data
			DatabaseHelper.getInstance().deleteSession(view.sessionView.session);
			view.sessionwidget.dataProvider = DatabaseHelper.getInstance().getSessions();
			view.sessionView.session = null;
			//update sessionview
			this.refreshSessionView();
		
		}
		private function updateSession(evt:SessionEvent):void{
		//TODO implement update session
			//enter into textfield
			//change add button to edit
			//disable the edit&delete
		}
		/************************************** WORD CRUD*********************************************/
		
		private function validate(evt:MouseEvent):void{
	
			if(view.sessionwidget.sessionsCb.selectedIndex == -1){
				Alert.show("Please choose a session to add the word!", "validate", 4, null);
			}else if(!validateVocab()){
				Alert.show("Please fill at least 2 of the 3 fields to add the word!", "validate", 4, null);
			}else{
				vocabSubmitted(evt);
			}
		}
		private function validateVocab():Boolean{
		
		var i1:int = (view.inputCharacter.text == "")?0:1;
		var i2:int = (view.inputEnglish.text == "")?0:1;
		var i3:int = (view.inputPinyin.text == "")?0:1;
		
		return (i1 +i2 + i3 >=2)?true:false;
		
		}
		private function vocabSubmitted(evt:MouseEvent):void{
			//Creating word object
			
			if(view.dataProvider)
			{
				var edited:Word 		= view.dataProvider;
					edited.english 		= view.inputEnglish.text;
					edited.character 	= view.inputCharacter.text;
					edited.pinyin 		= view.inputPinyin.text;
					edited.groupid 		= Session(view.sessionwidget.sessionsCb.selectedItem).id;
					edited.tagArray 	= view.tagwidget.tags;
					edited.imagePath	= view.inputIMGPath.text;
					edited.trackedForHanse	= view.trackingHanse.selected;
					DatabaseHelper.updateWord(edited);
			}
			else
			{
				
				var newWord:Word = new Word();
					newWord.english 	= view.inputEnglish.text;
					newWord.character 	= view.inputCharacter.text;
					newWord.pinyin 		= view.inputPinyin.text;
					newWord.groupid 	= Session(view.sessionwidget.sessionsCb.selectedItem).id;
					newWord.tagArray 	= view.tagwidget.tags;
					newWord.imagePath	= view.inputIMGPath.text;
					newWord.trackedForHanse	= view.trackingHanse.selected;
					
					DatabaseHelper.addWord(newWord);
				
			}
			
			
			cleanVocabInputView();
			Alert.show("The word has been updated","Notification", 4);
			refreshSessionView();
		}
		private function clearInputForm(evt:MouseEvent = null):void{
			
			view.clearForm();
			this.editedWord = null;
		
		}
		private function deleteVocab(evt:VocabEvent):void{
			DatabaseHelper.deleteWord(evt.vocab.id);
			this.clearInputForm();
			refreshSessionView();
		}
	
		private function editWord(evt:VocabEvent):void{

			view.dataProvider = evt.vocab;
			
		}
		private function cleanVocabInputView():void
		{
			view.clearForm();
		}
		
		public function set view( value:VocabInput ):void
		{
			_view = value;
		}
		
		public function get view( ):VocabInput
		{
			return _view;
		}
	}
}