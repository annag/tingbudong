package helpers
{
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.utils.ByteArray;

	public class AIRUtils
	{
		public static function readFileObject(file:File):Object{
			var amf:Object;
			if(file.exists){
				var stream:FileStream = new FileStream();
				stream.open(file, FileMode.READ);
				amf = stream.readObject();
				stream.close();
			}
			return amf;
		}
		
		public static function writeFileObject(file:File, obj:Object):Object{
			var stream:FileStream = new FileStream();
			stream.open(file, FileMode.WRITE);
			stream.writeObject(obj);
			stream.close();
			return obj;
		}
		
		public static function writeBytesToFile(file:File, bytes:ByteArray):void{
			var stream:FileStream = new FileStream();
			stream.open(file, FileMode.WRITE);
			stream.writeBytes(bytes);
			stream.close();
			
		}
		
		public static function readBytesFromPath(path:String):ByteArray
		{
			var file:File = File.applicationStorageDirectory.resolvePath(path);
			if(file.exists){
				var bytes:ByteArray = new ByteArray(); 
				var stream:FileStream = new FileStream();
				stream.open(file, FileMode.READ);
				stream.readBytes(bytes)
				stream.close();
				return bytes;
			}
			
			return null;
		}
	}

}