package utils
{
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.utils.ByteArray;

	public class ImageFile
	{
		private static var ImagePath:String = "images/";
		
		public static function FileFromName(filename:String):File
		{
			var file:File = File.applicationStorageDirectory.resolvePath( ImagePath+filename );
			return file;
		}
		
		public static function SaveToDisk(filename:String, byteArray:ByteArray):void
		{
			var file:File = FileFromName(filename);
			var wr:File = new File( file.nativePath );
			var stream:FileStream = new FileStream();
			stream.open( wr , FileMode.WRITE);
			stream.writeBytes ( byteArray, 0, byteArray.length ); 
			stream.close();
		}
		
		public static function Exists(filename:String):Boolean
		{
			return FileFromName(filename).exists;
		}

		public static function PathFromName(filename:String):String
		{
			var file:File = ImageFile.FileFromName(filename);
			
			if(filename != "" && file != null && file.exists)
			{
				return "file:///"+file.nativePath;
			}
			
			return "../../assets/image/quiz_img_placeholder.png";
		}
	
	}
}