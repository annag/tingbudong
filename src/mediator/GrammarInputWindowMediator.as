package mediator
{
	import events.SessionEvent;
	
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.events.Event;
	import flash.events.IEventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.MouseEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.geom.Matrix;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	
	import helpers.DatabaseHelper;
	
	import model.Grammar;
	import model.Session;
	import model.Word;
	
	import mx.collections.ArrayCollection;
	import mx.controls.Alert;
	import mx.core.mx_internal;
	import mx.events.CloseEvent;
	import mx.graphics.codec.JPEGEncoder;
	import mx.messaging.channels.StreamingAMFChannel;
	
	import utils.ImageFile;
	
	import views.searchresults.AddGramWindow;
	
	public class GrammarInputWindowMediator extends BaseMediator
	{
		private var _view:AddGramWindow;
		private var oldTrackHanziValue:Boolean = false;
		private var dataGridHasChanged:Boolean = false;
	
		public function GrammarInputWindowMediator(target:IEventDispatcher=null)
		{
			super(target);
		}
		
		override public function register():void{
		
			//vocab input event listeners
			view.submitbtn.addEventListener(MouseEvent.CLICK, validate );
			view.addEventListener(SessionEvent.NEW_SESSION, addSession );
			//vocab listenings event listeners
			
			view.sessionwidget.dataProvider = DatabaseHelper.getInstance().getSessions();
			view.sessionwidget.sessionsCb.selectedIndex = 0;
			view.addEventListener("newWindow", populateView);
		}
		public function populateView(evt:Event):void{
			SentenceMediator.getInstance().sentenceWidget = view.sentenceWidget;
			SentenceMediator.getInstance().sentences = view.activeGrammar.sentences;
		}
		public function destroy():void{
		
			view.submitbtn.removeEventListener(MouseEvent.CLICK, validate);
			view.removeEventListener(SessionEvent.NEW_SESSION, addSession);
		
		}
		/********************INTERFACE*********************/
		private function showSpinner(show:Boolean, message:String):void{
			view.spinnermsg.text = message;
			view.spinner.visible = show;
		
		}
		/************************************** SESSIONS*********************************************/
		private function addSession(evt:SessionEvent):void{
		
			var session:Session = new Session();
			session.name = evt.sessionName;
			
			DatabaseHelper.addSession(session);
			
			view.sessionwidget.dataProvider = DatabaseHelper.getInstance().getSessions();
			
			view.sessionwidget.sessionsCb.selectedIndex = 0;
			
			Alert.show("Session has been added","Notification",1, view);

		}
		/************************************** INTERFACE*********************************************/
		private function validate(evt:MouseEvent):void{
			
			if(view.sessionwidget.sessionsCb.selectedIndex == -1)
			{
				Alert.show("Please choose a session to add the word!", "validate", 4, view);
			}
			else if(!validateVocab())
			{
				Alert.show("Please fill at least 2 of the 3 fields to add the word!", "validate", 4, view);
			}
			else
			{
				//finish saving
				vocabSubmitted();

			}
		}
		
	

		private function validateVocab():Boolean
		{
			return (view.pinyintxt.text != "" && view.englishtxt.text != "");
			
		}
		
		private function vocabSubmitted():void
		{
			showSpinner(true, "Saving Grammar..");
			//Creating word object
			
			var edited:Grammar 		= view.activeGrammar;
			edited.pinyin 			= view.pinyintxt.text
			edited.english 			= view.englishtxt.text
			edited.groupid 			= Session(view.sessionwidget.sessionsCb.selectedItem).id;

		
			if(!view.update)
			{
				DatabaseHelper.addGrammar(edited);
				var arr:Array = DatabaseHelper.getInstance().getGrammarByPinyin(edited.pinyin);
				edited = arr[0]; 
			}
			SentenceMediator.getInstance().saveSentences(view.activeGrammar.id);
			DatabaseHelper.updateGrammar(edited);
			
			
			showSpinner(false, "");
			view.closePopup();
			if(view.container) view.container.searchInput.setFocus();
			Alert.show("The grammar has been updated","Notification", 4, view);
		}		
		
		
		
		
		
		
		
		
		private function assureremove(evt:MouseEvent):void{
			Alert.show('Are you sure you want to remove these sentences?', 'Confirm', 3, view, removeSelected);
		}
		private function removeSelected(event:CloseEvent):void{
			
			SentenceMediator.getInstance().removeSelected();
		}
		

		public function set view( value:AddGramWindow ):void
		{
			_view = value;
		}
		
		public function get view( ):AddGramWindow
		{
			return _view;
		}
	}
}