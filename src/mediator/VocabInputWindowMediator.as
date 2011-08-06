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
	
	import model.Session;
	import model.Word;
	
	import mx.collections.ArrayCollection;
	import mx.controls.Alert;
	import mx.core.mx_internal;
	import mx.events.CloseEvent;
	import mx.graphics.codec.JPEGEncoder;
	import mx.messaging.channels.StreamingAMFChannel;
	
	import utils.ImageFile;
	
	import views.searchresults.AddVocabWindow;
	
	public class VocabInputWindowMediator extends BaseMediator
	{
		private var _view:AddVocabWindow;
		private var oldTrackHanziValue:Boolean = false;
		private var dataGridHasChanged:Boolean = false;
	
		public function VocabInputWindowMediator(target:IEventDispatcher=null)
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
			view.trackingHanse.selected = oldTrackHanziValue;
			SentenceMediator.getInstance().sentenceWidget = view.sentenceWidget;
			SentenceMediator.getInstance().sentences = view.activeWord.sentences;
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
				if(view.imgwidget.selectedImageData){
				
					//grab image selected
					downloadSelectedImage();
				}else{
					//finish saving
					vocabSubmitted();
				}
			}
		}
		
		private var _selectedImageData:Object;
		
		
		private function getImageFileName():String
		{
			if(_selectedImageData && _selectedImageData.imageURL != "" && view.inputEnglish.text != "")
			{
				var url:String = _selectedImageData.imageURL;
				var urlA:Array = url.split("/");
				var file:String = view.inputEnglish.text + "_" + urlA[urlA.length-1];
				file = unescape(file);
				file = file.replace(/[^a-zA-Z0-9_]/g, ""); //removing any space
				file =  file.substring(0, file.length-4)+".jpg";
				
				return file;
			}
			return "";
			//throw new Error("error generating image file name, please check: getImageFileName method in VocabInputWindowMediator");
			
		}
		
		private function downloadSelectedImage():void
		{
			showSpinner(true, "Downloading Image..");
			if(view.imgwidget.selectedImageData)
			{
				var url:String = view.imgwidget.selectedImageData.imageURL;
				
				if(url && url != "")
				{
					_selectedImageData = view.imgwidget.selectedImageData;
					
					//check if already exist
					if(!ImageFile.Exists(getImageFileName())){			
					
						var loader:Loader = new Loader();
						loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onLoaderComplete);
						loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onLoaderIOError);
					
						var urlRequest:URLRequest = new URLRequest(url);
					
						loader.load(urlRequest);
					
						return;
					}
				}
			}
			
			//if no image selected, finish saving proccess
			vocabSubmitted();
			
		}
		
		private function onLoaderIOError(e:IOErrorEvent):void
		{
			showSpinner(false, "Problem downloading image..");
			Alert.show("Error trying to download selected image, please try with another one.", "Image Problem", 4, view);
		}
		
		private function onLoaderComplete(e:Event):void
		{
			showSpinner(true, "Image Saved..");
			var loader:LoaderInfo = e.target as LoaderInfo;
			loader.removeEventListener(Event.COMPLETE, onLoaderComplete);
			loader.removeEventListener(IOErrorEvent.IO_ERROR, onLoaderIOError);
			
			var bdata:BitmapData = new BitmapData(loader.content.width, loader.content.height, true, 0x00000000);
			var matrix:Matrix = new Matrix();
			bdata.draw(loader.content, matrix,null,null,null,true);
			
			var jpgEncoder:JPEGEncoder = new JPEGEncoder(80);
			var byteArray:ByteArray = jpgEncoder.encode(bdata);
			
			bdata.dispose();
			bdata = null;
			
			//saving to disk
			ImageFile.SaveToDisk(getImageFileName(), byteArray);
			
			
			//finish saving
			vocabSubmitted();
			
			
		}
		
		private function validateVocab():Boolean
		{
			
			var i1:int = (view.inputCharacter.text == "")?0:1;
			var i2:int = (view.inputEnglish.text == "")?0:1;
			var i3:int = (view.inputPinyin.text == "")?0:1;
			
			return (i1 +i2 + i3 >=2)?true:false;
			
		}
		
		private function vocabSubmitted():void
		{
			showSpinner(true, "Saving Word..");
			//Creating word object
			
			var edited:Word 		= view.activeWord;
			edited.english 			= view.inputEnglish.text;
			edited.character 		= view.inputCharacter.text;
			edited.pinyin 			= view.inputPinyin.text;
			edited.groupid 			= Session(view.sessionwidget.sessionsCb.selectedItem).id;
			edited.tagArray 		= view.tagwidget.tags;
			edited.imagePath		= getImageFileName();
			edited.trackedForHanse	= view.trackingHanse.selected;
			oldTrackHanziValue = oldTrackHanziValue;
			
			SentenceMediator.getInstance().saveSentences(view.activeWord.id);
			
			var idx:int = view.tagwidget.tags.indexOf("forCharracter");
			if(view.trackingHanse.selected){
				//make sure the "forCharracter" is part of tags, but just once
				if(idx == -1){
					view.tagwidget.tags.push("forCharracter");
				}
			}else{
				//make sure its not
				if(idx != -1){
					view.tagwidget.tags.splice(idx, 1);
				}
			}
				
			if(view.update)
			{
				DatabaseHelper.updateWord(edited);
			}
			else
			{
				DatabaseHelper.addWord(edited);
			}
			showSpinner(false, "");
			view.closePopup();
			if(view.container)
			view.container.searchInput.setFocus();
			Alert.show("The word has been updated","Notification", 4, view);
		}		
		
		private function assureremove(evt:MouseEvent):void{
			Alert.show('Are you sure you want to remove these sentences?', 'Confirm', 3, view, removeSelected);
		}
		private function removeSelected(event:CloseEvent):void{
			
			SentenceMediator.getInstance().removeSelected();
		}
		

		public function set view( value:AddVocabWindow ):void
		{
			_view = value;
		}
		
		public function get view( ):AddVocabWindow
		{
			return _view;
		}
	}
}