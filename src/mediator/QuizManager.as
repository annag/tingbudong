package mediator
{
	import events.EventManager;
	import events.SelectArrayEvent;
	
	import flash.desktop.DockIcon;
	import flash.desktop.NativeApplication;
	import flash.desktop.SystemTrayIcon;
	import flash.display.NativeWindow;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.utils.getTimer;
	
	import helpers.AIRUtils;
	import helpers.DatabaseHelper;
	
	import model.QuizSettings;
	import model.QuizVocabulary;
	import model.Session;
	import model.Vocab;
	import model.Word;
	
	import mx.controls.Alert;
	import mx.core.Window;
	import mx.managers.PopUpManager;
	
	import utils.DisplayUtils;
	
	import views.SelectSessionsView;
	import views.SettingsView;
	import views.quizes.QuizView;
	import views.quizes.QuizView1;
	import views.quizes.QuizView3;
	import views.quizes.Quizview2;

	public class QuizManager extends BaseMediator
	{
		/***********************************************/
		/*VARIABLES*/
		/***********************************************/
		//stores current settings the user sets in settingsview
		private var settings:QuizSettings;
		//stores and sorts quiz-words based on settings
		public var quizVocab:QuizVocabulary;
		private var settingsView:SettingsView;
		
		private var oldselectedsessions:Array;
		private var oldselectedtags:Array;
		
		private var allsessions:Array;
		private var allWords:Array;
		private var allGrammar:Array;
		
		public static var IKNOWTHESE:Number = 1;
		public static var ALMOST:Number 	= 2;
		public static var ALITTLE:Number 	= 3;
		public static var WHATSTHAT:Number 	= 4;
		public static var NOIDEA:Number 	= 5;
		/***********************************************/
		/*CONSTRUCTOR*/
		/***********************************************/
		public function QuizManager()
		{
			super();
		}
		
		/*register the mediator and event listeners*/
		override public function register():void{
	
			settings 	= loadQuizSettings();
			quizVocab 	= QuizVocabulary.getInstance();
			
			
			//onselection
			view.selectionRadioGroup.addEventListener(Event.CHANGE, updateSelection);
			view.sessionselctor.addEventListener(Event.CHANGE, 		updateSelection);
			view.tagselector.addEventListener(Event.CHANGE, 		updateSelection);
			
			view.limitWords.addEventListener(Event.CHANGE, 			updateSettings);
			view.ripetoremember.addEventListener(Event.CHANGE, 		updateSettings);
			view.rottenforgotten.addEventListener(Event.CHANGE, 	updateSettings);
			view.selectionRadioGroup.addEventListener(Event.CHANGE, updateSettings);
			view.sessionselctor.addEventListener(Event.CHANGE, 		updateSettings);
			view.tagselector.addEventListener(Event.CHANGE, 		updateSettings);
			//view.mainSelectionRadioGroup.addEventListener(Event.CHANGE, updateSettings);
			
			EventManager.getInstance().addEventListener(EventManager.UpdateSettingsEvent , populateView);
			EventManager.getInstance().addEventListener(EventManager.ResetSettingsEvent , resetQuizSettings);
			
			view.quizBtn2.addEventListener(MouseEvent.CLICK, gotNextStep);
			
			populateView();

		}
		/***********************************************/
		/*PUBLIC FUNCTIONS*/
		/***********************************************/
		//populates settings view with settings + number of words
		public function populateView(e:Event= null):void
		{

			allsessions = DatabaseHelper.getInstance().getSessions();
			allWords 	= DatabaseHelper.getInstance().getAllWords();
			allGrammar 	= DatabaseHelper.getInstance().getAllGrammar();
			
			
			quizVocab.allGrammar 	= allGrammar;
			quizVocab.allWords 		= allWords;
			

			//fill datagrids
			view.sessionselctor.dataProvider 	= getSessionVisuals(allsessions);
			
			var tagsArr:Array = DatabaseHelper.getInstance().getTags();
			view.tagselector.dataProvider 		= getTagVisuals(tagsArr);
			
			setSettings();
		}
		/***********************************************/
		/*PRIVATE FUNCTIONS*/
		/***********************************************/
		private function gotNextStep(evt:Event):void{
			if(this.quizVocab.quizWords.length == 0){
				Alert.show("Please add words to take a quiz.","Alert",1);
				return;
			}
			for(var i:int=0;i<quizVocab.quizWords.length;i++){
				
				var vcb:Vocab = quizVocab.quizWords[i];
				vcb.quizObj.reset(); 
			}
			EventManager.getInstance().dispatchEvent(new Event(EventManager.OpenQuizBaseEvent));
		}
		private function updateSelection(evt:Event):void{
			
			var targetvalueAll:Boolean = false;
			targetvalueAll = (evt.target == view.selectionRadioGroup);
			
			var targetvalueSpecific:Boolean= false;
			targetvalueSpecific = (evt.target == view.sessionselctor || evt.target == view.tagselector);
			
			if(targetvalueAll && view.selectionRadioGroup.selectedValue == 0){
				//all words are selected: deselect the sessions
				oldselectedsessions = view.sessionselctor.selectedIndices;
				view.sessionselctor.deselectAllItems();
				oldselectedtags = view.tagselector.selectedIndices;
				view.tagselector.deselectAllItems();
			}else if(targetvalueAll && view.selectionRadioGroup.selectedValue == 1){
				view.sessionselctor.selectedIndices = oldselectedsessions;
				view.tagselector.selectedIndices 	= oldselectedtags;
			}else if(targetvalueSpecific && (view.tagselector.selectedIndices.length >0 || view.sessionselctor.selectedIndices.length >0)){
				view.selectionRadioGroup.selectedValue = 1;
			}else if(targetvalueSpecific && (view.tagselector.selectedIndices.length ==0 && view.sessionselctor.selectedIndices.length ==0)){
				view.selectionRadioGroup.selectedValue = 0;
			}
		}
		
		/**
		 * populate the settings view with the values recorded in the settings object
		 **/
		public function setSettings():void{
			
			//ripeness box
			view.ripetoremember.selected					= settings.selectedRipenessRipe;
			view.rottenforgotten.selected					= settings.selectedRipenessNotRipe;
			
			//final box
			view.limitWords.selectedIndex					= settings.limitWordsIndex;
			view.selectionRadioGroup.selectedValue			= settings.mainQuizContent;
			
			//sessions box
			if(this.settings.sArray != null && view.selectionRadioGroup.selectedValue == 1){
				view.sessionselctor.selectedIndices = settings.sArray.slice();
				view.sessionselctor.invalidateProperties();
			}else if(this.settings.sArray != null && view.selectionRadioGroup.selectedValue == 0){
				this.oldselectedsessions = settings.sArray.slice();
			}
			if(this.settings.tArray != null && view.selectionRadioGroup.selectedValue == 1){
				view.tagselector.selectedIndices = settings.tArray.slice();
			}else if(this.settings.tArray != null && view.selectionRadioGroup.selectedValue == 0){
				this.oldselectedtags = settings.tArray.slice();
			
			}
	
			this.settings.setWordArrays();
			
			quizVocab.update(settings);
			
			setRipeFromSelection();
			
			var allVocab:int = allWords.concat(allGrammar).length;
			view.updateSessions_txt.text 	= allsessions.length.toString()+" sessions and "+allVocab.toString()+" vocabulary";
			view.update_txt.text 			= quizVocab.quizWords.length.toString();
		}
		
		/**
		 * Load Quiz settings object from disk
		 **/
		private function loadQuizSettings():QuizSettings
		{ 
			var qs:QuizSettings = AIRUtils.readFileObject(QuizSettings.quizSettingsFile) as QuizSettings
				
			if(!qs)
			{
				qs = resetQuizSettings();
			}
			
			return qs;
				
		}
		public function resetQuizSettings(evt:Event = null):QuizSettings
		{
			var qs:QuizSettings = new QuizSettings();
			qs = QuizSettings.getDefaultSettings();
			qs.save();
			settings = qs
			return qs;
		}
		
		
		private function getTagVisuals(arr:Array):Array{
			
			trace("------"+arr.length);
			var newArr:Array = new Array();
			var obj:Object;
			var arr2:Array;
			for each(var str:String in arr){
				obj = new Object();
				obj.name 	= str;
				arr2 = DatabaseHelper.getInstance().getWordsWithTags(new Array(str));
				obj.wordlen = arr2.length;
				obj.level 	= DatabaseHelper.getInstance().getLevelofTag(arr2);
				newArr.push(obj);
			}
			return newArr;
		}
		
	
		private function getSessionVisuals(arr:Array):Array{
			
			var newArr:Array = new Array();
			var obj:Object;
			for each(var sess:Session in arr){
				obj = new Object();
				obj.name 	= sess.name
				obj.wordlen = sess.vocabulary.length;
				obj.level 	= DatabaseHelper.getInstance().getLevelOfWords(sess.vocabulary);
				newArr.push(obj);
			}
			return newArr;
		}
		

	
		private function getHeight(sessions:int, perLine:int):int{
			
			var c:int = sessions >= perLine ? perLine: sessions;
			return 280;
		}
		private function getWidth(sessions:int, perLine:int):int{
			var c:int = Math.ceil(sessions/perLine);
			if(c > 2){
				return  20+90*c;
			}else{
				return 230;
			}
		}
		/*
		record the settings in the settings object, 
		and update the quiz-array
		*/
		private function updateSettings(evt:Event):void{
			
			//TODO ANNA add checking limitwords
			
			//saves settings user made in view in a settings object
			recordcurrentSettings();
			settings.save();
			
			//based on settings calculates the quizcontent
			quizVocab.update(settings);
			
			//update ripeness display
			setRipeFromSelection();
			
			//updates the selected words in settings-view
			view.update_txt.text = quizVocab.quizWords.length.toString();
		}
		private function setRipeFromSelection():void{
			
			view.isRipe.text 	= quizVocab.ripeWords.length.toString();;
			view.isRotten.text 	= quizVocab.notRipeWords.length.toString();;
		}
		/**
		 * TODO  on change of the settings-view, record the new settings in the settings-object
		**/
		private function recordcurrentSettings():void{
			
			//maincontent settings
			this.settings.selectedRipenessRipe 		= view.ripetoremember.selected;
			this.settings.selectedRipenessNotRipe 	= view.rottenforgotten.selected;
			this.settings.mainQuizContent			= view.selectionRadioGroup.selectedValue.valueOf();
			this.settings.sArray 					= view.sessionselctor.selectedIndices;
			this.settings.tArray 					= view.tagselector.selectedIndices;
			this.settings.limitWordsIndex			= view.limitWords.selectedIndex;
			this.settings.setWordArrays();
		}
		
		public function set view(value:SettingsView):void
		{
			settingsView = value;
		}
		
		public function get view():SettingsView
		{
			return settingsView;
		}
		
	}
}