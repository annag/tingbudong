package components
{
	import de.popforge.audio.output.SoundFactory;
	import de.popforge.format.wav.WavDecoder;
	import de.popforge.format.wav.WavFormat;
	
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.filesystem.File;
	import flash.media.Sound;
	import flash.media.SoundChannel;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	
	import helpers.AIRUtils;
	import helpers.CDictHelper;
	
	import model.Word;
	
	import mx.messaging.Channel;
	
	import utils.Execution;

	public class PronPlayer
	{
		private static var _instance:PronPlayer;
		
		private var storageFolder:String = "pronsounds/";
		private var serverURL:String = "http://lost-theory.org/chinese/phonetics/sounds/";	
		private var serverReplacementPattern:Array = new Array(/u:/gix, /r5/gix, /5/gix); 
		private var serverReplacementString:Array = new Array("v", "er5", "1");
		
		private var channel:SoundChannel;
		private var isBusy:Boolean;
		private var didFail:Boolean;
		
		private var currentWordArray:Array;
		private var currentWordDictionary:Dictionary;
		
		private var urlRequestDictionary:Dictionary;
		
		
		public static function getInstance():PronPlayer
		{
			if(_instance == null)
			{
				_instance = new PronPlayer();
			}
			return _instance;
		}
		
		public function PronPlayer()
		{
			urlRequestDictionary = new Dictionary(true);
			channel = new SoundChannel();
		}
		
		/**
		 * Will play sound files if pinying match the form: i.e: wo3de2ma1ma1shi3hen1hao3
		 **/
		public function PlayFromPinyin(pinyin:String):void
		{
			if(pinyin != "" && pinyin != null)
			{
				if(!isBusy)
				{
					isBusy = true;
					
					//correction
					var l:int = serverReplacementPattern.length;
					for(var i:int=0; i<l; i++)
					{
						pinyin = pinyin.replace(serverReplacementPattern[i], serverReplacementString[i]);
					}
					
					//cleanup
					pinyin = pinyin.replace(/[\W]/gix, "");
					pinyin = pinyin.toLowerCase();
					
					//separate words
					//regexp will match alpha+number, global, ignore spaces/case
					currentWordArray = pinyin.match(/[a-zA-z]+[0-9]/gix);
					currentWordDictionary = new Dictionary();
					didFail = false;
					
					trace("pron player pinyin: " + pinyin);
					
					loadWords();
					
				}
				else
				{
					trace("still working..");
				}
			}
			
		}
		
		public function PlayFromChinese(chinese:String):void
		{
			if(chinese != "" && chinese.length > 0)
			{
				if(!isBusy)
				{
					isBusy = true;
					
					var pinyin:String = "";
					
					//first try to find the whole word
					var found1:Array = CDictHelper.getInstance().searchSingleCharacter(chinese);
					if(found1.length>0)
					{
						var w1:Word = found1[0];
						pinyin = w1.pinyin;
						found1 = null;
						w1 = null;
					}
					else
					{
						//character by character
						var len:int = chinese.length;
						var found2:Array;
						for(var i:int = 0; i<len; i++)
						{
							var character:String = chinese.charAt(i);
							found2 = CDictHelper.getInstance().searchSingleCharacter(character);
							if(found2.length>0)
							{
								var w2:Word = found2[0];
								pinyin += w2.pinyin;
								found2 = null;
								w2 = null;
							}
						}
					}
					
					isBusy = false;
					
					trace("pron player chinese: " + chinese);
					
					PlayFromPinyin(pinyin);
				}
				else
				{
					trace("still working..");
				}
			}
			
		}
		
		private function loadWords():void
		{
			for each(var pinyin:String in currentWordArray)
			{
				var fileName:String = pinyin + ".wav"
				
				//check if file is cached
				var bytes:ByteArray = AIRUtils.readBytesFromPath(storageFolder+fileName);
				
				if(bytes != null)
				{
					currentWordDictionary[pinyin] = bytes;
				}
				else
				{
					var url:String = serverURL + fileName;
					
					var urlLoader:URLLoader = new URLLoader();
					urlLoader.dataFormat = URLLoaderDataFormat.BINARY;
					urlLoader.addEventListener(Event.COMPLETE, onLoaderComplete);
					urlLoader.addEventListener(IOErrorEvent.IO_ERROR, onLoaderIOError);
					
					var urlRequest:URLRequest = new URLRequest(url);
					
					urlRequestDictionary[urlLoader] = pinyin;
					
					urlLoader.load(urlRequest);
				}
				
			}
			
			intentPlayCurrentWords();
			
		}
		
		private function onLoaderComplete(e:Event):void
		{
			var urlLoader:URLLoader = e.target as URLLoader;
				urlLoader.removeEventListener(Event.COMPLETE, onLoaderComplete);
				urlLoader.removeEventListener(IOErrorEvent.IO_ERROR, onLoaderIOError);
		
			//Save data to disk
			var word:String = urlRequestDictionary[urlLoader];
			var fileName:String = word + ".wav";
			var pronFile:File = File.applicationStorageDirectory.resolvePath(storageFolder+fileName);
			AIRUtils.writeBytesToFile(pronFile, urlLoader.data);
				
			currentWordDictionary[word] = urlLoader.data;
			
			urlLoader = null;
			
			intentPlayCurrentWords();
		}
		
		private function onLoaderIOError(e:IOErrorEvent):void
		{
			didFail = true;
			
			var urlLoader:URLLoader = e.target as URLLoader;
				urlLoader.removeEventListener(Event.COMPLETE, onLoaderComplete);
				urlLoader.removeEventListener(IOErrorEvent.IO_ERROR, onLoaderIOError);
		
			var word:String = urlRequestDictionary[urlLoader];
			currentWordDictionary[word] = new ByteArray();
				
			intentPlayCurrentWords();
			
			trace("error loading sound file for: " + word);
		}
		
		private function intentPlayCurrentWords():void
		{
			trace("intent play..");
			
			var canPlay:Boolean = true;
			var arr:Array = new Array();
			
			for each(var word:String in currentWordArray)
			{
				var bytes:ByteArray = currentWordDictionary[word];
				if(!bytes)
				{
					canPlay = false;
					trace("still loading sound files...");
				}
			}
			
			if(canPlay)
			{
				if(didFail)
				{
					finishCurrent();
				}
				else
				{
					playCurrentWords();
				}
				
			}
		}
		
		private function playCurrentWords():void
		{
			var word:String = currentWordArray.shift();
			var bytes:ByteArray = currentWordDictionary[word];
			playSoundFromBytes(bytes);
		}
		
		private function playSoundFromBytes(bytes:ByteArray):void
		{
			var wavformat:WavFormat = WavFormat.decode(bytes);
			SoundFactory.fromArray(wavformat.samples, wavformat.channels, wavformat.bits, wavformat.rate, onSoundFactoryComplete);
		}
		
		private function onSoundFactoryComplete(sound:Sound):void
		{
			channel = sound.play();
			channel.addEventListener(Event.SOUND_COMPLETE, onSoundPlayComplete);
		}
		
		private function onSoundPlayComplete(e:Event):void
		{
			if(currentWordArray.length > 0)
			{
				playCurrentWords();
			}
			else
			{
				finishCurrent();
			}
		}
		
		private function finishCurrent():void
		{
			currentWordArray = null;
			currentWordDictionary = null;
			isBusy = false;
			trace("finished playing");
		}
		
	}
}