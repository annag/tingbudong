package mediator
{
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.MouseEvent;
	import flash.events.ProgressEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.net.FileFilter;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	
	import helpers.DatabaseHelper;
	
	import model.Session;
	import model.Word;
	
	import mx.collections.ArrayCollection;
	import mx.controls.Alert;
	import mx.events.CloseEvent;
	
	import views.importing.ImportingView;
	import views.viewcomponents.Tagwidget;
	
	
	
	public class ImportManager extends BaseMediator
	{

		private var file:File;
		private var records:Array = new Array();
		private var stream:FileStream;
		private var result:String;
		private var _view:ImportingView;
		
		public function ImportManager():void
		{
			super();
		}
		
		override public function register():void
		{
			
			//add eventhandlers 
			view.importbtn.addEventListener(MouseEvent.CLICK, importdata);
			view.cancelbtn.addEventListener(MouseEvent.CLICK,assureremove);
			view.selectbtn.addEventListener(MouseEvent.CLICK,selectall);
			view.deselectbtn.addEventListener(MouseEvent.CLICK,deselectall);
			view.emptyselectbtn.addEventListener(MouseEvent.CLICK,selcetEmpty);
			view.dubselectbtn.addEventListener(MouseEvent.CLICK, selcetDuplicates);
			view.addtagsbtn.addEventListener(MouseEvent.CLICK,addTagsToSelected);
			view.addsessionbtn.addEventListener(MouseEvent.CLICK,addSessionToSelected);
			view.cancelsinglebtn.addEventListener(MouseEvent.CLICK,removeSelected);
			view.btn.addEventListener(MouseEvent.CLICK,browse);
			
			//session combobox:
			view.sessions.dataProvider = DatabaseHelper.getInstance().getSessions();
		}
	
		
		private function importdata(evt:MouseEvent):void{

			var arr:ArrayCollection = view.datagrid.dataProvider as ArrayCollection;
			
			//validate
			arr = validateItems(arr);
			
			//return if no words are valid
			if(arr.length == 0){
				Alert.show("No words ready to import.","Alert",1);
				return;
			}
			
			//add new data
			for(var e:int= 0; e<arr.length; e++){	
				addWord(arr[e]);
			}
			
			//remove lines in datagrid
			for(var i:int= 0; i<arr.length; i++){	
				records.splice(arr[i], 1);
			}
			view.datagrid.dataProvider = records;
			
			//if no lines are left, - hide datagrid
			if(records.length == 0){
				this.showDataGrid(false);
			}
			
			//show aleart of how many words were imported
			Alert.show(arr.length+" Words have been imported!","Alert",1);

		}
		
		private function addWord(item:Object):void{
			
			var newWord:Word = new Word();
			newWord.english 	= item.col1;
			newWord.character 	= item.col3;
			newWord.pinyin 		= item.col2;
			newWord.groupid 	= Session(item.session).id;
			newWord.tagArray 	= item.tags as Array;
			
			DatabaseHelper.addWord(newWord);
		
		}
		private function checkDublicates(arr:Array):Array
		{
			var arrnew:Array = new Array();
			for(var e:int= 0; e<arr.length; e++){	
				var item:Object = arr[e];
				
				var english:String 		= item.col1;
				var character:String 	= item.col3;
				var pinyin:String 		= item.col2;
				var isDup:Boolean = DatabaseHelper.checkDuplicateWord(english, character, pinyin);
				
				if(isDup)
				{
					arrnew.push(e);
				}
			}
			return arrnew;
		}
		private function checkEmpty(arr:Array):Array{
			var arrnew:Array = new Array();
			for(var e:int= 0; e<arr.length; e++){	
				var item:Object = arr[e];
				
				var english:String 		= item.col1;
				var character:String 	= item.col3;
				var pinyin:String 		= item.col2;
				var isEmpty:Boolean = (english =="" && character == "" && pinyin == "");
					
				if(isEmpty)
				{
					arrnew.push(e);
				}
			}
			return arrnew;
		}
		private function validateItems(arr:ArrayCollection):ArrayCollection{
			var arrnew:ArrayCollection = new ArrayCollection();
			for(var e:int= 0; e<arr.length; e++){	
				var item:Object = arr[e];
				
				var englishSet:Boolean = (item.col1 != "");
				var charorpyninSet:Boolean = (item.col2 != "" || item.col3 != "");
				var sessionSet:Boolean = (item.col4 != "");
				
				if(englishSet && charorpyninSet && sessionSet){
					arrnew.addItem(item);
				}
			}
			return arrnew;
		}
		private function selcetEmpty(evt:MouseEvent):void{
			
			var arr:Array = checkEmpty(this.records);
			
			view.datagrid.selectedIndices = arr;
		}
		private function selcetDuplicates(evt:MouseEvent):void{
			
			var arr:Array = checkDublicates(this.records);
			
			view.datagrid.selectedIndices = arr;
		}
		private function removeSelected(evt:MouseEvent):void{
		
			//remove selected lines
			//get selected lines
			var arr:Array = view.datagrid.selectedIndices;
			
			if(arr.length == 0){
				Alert.show("Please select a row","Alert",1);
				return;
			}
			var tempArr:Array = new Array();
			for each(var selIndex:int in arr){
				tempArr.push(records[selIndex]);	
			}	
				
			for(var w:int= 0; w<tempArr.length; w++){
				
				var idx:int = records.indexOf(tempArr[w]);
				records.splice(idx, 1);
			}
			view.datagrid.dataProvider = records;
		}
		private function addSessionToSelected(evt:MouseEvent):void{
			
			//get selected session
			var sess:Session = view.sessions.selectedItem as Session;
			if(sess == null)
			{
			Alert.show("Please select a session.", "Alert",1);
			return;
			}
			//get selected lines
			var arr:Array = view.datagrid.selectedIndices;
			//PROCESS DATA TODO
			
			if(arr.length == 0){
				Alert.show("Please select a row","Alert",1);
				return;
			}
			//fill correct column in selected lines with session name
			for(var e:int= 0; e<arr.length; e++){	
					var obj:Object = records[arr[e]];
					obj.col4 = sess.name;
					obj.session = sess;
			}
			view.datagrid.dataProvider = records;
			
		}
		private function addTagsToSelected(evt:MouseEvent):void{
		
			
			
			var arr:Array = view.datagrid.selectedIndices;
			if(arr.length == 0){
				Alert.show("Please select a row","Alert",1);
				return;
			}
			if(view.inputTags.text == "" || view.inputTags.text == " " || view.inputTags.text == view.inputTags.prompt){
				Alert.show("Please enter a tag","Alert",1);
				return;
			}
			//get new tags
			var arr2:Array = Tagwidget.settagArray(view.inputTags.text);

			//fill correct column in selected lines with tag name
			for(var e:int= 0; e<arr.length; e++){	
				//??
				var obj:Object = records[arr[e]];
				var temparr:Array = arr2.slice();
				if(obj.tags){
					temparr = obj.tags.concat(temparr);
				}
				obj.col5 = temparr.toString();
				obj.tags = temparr;
			}
			view.datagrid.dataProvider = records;
		}
		private function assureremove(evt:MouseEvent):void{
		
			Alert.show('Are you sure you want to cancel this import?', 'Confirm', 3, view, cancelimport);
		}
		private function cancelimport(event:CloseEvent):void{
			if(event.detail == Alert.YES){
				records = new Array();
				view.datagrid.dataProvider = records;
				this.showDataGrid(false);
			}
		}
		private function selectall(evt:MouseEvent):void{
			trace("select all!");
			view.datagrid.selectAllItems();
		

		}
		private function deselectall(evt:MouseEvent):void{
		
			trace("deselect all!");
			view.datagrid.deselectAllItems();
		}
		private function browse(evt:MouseEvent):void 
		{
            file = new File();
            file.addEventListener(Event.SELECT, file_select);
            var csvFilter:FileFilter = new FileFilter("CSV", "*.csv;");
            
            file.browseForOpen("Please select a file...", [csvFilter]);
            file.addEventListener(Event.SELECT, fileselected);
        }
 			
 		private function fileselected(evt:Event):void
		{
 			result = "";
            stream = new FileStream();
            stream.addEventListener(ProgressEvent.PROGRESS, fileProgress);
            stream.addEventListener(Event.COMPLETE, eventComplete);
            stream.addEventListener(IOErrorEvent.IO_ERROR, onIOError); 
            stream.openAsync(File(evt.currentTarget), FileMode.READ);
			showDataGrid(true);
 		}
 		
		private function fileProgress(evt:ProgressEvent):void{
 			       
 			
 		}
 		private function showDataGrid(visible:Boolean):void{
			
			view.datagridpanel.visible 	= visible;
			view.contentItems.visible 	= visible;
			view.contentItems2.visible 	= visible;
			view.contentItems3.visible 	= visible;
		}

		private function eventComplete(evt:Event):void{
			
			result = stream.readUTFBytes(stream.bytesAvailable);
 			stream.close();
 			var fields:Array 	= new Array();
 			var obj:Object 	= new Object();
 			var record:Array 	= new Array();
 			
			trace(result)
			result = result.split("\"").join("");
			record = result.split("\n");
			
			for(var i:int = 0; i<record.length; i++){
				if(record[i] != ""){
					obj = new Object();
					fields = record[i].split(",");
					fields
					obj.col1 = fields[0];
					obj.col2 = fields[1];
					obj.col3 = fields[2];
					obj.col4 = "";
					obj.col5 = "";
					records.push(obj);
				}
			}
			view.datagrid.dataProvider = records;
			//evaluate all lines
			//return a array of lines that are complete and ready for import
			//color those lines a certain color
			
			//list.dataProvider = records;
 		}
 		
		private function onIOError(evt:Event):void{
 				//Alert.show("I/O Error: "+evt.type);
 		}
		
		private function file_select(evt:Event):void {
            view.browse_lbl.text = File(evt.currentTarget).nativePath;
            var request:URLRequest = new URLRequest;
 			request.url = File(evt.currentTarget).nativePath;//"./Test.csv";
 			var loader:URLLoader = new URLLoader;
 			loader.dataFormat = URLLoaderDataFormat.TEXT;
 			loader.addEventListener(Event.COMPLETE, eventComplete);
 			loader.addEventListener(IOErrorEvent.IO_ERROR, onIOError); 
 			loader.load(request);
        }
		
		public function set view(value:ImportingView):void
		{
			_view = value;
		}
		
		public function get view():ImportingView
		{
			return _view;
		}
			
	}
}

