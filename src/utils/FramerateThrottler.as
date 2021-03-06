/**
 * FramerateThrottler by Grant Skinner. May 9, 2009
 * Visit www.gskinner.com/blog for documentation, updates and more free code.
 *
 *
 * Copyright (c) 2008 Grant Skinner
 * 
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the "Software"), to deal in the Software without
 * restriction, including without limitation the rights to use,
 * copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following
 * conditions:
 * 
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 * OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 * OTHER DEALINGS IN THE SOFTWARE.
 **/

package utils {
	
	import flash.desktop.NativeApplication;
	import flash.system.Capabilities;
	import flash.events.Event;
	
	/**
	 * Simple class designed to throttle the framerate of AIR applications when they are not
	 * the active (frontmost) application. This is to reduce problems with idle CPU usage on
	 * Mac. This should be initialized as soon as your application starts up and has a window
	 * open.
	 **/
	public class FramerateThrottler {
		
		// Constants:
		
		// Public Properties:
		/**
		 * Specifies whether to only throttle framerate on the Mac.
		 **/
		public static var onlyThrottleOnMac:Boolean=false;
		
		// Protected Properties:
		/** @private **/
		protected static var _activeFramerate:Number;
		/** @private **/
		protected static var _backgroundFramerate:Number;
		/** @private **/
		protected static var _active:Boolean=false;
		/** @private **/
		protected static var _enabled:Boolean=true;
		/** @private **/
		protected static var mac:Boolean;
		
		// Initialization:
		/**
		 * Initializes the system. This should be called as soon as your application starts up
		 * and has a window open.
		 *
		 * @param backgroundFramerate Specifies the framerate to use when your application is not active (ie. in the background).
		 * @param activeFramerate Optional parameter specifying your application's default framerate. If you omit this parameter, it will use the current framerate of your application or 20fps if there is no window open to read the framerate from.
		 **/
		public static function initialize(backgroundFramerate:Number=1,activeFramerate:Number=NaN):void {
			var na:NativeApplication = NativeApplication.nativeApplication;
			if (!isNaN(activeFramerate) && activeFramerate > 0) {
				_activeFramerate = activeFramerate;
			} else if (na.openedWindows.length > 0) {
				_activeFramerate = na.openedWindows[0].stage.frameRate;
			} else {
				_activeFramerate = 20;
			}
			_backgroundFramerate = backgroundFramerate;
			mac = (Capabilities.version.split(" ")[0].toUpperCase() == "MAC");
			na.addEventListener(Event.DEACTIVATE, handleDeactivate);
		}
		
		// Public getter / setters:
		/**
		 * Indicates whether framerate should be automatically throttled and restored when
		 * your application is activated (frontmost) or deactivated (background). True by default.
		 * This is very useful if you want to temporarily restore the framerate while in the background.
		 * <br/><br/>
		 * For example, if you loaded new data while in the background, you could set enabled to false,
		 * transition in the new data, then set enabled to true. You do not need to worry if the user
		 * focuses the application in the middle of the transition, as it will properly maintain the
		 * active framerate when you set enabled back to true.
		 **/
		public static function set enabled(value:Boolean):void {
			if (value == _enabled) { return; }
			_enabled = value;
			if (!_active && !_enabled) {
				restoreFramerate();
			} else if (!_active && _enabled) {
				throttleFramerate();
			}
		}
		public static function get enabled():Boolean {
			return _enabled;
		}
		
		/**
		 * Indicates whether your application is currently active (frontmost).
		 **/
		public static function get active():Boolean {
			return _active;
		}
		
		// Public Methods:
		
		// Protected Methods:
		/** @private **/
		protected static function restoreFramerate():void {
			if (onlyThrottleOnMac && !mac) { return; }
			var na:NativeApplication = NativeApplication.nativeApplication;
			if (na.openedWindows.length > 0) {
				na.openedWindows[0].stage.frameRate = _activeFramerate;
			}
		}
		
		/** @private **/
		protected static function throttleFramerate():void {
			if (onlyThrottleOnMac && !mac) { return; }
			var na:NativeApplication = NativeApplication.nativeApplication;
			if (na.openedWindows.length > 0) {
				_activeFramerate = na.openedWindows[0].stage.frameRate;
				na.openedWindows[0].stage.frameRate = _backgroundFramerate;
			}
		}
		
		/** @private **/
		protected static function handleDeactivate(evt:Event):void {
			_active = false;
			if (_enabled) { throttleFramerate(); }
			var na:NativeApplication = NativeApplication.nativeApplication;
			na.removeEventListener(Event.DEACTIVATE, handleDeactivate);
			na.addEventListener(Event.ACTIVATE, handleActivate);
		}
		
		/** @private **/
		protected static function handleActivate(evt:Event):void {
			_active = true;
			if (_enabled) { restoreFramerate(); }
			var na:NativeApplication = NativeApplication.nativeApplication;
			na.removeEventListener(Event.ACTIVATE, handleActivate);
			na.addEventListener(Event.DEACTIVATE, handleDeactivate);
		}
		
	}
	
}