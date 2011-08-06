package mediator
{
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import events.EventManager;
	
	public class BaseMediator extends EventDispatcher
	{
		
		public function BaseMediator(target:IEventDispatcher=null)
		{
			super(target);
		}
		
		public function register():void
		{
			throw new Error("override me");
		}
		
		
	}
}