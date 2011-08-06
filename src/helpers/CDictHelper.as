package helpers
{
	import flash.data.SQLConnection;
	import flash.data.SQLMode;
	import flash.data.SQLStatement;
	import flash.events.SQLErrorEvent;
	import flash.events.SQLEvent;
	import flash.filesystem.File;
	
	import model.Word;

	public class CDictHelper
	{
		private static var Columns:Array = new Array("Definition", "Simplified", "Traditional", "Pinyin");
		private static var NotInclude:Array = new Array("(idiom)", "surname", "Japanese variant of", "variant");
		
		public static var PinyinTones:Array = new Array("1","2","3","4");
		private static var _instance:CDictHelper;
		private static var connection:SQLConnection;
		private static var dbFile:File;
		
		
		
		public function CDictHelper()
		{
			connection = new SQLConnection();
			connection.addEventListener(SQLErrorEvent.ERROR, handleSQLConnectionError);
			
		}
		
		public static function getInstance():CDictHelper
		{
			if(!_instance)
				_instance = new CDictHelper;
			
			return _instance;
			
		}
		
		/**************************************** DATABASE HANDELING ***********************************************/
		private function handleSQLConnectionError(e:Error):void
		{
			throw new Error("Set the database file first");
		}
		
		public function setDatabaseFile(file:File):void
		{
			dbFile = file;
			connection.open(file, SQLMode.UPDATE);
		}
		
		private function handleSQLStatementError(e:Error):void
		{
			trace(e.message);
		}
		
		private function handleSQLStatementResult(e:SQLEvent):void
		{
			
			
		}
		
		
		//Helper methods
		public function search(string:String, limit:int=0):Array
		{
			var result:Array = new Array();
			
			result = result.concat(searchAllExactMatch(string));
			result = result.concat(searchPinyinExactMatchDifferentTones(string, NotInclude));
			result = result.concat(searchDefinition(string, NotInclude));
			result = result.concat(searchPinyin(string, NotInclude));
			
			var i:int;
			var j: int;
			for (i = 0; i < result.length - 1; i++){
				for (j = i + 1; j < result.length; j++){
					if (result[i].character == result[j].character){
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
		
		private function searchAllExactMatch(string:String):Array
		{
			var result:Array = new Array();
			var sql:String;
			
			for each(var col:String in Columns)
			{
				sql = "SELECT * FROM Cedict WHERE {column} = '{string}' OR {column} LIKE '{string}|%' OR {column} LIKE '%|{string}|%' OR {column} LIKE '%|{string}'";
				sql = sql.replace(/{column}/g, col);
				sql = sql.replace(/{string}/g, string);
				result = result.concat(performSQLquery(sql));
			}
			
			//special round for 
			
			return result;
		}
		
		private function searchPinyinExactMatchDifferentTones(string:String, notA:Array):Array
		{
		
			var result:Array = new Array();
			var sql:String = "SELECT * FROM Cedict WHERE(";
			var col:String = Columns[3];
			
			//only serarch 1 pinyin
			var pinyinLen:int = string.split(" ").length;
			if(pinyinLen > 1)
			{
				return new Array();
			}
			
		
			for each(var tone:String in PinyinTones)
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
			
			sql += excludeTerms(notA, Columns[0]);
			
			result = result.concat(performSQLquery(sql));
			
			return result;
		}
		
		private function searchDefinition(string:String, notA:Array=null):Array
		{
			var result:Array = new Array();
			var sql:String;
			var col:String = Columns[0];
			sql = "SELECT * FROM Cedict WHERE ({column} LIKE '{string} %' OR {column} LIKE '% {string}' OR {column} LIKE '% {string} %' OR {column} LIKE '%|{string} %' OR {column} LIKE '% {string}|%')";
			sql = sql.replace(/{column}/g, col);
			sql = sql.replace(/{string}/g, string);
			
			//not like
			//exclude some terms in the search: (idiom), surname, etc
			sql += excludeTerms(notA, col);
			
			result = result.concat(performSQLquery(sql));
			return result;
		}
		private function excludeTerms(notA:Array, col:String):String{
			var sql:String = "";
			if(notA)
			{
				for each(var not:String in notA)
				{
					sql += " AND {column} NOT LIKE '%{not}%'";
					sql = sql.replace(/{column}/g, col);
					sql = sql.replace(/{not}/g, not);
				}
			}
			return sql;
		}
		private function searchPinyin(string:String, notA:Array = null):Array
		{
			var result:Array = new Array();
			var sql:String;
			var col:String = Columns[3];
			var words:Array = string.split(" ");
			
			string = "";
			for each(var word:String in words)
			{
				string += (word+"% ");
			}
			
			string = string.substr(0, string.length-1); //remove last space
			
			sql = "SELECT * FROM Cedict WHERE ({column} LIKE '{string}')";
			sql = sql.replace(/{column}/g, col);
			sql = sql.replace(/{string}/g, string);
			
			sql += excludeTerms(notA, Columns[0]);
			
			result = result.concat(performSQLquery(sql));
			
			return result;
		}
		
		private function searchAll(string:String, not:String=""):Array
		{
			
			var sql:String = "SELECT * FROM Cedict WHERE Traditional || Simplified || Pinyin || Definition like '%{string}%'";
			
			/*
			if(limit > 0)
			{
				sql += " LIMIT " + limit;
			}
			*/
			
			sql = sql.replace(/{string}/g, string);
			
			if(not != "")
			{
				sql += " AND NOT LIKE '%{not}%'";
				sql = sql.replace(/{not}/g, not);
			}
			
			return performSQLquery(sql);
		}
		
		public function searchSingleCharacter(character:String):Array
		{
			var sql:String = "SELECT * FROM CEdict WHERE Simplified = '{$}'";
				sql = sql.replace("{$}", character);
			
				return performSQLquery(sql);
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
				word.character 		= rawWord.Simplified;
				word.english 		= rawWord.Definition;
				word.pinyin 		= rawWord.Pinyin;
				words.push(word);
				
			}
			
			return words;
		}
	}
}