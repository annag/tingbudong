package helpers
{
	import flash.data.SQLConnection;
	import flash.data.SQLMode;
	import flash.data.SQLResult;
	import flash.data.SQLStatement;
	import flash.events.SQLErrorEvent;
	import flash.events.SQLEvent;
	import flash.filesystem.File;
	import flash.utils.getTimer;
	
	import model.Grammar;
	import model.Sentence;
	import model.Session;
	import model.Vocab;
	import model.Word;

	public class DatabaseHelper
	{
		private static var Columns:Array = new Array("english", "character", "pinyin");
		
		private static var _instance:DatabaseHelper;
		private static var connection:SQLConnection;
		private static var dbFile:File;
		
		//hacky
		public static var tagscount:int = 0;
		public static var sessionscount:int = 0;
		
		public function DatabaseHelper()
		{
			connection = new SQLConnection();
			connection.addEventListener(SQLErrorEvent.ERROR, handleSQLConnectionError);
				
		}
		
		public static function getInstance():DatabaseHelper
		{
			if(!_instance)
				_instance = new DatabaseHelper;
			
			return _instance;
			
		}
		/**************************************** DATABASE HANDELING ***********************************************/
		//TODO FLUXA
		
		public function getGrammarWithSearchString(string:String, limit:int):Array{
		
			var result:Array = new Array();
			var sql:String;
			
	
				sql = "SELECT * FROM grammar WHERE pinyin LIKE '%{string}%' OR english LIKE '%{string}%'";
				sql = sql.replace(/{string}/g, string);
		
				
				result = result.concat(performSQLqueryGrammar(sql));
				
				if(result.length > limit)
				{
					result = result.slice(0, 99);
				}
			
			
			return result;
		}
		public function getWordsWithSearchString(string:String, limit:int):Array{
			
			//get words with search string matching:
			//english
			//pinyin
			//character >> merge them into one array.
			
			
			var result:Array = new Array();
			
			
			result = result.concat(searchAllExactMatch(string));
			result = result.concat(searchPinyinExactMatchDifferentTones(string));
			result = result.concat(searchDefinition(string));
			result = result.concat(searchPinyin(string));
			
			var i:int;
			var j: int;
			for (i = 0; i < result.length - 1; i++){
				for (j = i + 1; j < result.length; j++){
					if (result[i].id == result[j].id){
						result.splice(j, 1);
					}
				}
			}
		
			
			if(result.length > limit)
			{
				result = result.slice(0, 99);
			}
			
			return result;
			
		
		}
		
		private function performSQLqueryGrammar(sql:String):Array
		{
			
			var dbStatement:SQLStatement = new SQLStatement();
			dbStatement.text = sql;
			dbStatement.sqlConnection = connection;
			dbStatement.execute();			
			
			var data:Object = dbStatement.getResult().data;
			var grams:Array = new Array();
			for each(var rawGrammar:Object in data)
			{
				
				var gram:Grammar = new Grammar();
				gram.english 		= rawGrammar.english;
				gram.pinyin 		= rawGrammar.pinyin;
				gram.id 			= rawGrammar.id;
				gram.groupid 		= rawGrammar.groupid;
				gram.decayRate_index= rawGrammar.decayindex;
				gram.knowledge		= rawGrammar.knowledge;			
				gram.rec.init(rawGrammar.lastcorrect, rawGrammar.lasttimes, rawGrammar.alltimes);
				gram.settagArray(rawGrammar.tags);
				gram.sentences = DatabaseHelper.getInstance().getSentencesFromVocab(rawGrammar.id);
				
				
				grams.push(gram);
				
			}
			
			return grams;
		}
		private function performSQLquery(sql:String):Array
		{
			
			var dbStatement:SQLStatement = new SQLStatement();
			dbStatement.text = sql;
			dbStatement.sqlConnection = connection;
			dbStatement.execute();			
			
			var data:Object = dbStatement.getResult().data;
			var words:Array = new Array();
			for each(var rawWord:Object in data)
			{
				
				var word:Word = new Word();
				word.character 		= rawWord.character;
				word.english 		= rawWord.english;
				word.pinyin 		= rawWord.pinyin;
				word.id 			= rawWord.id;
				word.groupid 		= rawWord.groupid;
				word.imagePath		= rawWord.image;
				word.trackedForHanse= rawWord.trackingforhanzi;
				word.decayRate_index= rawWord.decayindex;
				word.knowledge		= rawWord.knowledge;			
				word.rec.init(rawWord.lastcorrect, rawWord.lasttimes, rawWord.alltimes);
				word.settagArray(rawWord.tags);
				word.sentences = DatabaseHelper.getInstance().getSentencesFromVocab(rawWord.id);
				
				
				words.push(word);
				
			}
			
			return words;
		}
		
		private function searchAllExactMatch(string:String):Array
		{
			var result:Array = new Array();
			var sql:String;
			
			for each(var col:String in Columns)
			{
				sql = "SELECT * FROM words WHERE {column} = '{string}' OR {column} LIKE '{string}|%' OR {column} LIKE '%|{string}|%' OR {column} LIKE '%|{string}'";
				sql = sql.replace(/{column}/g, col);
				sql = sql.replace(/{string}/g, string);
				result = result.concat(performSQLquery(sql));
			}
			
			//special round for 
			
			return result;
		}
		
		private function searchPinyinExactMatchDifferentTones(string:String):Array
		{
			
			var result:Array = new Array();
			var sql:String = "SELECT * FROM words WHERE(";
			var col:String = Columns[2]; //pinyin
			
			//only serarch 1 pinyin
			var pinyinLen:int = string.split(" ").length;
			if(pinyinLen > 1)
			{
				return new Array();
			}
			
			for each(var tone:String in CDictHelper.PinyinTones)
			{
				sql += " {column} = '{string}{tone}' OR";
				sql = sql.replace(/{column}/g, col);
				sql = sql.replace(/{tone}/g, tone);
				sql = sql.replace(/{string}/g, string);
			}
			
			//remove last AND
			sql = sql.substr(0, sql.length-3);
			//add last )
			sql += ")";
			
			result = result.concat(performSQLquery(sql));
			
			return result;
		}
		
		private function searchDefinition(string:String):Array
		{
			var result:Array = new Array();
			var sql:String;
			var col:String = Columns[0];
			sql = "SELECT * FROM words WHERE ({column} LIKE '%+{string}' OR {column} LIKE '{string}+%' OR {column} LIKE '%...{string}' " +
				"OR {column} LIKE '{string}...%' OR {column} LIKE '{string},%' OR {column} LIKE '{string} %' " +
				"OR {column} LIKE '% {string}' OR {column} LIKE '% {string} %' OR {column} LIKE '%|{string} %' " +
				"OR {column} LIKE '% {string}|%')";
			//sql = "SELECT * FROM words WHERE {column} LIKE '%{string}%'";
			sql = sql.replace(/{column}/g, col);
			sql = sql.replace(/{string}/g, string);
			
			
			result = result.concat(performSQLquery(sql));
			return result;
		}
		
		private function searchPinyin(string:String):Array
		{
			var result:Array = new Array();
			var sql:String;
			var col:String = Columns[2]; //pinyin
			var words:Array = string.split(" ");
			
			string = "";
			for each(var word:String in words)
			{
				string += (word+"% ");
			}
			
			string = string.substr(0, string.length-1); //remove last space
			
			sql = "SELECT * FROM words WHERE ({column} LIKE '{string}')";
			sql = sql.replace(/{column}/g, col);
			sql = sql.replace(/{string}/g, string);
			
			
			result = result.concat(performSQLquery(sql));
			
			return result;
		}
		
		
		private function handleSQLConnectionError(e:Error):void
		{
			throw new Error("Set the database file first");
		}
		
		public function setDatabaseFile(file:File):void
		{
			dbFile = file;
			connection.open(file, SQLMode.UPDATE);
		}
		public static function clearDatabase():void
		{
			var sql:String = "DELETE FROM words";
			
			var dbStatement:SQLStatement = new SQLStatement();
				dbStatement.text = sql;
				dbStatement.sqlConnection = connection;
				dbStatement.execute();
			
			sql = "DELETE FROM sessions";
				dbStatement = new SQLStatement();
				dbStatement.text = sql;
				dbStatement.sqlConnection = connection;
				dbStatement.execute();
			
		}
		private function handleSQLStatementError(e:Error):void
		{
			trace(e.message);
		}
		
		private function handleSQLStatementResult(e:SQLEvent):void
		{
			
			
		}
		/**************************************** WORDS CRUD HANDELING ***********************************************/
		
		public static function addWord(word:Word):void
		{
			var sql:String = "INSERT INTO words VALUES(null, :english,:pinyin,:character,:groupid,:tags,:image,:trackingforhanzi,:decayindex, :knowledge, :lastcorrect, :lasttimes, :alltimes);";
			
			var dbStatement:SQLStatement = new SQLStatement();
				dbStatement.text = sql;
				dbStatement.parameters[":english"] 				= word.english;
				dbStatement.parameters[":pinyin"] 				= word.pinyin;
				dbStatement.parameters[":character"] 			= word.character;
				dbStatement.parameters[":groupid"] 				= word.groupid;
				dbStatement.parameters[":tags"] 				= word.gettagArray();
				dbStatement.parameters[":image"]				= word.imagePath;
				dbStatement.parameters[":trackingforhanzi"]		= word.trackedForHanse;
				dbStatement.parameters[":decayindex"]			= word.decayRate_index;
				dbStatement.parameters[":knowledge"]			= word.knowledge;
				dbStatement.parameters[":lasttimes"]			= word.rec._today_quized;
				dbStatement.parameters[":lastcorrect"]			= word.rec.today_correct.join(",");
				dbStatement.parameters[":alltimes"]				= word.rec.all_times.join(",");
				dbStatement.sqlConnection = connection;
				dbStatement.addEventListener(SQLErrorEvent.ERROR, _instance.handleSQLStatementError,false,0,true);
				dbStatement.addEventListener(SQLEvent.RESULT, _instance.handleSQLStatementResult,false,0,true);
				dbStatement.execute();
				dbStatement = null;
				
		}
		public static function resetVocab(id:int):Boolean{
			
			if(id !=-1){
				var sql:String = "UPDATE words SET knowledge = 0 WHERE id = " + id.toString();
				var dbStatement:SQLStatement = new SQLStatement();
				dbStatement.text = sql;
				dbStatement.sqlConnection = connection;
				dbStatement.addEventListener(SQLErrorEvent.ERROR, _instance.handleSQLStatementError,false,0,true);
				dbStatement.addEventListener(SQLEvent.RESULT, _instance.handleSQLStatementResult,false,0,true);
				dbStatement.execute();
				dbStatement = null;
				return true;
			}
		
			return false;
		}
		
		public static function deleteWord(id:int=-1):Boolean{
			
			if(id>=0)
			{
				var sql:String = "DELETE FROM words WHERE id = " + id.toString();
			
				var dbStatement:SQLStatement = new SQLStatement();
					dbStatement.text = sql;
					dbStatement.sqlConnection = connection;
					dbStatement.execute();
				return true;
			}	
			return false;
			
		}
		
		public static function updateWord(word:Word=null):Boolean{
			if(word)
			{
				var sql:String = "UPDATE words SET english = :english, pinyin = :pinyin, character = :character, groupid = :groupid, tags = :tags, image = :image, trackingforhanzi = :trackingforhanzi, decayindex = :decayindex, knowledge = :knowledge, lastcorrect = :lastcorrect, lasttimes = :lasttimes, alltimes = :alltimes WHERE id = " + word.id.toString();
				var test:String = word.gettagArray();
				var dbStatement:SQLStatement = new SQLStatement();
					dbStatement.text = sql;
					dbStatement.parameters[":english"] 				= word.english;
					dbStatement.parameters[":pinyin"] 				= word.pinyin;
					dbStatement.parameters[":character"] 			= word.character;
					dbStatement.parameters[":groupid"] 				= word.groupid;
					dbStatement.parameters[":image"]				= word.imagePath;
					dbStatement.parameters[":trackingforhanzi"]		= word.trackedForHanse;
					dbStatement.parameters[":tags"] 				= word.gettagArray();
					dbStatement.parameters[":decayindex"] 			= word.decayRate_index;
					dbStatement.parameters[":knowledge"]			= word.knowledge;
					dbStatement.parameters[":lasttimes"]			= word.rec._today_quized;
					dbStatement.parameters[":lastcorrect"]			= word.rec.today_correct.join(",");
					dbStatement.parameters[":alltimes"]				= word.rec.all_times.join(",");
					dbStatement.sqlConnection = connection;
					dbStatement.addEventListener(SQLErrorEvent.ERROR, _instance.handleSQLStatementError,false,0,true);
					dbStatement.addEventListener(SQLEvent.RESULT, _instance.handleSQLStatementResult,false,0,true);
					dbStatement.execute();
					dbStatement = null;
					return true;
			}
					
				
			return false;
			
				
		}
		
		public static function checkDuplicateWord(english:String, character:String, pinyin:String):Boolean
		{
			
			var all:Array = DatabaseHelper.getInstance().getAllWords();	
			for each(var w:Word in all)
			{
				if(w.english == english && w.character == character && w.pinyin == pinyin) return true;
			}
			return false;
		}
		
		/**************************************** SENTENCE CRUD HANDELING ***********************************************/
		
		public static function addSentence(sentence:Sentence):void
		{
			var sql:String = "INSERT INTO sentences VALUES(null, :english,:pinyin,:character,:vocabid);";
			
			var dbStatement:SQLStatement = new SQLStatement();
			dbStatement.text = sql;
			dbStatement.parameters[":english"] 				= sentence.english;
			dbStatement.parameters[":pinyin"] 				= sentence.pinyin;
			dbStatement.parameters[":character"] 			= sentence.character;
			dbStatement.parameters[":vocabid"] 				= sentence.vocabid;
			

			dbStatement.sqlConnection = connection;
			dbStatement.addEventListener(SQLErrorEvent.ERROR, _instance.handleSQLStatementError,false,0,true);
			dbStatement.addEventListener(SQLEvent.RESULT, _instance.handleSQLStatementResult,false,0,true);
			dbStatement.execute();
			dbStatement = null;
			
		}
		public static function deleteSentence(id:int=-1):Boolean{
			
			if(id>=0)
			{
				var sql:String = "DELETE FROM sentences WHERE id = " + id.toString();
				
				var dbStatement:SQLStatement = new SQLStatement();
				dbStatement.text = sql;
				dbStatement.sqlConnection = connection;
				dbStatement.execute();
				return true;
			}	
			return false;
			
		}
		public static function updateSentence(sentence:Sentence=null):Boolean{
			if(sentence)
			{
				var sql:String = "UPDATE sentences SET english = :english, pinyin = :pinyin, character = :character, vocabid = :vocabid WHERE id = " + sentence.id.toString();
				var dbStatement:SQLStatement = new SQLStatement();
				dbStatement.text = sql;
				dbStatement.parameters[":english"] 				= sentence.english;
				dbStatement.parameters[":pinyin"] 				= sentence.pinyin;
				dbStatement.parameters[":character"] 			= sentence.character;
				dbStatement.parameters[":vocabid"] 				= sentence.vocabid;
				dbStatement.sqlConnection = connection;
				dbStatement.addEventListener(SQLErrorEvent.ERROR, _instance.handleSQLStatementError,false,0,true);
				dbStatement.addEventListener(SQLEvent.RESULT, _instance.handleSQLStatementResult,false,0,true);
				dbStatement.execute();
				dbStatement = null;
				return true;
			}
			
			
			return false;
			
			
		}
		public function updateSentencesForVocab(vocab:Vocab):Boolean{
		
			//get all sentences for a word
			//delete all sentences
			//save all new sentences
			
			return true;
		
		}
		public function getAllSentences():Array{
		
			var sql:String = "SELECT * FROM sentences";
			return DatabaseHelper.getInstance().getSentences(sql);
		}
		public static function checkDuplicateSentence(english:String, character:String, pinyin:String):Boolean
		{
			
			var all:Array = DatabaseHelper.getInstance().getAllSentences();
			for each(var s:Sentence in all)
			{
				if(s.english == english && s.character == character && s.pinyin == pinyin) return true;
			}
			return false;	
		}
		public function getSentenceById(sentenceId:String):Sentence{
			var sql:String = "SELECT * FROM sentences WHERE id = " + sentenceId;
			return (DatabaseHelper.getInstance().getSentences(sql) as Array)[0];

		}
		/**************************************** SESSIONS CRUD HANDELING ***********************************************/
		public static function addSession(session:Session):void
		{
			var sql:String = "INSERT INTO sessions VALUES(null, :name, strftime('%J',:dateadded));";
			
			var dbStatement:SQLStatement = new SQLStatement();
				dbStatement.text = sql;
				dbStatement.parameters[":name"] = session.name;
				dbStatement.parameters[":dateadded"] = toSqlDate(new Date());
				dbStatement.sqlConnection = connection;
				dbStatement.addEventListener(SQLErrorEvent.ERROR, _instance.handleSQLStatementError,false,0,true);
				dbStatement.addEventListener(SQLEvent.RESULT, _instance.handleSQLStatementResult,false,0,true);
				dbStatement.execute();
				dbStatement = null;
		}
		
		public static function updateSession(sessionId:String, sessionName:String):Boolean
		{
			if(sessionId)
			{
				var sql:String = "UPDATE sessions SET name = :name WHERE id = " + sessionId;
				
				var dbStatement:SQLStatement = new SQLStatement();
					dbStatement.text = sql;
					dbStatement.parameters[":name"] = sessionName;
					dbStatement.sqlConnection = connection;
					dbStatement.addEventListener(SQLErrorEvent.ERROR, _instance.handleSQLStatementError,false,0,true);
					dbStatement.addEventListener(SQLEvent.RESULT, _instance.handleSQLStatementResult,false,0,true);
					dbStatement.execute();
					dbStatement = null;
					
			}
			else
				return false
			
			return true;
		}

		public static function deleteSession(sessionId:String):Boolean
		{
			if(sessionId)
			{
				var sql:String = "DELETE FROM sessions WHERE id = " + sessionId;
				
				var dbStatement:SQLStatement = new SQLStatement();
				dbStatement.text = sql;
				dbStatement.sqlConnection = connection;
				dbStatement.execute();
				
				DatabaseHelper.deleteAllWordsOfSession(int(sessionId));
				
			}
			else
				return false;
			
			return true;
		}
		public function getSession(id:int=-1):Session{
			
			var sql:String = "SELECT * FROM sessions WHERE id = " + id.toString();
			var dbStatement:SQLStatement = new SQLStatement();
			dbStatement.text = sql;
			dbStatement.sqlConnection = connection;
			dbStatement.execute();
			
			var obj:SQLResult =  dbStatement.getResult();
			
			return DatabaseHelper.getInstance().parseSession(obj.data[0]);
		}
		public function getSessions():Array
		{
			var sql:String = "SELECT * FROM sessions ORDER BY id DESC";
			var dbStatement:SQLStatement = new SQLStatement();
			dbStatement.text = sql;
			dbStatement.sqlConnection = connection;
			dbStatement.execute();
			
			var data:Object = dbStatement.getResult().data;
			var array:Array = new Array();
			
			for each(var obj:Object in data)
			{
				array.push(DatabaseHelper.getInstance().parseSession(obj));	
			}
			
			return array;
			
		}
		public static function getLatestSessions(num:int=0):Array
		{
			var sessions:Array = DatabaseHelper.getInstance().getSessions();
			sessions = sessions.sort(sessionsSortFunction);
			
			if(num > 0 && num < sessions.length)
			{
				sessions = sessions.slice(0, num);				
			}
			
			return sessions;
			
		}
		public function getSessionByName(str:String):Session{
			
			var sessions:Array = this.getSessions();
			for each (var s:Session in sessions){
				
				if(s.name == str)return s;
				
			}
			return null;
		}
		public static function deleteAllWordsOfSession(sessionId:int):void{
		
			var arr:Array = DatabaseHelper.getInstance().getWordsFromSession(sessionId.toString());
			for(var i:int = 0; i<arr.length;i++){
				var w:Word = arr[i];
				deleteWord(w.id);
			
			}
		}

		public static function sessionsSortFunction(a:Session, b:Session):int
		{
			if(a.dateadded > b.dateadded)
				return -1;
			else if(a.dateadded == b.dateadded) 
				return 0;
			else 
				return 1;
		}
		/***************************************GRAMMAR CRUD**************************************************************/
		
		
		public static function addGrammar(gram:Grammar):void
		{
			var sql:String = "INSERT INTO grammar VALUES(null, :groupid, :pinyin, :english, :tags, :decayindex, :knowledge, :lasttimes, :lastcorrect, :alltimes);";
			
			var dbStatement:SQLStatement = new SQLStatement();
			dbStatement.text = sql;
			dbStatement.parameters[":groupid"] 				= gram.groupid;
			dbStatement.parameters[":pinyin"] 				= gram.pinyin;
			dbStatement.parameters[":english"] 				= gram.english;
			dbStatement.parameters[":tags"] 				= "grammar";
			dbStatement.parameters[":decayindex"] 			= gram.decayRate_index;
			dbStatement.parameters[":knowledge"]			= gram.knowledge;
			dbStatement.parameters[":lasttimes"]			= gram.rec._today_quized;
			dbStatement.parameters[":lastcorrect"]			= gram.rec.today_correct.join(",");
			dbStatement.parameters[":alltimes"]				= gram.rec.all_times.join(",");
			dbStatement.sqlConnection = connection;
			dbStatement.addEventListener(SQLErrorEvent.ERROR, _instance.handleSQLStatementError,false,0,true);
			dbStatement.addEventListener(SQLEvent.RESULT, _instance.handleSQLStatementResult,false,0,true);
			dbStatement.execute();
			dbStatement = null;
			
		}
		
		public static function deleteGrammar(id:int=-1):Boolean{
			
			if(id>=0)
			{
				var sql:String = "DELETE FROM grammar WHERE id = " + id.toString();
				
				var dbStatement:SQLStatement = new SQLStatement();
				dbStatement.text = sql;
				dbStatement.sqlConnection = connection;
				dbStatement.execute();
				return true;
			}	
			return false;
			
		}
		
		public static function updateGrammar(gram:Grammar=null):Boolean{
			if(gram)
			{
				var sql:String = "UPDATE grammar SET pinyin = :pinyin, english = :english, groupid = :groupid, lasttimes = :lasttimes, lastcorrect = :lastcorrect, alltimes = :alltimes, decayindex = :decayindex, knowledge = :knowledge, tags = :tags WHERE id = " + gram.id.toString();
				var dbStatement:SQLStatement = new SQLStatement();
				dbStatement.text = sql;
				dbStatement.parameters[":pinyin"] 			= gram.pinyin;
				dbStatement.parameters[":english"] 				= gram.english;
				dbStatement.parameters[":groupid"] 				= gram.groupid;
				dbStatement.parameters[":tags"] 				= gram.gettagArray();
				dbStatement.parameters[":decayindex"] 			= gram.decayRate_index;
				dbStatement.parameters[":knowledge"]			= gram.knowledge;
				dbStatement.parameters[":lasttimes"]			= gram.rec._today_quized;
				dbStatement.parameters[":lastcorrect"]			= gram.rec.today_correct.join(",");
				dbStatement.parameters[":alltimes"]				= gram.rec.all_times.join(",");
				dbStatement.sqlConnection = connection;
				dbStatement.addEventListener(SQLErrorEvent.ERROR, _instance.handleSQLStatementError,false,0,true);
				dbStatement.addEventListener(SQLEvent.RESULT, _instance.handleSQLStatementResult,false,0,true);
				dbStatement.execute();
				dbStatement = null;
				return true;
			}
			
			
			return false;
			
			
		}
		
		public static function checkDuplicateGrammar(pinyin:String):Boolean
		{
			
			var all:Array = DatabaseHelper.getInstance().getAllGrammar();	
			for each(var g:Grammar in all) { if(g.pinyin == pinyin) return true; }
			return false;
		}
		
		/***************************************QUERIES*******************************************************************/
		private function getGrammar(sql:String):Array
		{
			
			var dbStatement:SQLStatement = new SQLStatement();
			dbStatement.text = sql;
			dbStatement.sqlConnection = connection;
			dbStatement.execute();			
			
			var data:Object = dbStatement.getResult().data;
			var grammar:Array = new Array();
			for each(var rawGram:Object in data){
				
				var gram:Grammar = new Grammar();
				gram.id 			= rawGram.id;
				gram.pinyin 	= rawGram.pinyin;
				gram.english 			= rawGram.english;
				gram.groupid		= rawGram.groupid;
				gram.sentences 		= DatabaseHelper.getInstance().getSentencesFromVocab(rawGram.id);
				gram.decayRate_index= rawGram.decayindex;
				gram.knowledge		= rawGram.knowledge;			
				gram.rec.init(rawGram.lastcorrect, rawGram.lasttimes, rawGram.alltimes);
				gram.settagArray(rawGram.tags);
				grammar.push(gram);
				
			}
			
			return grammar;
		}
		private function getSentences(sql:String):Array
		{
			
			var dbStatement:SQLStatement = new SQLStatement();
			dbStatement.text = sql;
			dbStatement.sqlConnection = connection;
			dbStatement.execute();			
			var data:Object = dbStatement.getResult().data;
			
			var sentences:Array = new Array();
			for each(var rawSentence:Object in data){
				
				var sentence:Sentence = new Sentence();
				sentence.id 			= rawSentence.id;
				sentence.character 		= rawSentence.character;
				sentence.english 		= rawSentence.english;
				sentence.pinyin 		= rawSentence.pinyin;
				sentence.vocabid 		= rawSentence.vocabid;

				sentences.push(sentence);
			}
			return sentences;
		}
		private function getWords(sql:String):Array
		{
			
			var dbStatement:SQLStatement = new SQLStatement();
			dbStatement.text = sql;
			dbStatement.sqlConnection = connection;
			dbStatement.execute();			
			
			var data:Object = dbStatement.getResult().data;
			var words:Array = new Array();
			for each(var rawWord:Object in data){
				
				var word:Word = new Word();
				word.id 			= rawWord.id;
				word.character 		= rawWord.character;
				word.english 		= rawWord.english;
				word.pinyin 		= rawWord.pinyin;
				word.groupid 		= rawWord.groupid;
				word.sentences 		= DatabaseHelper.getInstance().getSentencesFromVocab(rawWord.id);
				word.imagePath		= rawWord.image;
				word.trackedForHanse= rawWord.trackingforhanzi;
				word.decayRate_index= rawWord.decayindex;
				word.knowledge		= rawWord.knowledge;			
				word.rec.init(rawWord.lastcorrect, rawWord.lasttimes, rawWord.alltimes);
				word.settagArray(rawWord.tags);
				
				
				words.push(word);
				
			}
			
			return words;
		}
		public function addexistingTags():void{
		
			var arr:Array = getTags();
		}
		
		public function getWordsWithTags(tags:Array):Array
		{
			var sql:String="select * from  words where tags like ";
			var str:String;
			var count:int = 0;
			var hasGrammar:Boolean = false;
			for each(var tag:String in tags){
				if(tag == "grammar") hasGrammar = true;
				if(count > 0){
					str = " or tags like '%"+tag+"%'";
				}else{
					str = "'%"+tag+"%'";
				}
				sql += str;
				count++;
			}
			var arr:Array = DatabaseHelper.getInstance().getWords(sql);
	
			if(hasGrammar){
				var allGrammar:Array = getAllGrammar();
				arr = arr.concat(allGrammar);
			
			}
			return arr;
		}
		public function getLevelofTag(arr:Array):Number{
		
			return getLevelOfWords(arr);
		}
		public function getLevelOfWords(arr:Array):Number{

			var level1:Number = XMLParsingHelper.getAllForWords(Vocab.IKNOWTHESE, arr, 	Vocab.CURRENT_KNOWLEDGE);
			var level2:Number = XMLParsingHelper.getAllForWords(Vocab.ALMOST, arr, 		Vocab.CURRENT_KNOWLEDGE);
			var level3:Number = XMLParsingHelper.getAllForWords(Vocab.ALITTLE, arr, 		Vocab.CURRENT_KNOWLEDGE);
			var level4:Number = XMLParsingHelper.getAllForWords(Vocab.WHATSTHAT, arr, 	Vocab.CURRENT_KNOWLEDGE);
			var level5:Number = XMLParsingHelper.getAllForWords(Vocab.NOIDEA, arr, 		Vocab.CURRENT_KNOWLEDGE);
			
			var level:int 		= 	Vocab.NOIDEA;
			var res:Number 	=	0;
			if(level2 >= level1){
				res 	= level2;
				level 	= Vocab.ALMOST;
			}else{
				res 	= level1;
				level 	= Vocab.IKNOWTHESE;
			}
			if(level3 >= res){
				res 	= level3;
				level 	= Vocab.ALITTLE;
			}
			if(level4 >= res){
				res 	= level4;
				level 	= Vocab.WHATSTHAT;
			}
			if(level5 >= res){
				res 	= level5;
				level 	= Vocab.NOIDEA;
			}
			return level;
		
		}
		public function getLevelofSession(sessionId:String):Number{
			
			var allWords:Array =  this.getWordsFromSession(sessionId);
			return getLevelOfWords(allWords);
		}
		
		public function getAllGrammar():Array{
			var sql:String = "SELECT * FROM grammar";
			return DatabaseHelper.getInstance().getGrammar(sql);
		}
		public function getAllWords():Array
		{
			var sql:String = "SELECT * FROM words";
			return DatabaseHelper.getInstance().getWords(sql);
		}
		
		public function getWordsFromSession(id:String=null):Array
		{
			var sql:String = "SELECT * FROM words WHERE groupid = " + id;
			return DatabaseHelper.getInstance().getWords(sql);
			
		}
		public function getGrammarFromSession(id:String=null):Array
		{
			var sql:String = "SELECT * FROM grammar WHERE groupid = " + id;
			return DatabaseHelper.getInstance().getGrammar(sql);
			
		}
		public function getSentencesFromVocab(id:String=null):Array
		{
			var sql:String = "SELECT * FROM sentences WHERE vocabid = " + id;
			return DatabaseHelper.getInstance().getSentences(sql);
			
		}
		public function getGrammarById(id:String):Grammar{
			var sql:String = "SELECT * FROM grammar WHERE id = " + id;
			return (DatabaseHelper.getInstance().getGrammar(sql) as Array)[0];
			
		}
		public function getWordById(id:String):Grammar{
			var sql:String = "SELECT * FROM words WHERE id = " + id;
			return (DatabaseHelper.getInstance().getWords(sql) as Array)[0];
			
		}
		public function getGrammarByPinyin(txt:String):Array{
			var sql:String = "SELECT * FROM grammar WHERE pinyin ='" + txt+"'";
			return DatabaseHelper.getInstance().getGrammar(sql);
		
		}
		/********************************************DATA HANDLING*******************************************/
		private function parseSession(obj:Object):Session
		{
			var session:Session = new Session();
				session.id = obj.id;
				session.name = obj.name;
				session.words = DatabaseHelper.getInstance().getWordsFromSession(obj.id);
				session.grammar = DatabaseHelper.getInstance().getGrammarFromSession(obj.id);
				session.dateadded = obj.dateadded;
			return session;	
			
		}
		
		public function getTags():Array
		{
			var tags:Array = new Array();
			
			var words:Array = DatabaseHelper.getInstance().getAllWords();
			var allGrammar:Array = getAllGrammar();
			words = words.concat(allGrammar);
			
			for each(var word:Vocab in words)
			{
				for each(var tag:String in word.tagArray)
				{
					if(tags.indexOf(tag) < 0)
						tags.push(tag);
				}
			}
			return tags;
		}
		
		private static function toSqlDate(dateVal:Date):String
		{
			return dateVal == null ? null : dateVal.fullYear
											+ "-" + lpad(dateVal.month + 1,2,'0')  // month is zero-based
											+ "-" + lpad(dateVal.date,2,'0')
											+ " " + lpad(dateVal.hours,2,'0')
											+ ":" + lpad(dateVal.minutes,2,'0')
											+ ":" + lpad(dateVal.seconds,2,'0')
											;
		}
		
		private static function lpad(original:Object, length:int, pad:String):String
		{
			var padded:String = original == null ? "" : original.toString();
			while (padded.length < length) padded = pad + padded;
			return padded;
		}
		
		private static const lastOpenedDateFileName:String = "lastopeneddate.dat";
		private static var lastOpenedDateFile:File = File.applicationStorageDirectory.resolvePath(lastOpenedDateFileName);
		
		public static function getLastOpenDate():Date
		{
			var date:Date = AIRUtils.readFileObject(lastOpenedDateFile) as Date;
			if(date == null)
			{
				trace("creating new date");
				date = new Date();
			}
			trace("application last opened: " + date);
			return date;
			
		}
		
		public static function refreshLastOpenDate():void
		{
			AIRUtils.writeFileObject(lastOpenedDateFile, new Date());
		}
	}
}