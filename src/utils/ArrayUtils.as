package utils
{
	public class ArrayUtils
	{
		
		public static function shuffleArray(input:Array):Array
		{
			var len:int = input.length;
			var temp:*;
			var i:int = len;
			while (i--) {
				var rand:int = Math.floor(Math.random() * len);
				temp = input[i];
				input[i] = input[rand];
				input[rand] = temp;
			}
			return input;
		}

	}
}