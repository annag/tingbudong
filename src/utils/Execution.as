/*
Copyright (c) 2006 - 2008  Eric J. Feminella  <eric@ericfeminella.com>
All rights reserved.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is furnished
to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

@internal
*/

package utils
{
	import flash.utils.getTimer;
	
	/**
	 *
	 * Provides an API whereby a specific code execution duration can be
	 * measured for calculating relative time in milliseconds.
	 *
	 * <p>
	 * <code>Execution</code> provides a mechanism for determining the
	 * number of milliseconds which have elapsed for a specific code
	 * block, method or asynchronous service invocation execution.
	 * </p>
	 *
	 * @example The following demonstrate a few common use-case examples
	 * of the <code>Execution</code> API. The first example demonstrates
	 * how <code>Execution</code> can be utilized for calculating the
	 * duration of a for loop.
	 *
	 * <listing version="3.0">
	 *
	 * var execution:IExecutable = Execution.createExecution();
	 *
	 * for (var i:int = 0; i < 10000; i++)
	 * {
	 *    trace( execution.elapsedTime() );
	 * }
	 *
	 * trace( execution.getExecutionDuration() );
	 *
	 * </listing>
	 *
	 * @example This next example demonstrates how <code>Execution</code>
	 * can be utilized for calculating the duration of an asynchronous
	 * service invocation. The example calls an <code>HTTPService</code>
	 * with an id of "service" and calculates the duration of the service
	 * invocation and resulting response.
	 * </p>
	 *
	 * <listing version="3.0">
	 *
	 * service.result = this.result;
	 * service.send();
	 *
	 * var execution:IExecutable = new Execution();
	 *
	 * private function result(data:Object) : void
	 * {
	 *    trace( execution.getExecutionDuration() );
	 * }
	 *
	 * </listing>
	 *
	 * @see com.ericfeminella.diagnostics.IExecution
	 * @see flash.utils.getTimer
	 *
	 */
	public class Execution
	{
		/**
		 *
		 * Defines the value of an execution start time which is used to
		 * determine the elapsed code execution duration.
		 *
		 */
		protected var executionStartTime:int;
		
		/**
		 *
		 * Defines the value of an execution stop time which is used to
		 * determine the elapsed code execution duration.
		 *
		 */
		protected var executionStopTime:int;
		
		/**
		 *
		 * Creates a new instance of Execution from which a code execution
		 * duration can be measured.
		 *
		 * @example The following example demonstrates the most basic and
		 * typical use of <code>Execution</code>.
		 *
		 * <listing version="3.0">
		 *
		 * var execution:IExecutable = new Execution();
		 * execution.start();
		 *
		 * for (var i:int = 0; i < 10000; i++)
		 * {
		 *    trace( execution.elapsedTime() );
		 * }
		 *
		 * trace( execution.elapsedTime() );
		 *
		 * </listing>
		 *
		 * @param determines if the <code>Execution</code> instance is to
		 *  autostart
		 *
		 */
		public function Execution(autoStart:Boolean = true)
		{
			if ( autoStart )
			{
				start();
			}
		}
		
		/**
		 *
		 * Retrieves the measurement based on <code>executionStartTime</code>
		 * and the current <code>executionStopTime</code>.
		 *
		 * @example
		 *
		 * <listing version="3.0">
		 *
		 * var execution:IExecutable = new Execution();
		 * execution.start();
		 *
		 * for (var prop:String in someObject)
		 * {
		 *    trace( prop + "=" + someObject[prop])
		 * }
		 *
		 * trace( execution.elapsedTime() );
		 *
		 * </listing>
		 *
		 * @return integer representing the total execution duration
		 *
		 */
		public function getElapsedTime() : int
		{
			return stop() - executionStartTime;
		}
		
		/**
		 *
		 * Initializes the current execution measurements and sets the
		 * value of the <code>executionStartTime</code> property to the
		 * value of the current getTimer(); Flash Player call.
		 *
		 * @example
		 * <listing version="3.0">
		 *
		 * var execution:IExecutable = new Execution( true );
		 *
		 * someMethod();
		 *
		 * trace( execution.getExecutionDuration() );
		 *
		 * </listing>
		 *
		 * @return an integer representing the start time
		 *
		 */
		public function start() : int
		{
			return executionStartTime = getTimer();
		}
		
		/**
		 *
		 * Stops the current execution measurements and sets the value
		 * of the <code>executionStopTime</code> property to the value
		 * of the current getTimer(); Flash Player call.
		 *
		 * @example
		 * <listing version="3.0">
		 *
		 * var execution:IExecutable = new Execution( true );
		 *
		 * if ( someMethod() == null )
		 * {
		 *     execution.stop();
		 *     trace( execution.getExecutionDuration() );
		 * }
		 * else
		 * {
		 *     someOtherMethod()
		 * }
		 *
		 * trace( execution.getExecutionDuration() );
		 *
		 * </listing>
		 *
		 * @return an integer representing the stop time
		 *
		 */
		public function stop() : int
		{
			return executionStopTime = getTimer();
		}
		
		/**
		 *
		 * Determines the total time (in milliseconds) which has elapsed
		 * for a specific code <code>Execution</code>.
		 *
		 * @example
		 * <listing version="3.0">
		 *
		 * var execution:IExecutable = new Execution( true );
		 *
		 * someMethod();
		 *
		 * trace( execution.getExecutionDuration() );
		 *
		 * </listing>
		 *
		 * @return the total execution time in milliseconds
		 *
		 */
		public function getExecutionTotalDuration() : int
		{
			var elapsedDuration:int = ( stop() - executionStartTime );
			
			return elapsedDuration;
		}
		
		/**
		 *
		 * Retrieves the initial start time of <code>Execution</code>
		 * instance.
		 *
		 * @return the start time in milliseconds
		 *
		 */
		public function get startTime() : int
		{
			return executionStartTime;
		}
		
		/**
		 *
		 * Retrieves the stop time of the <code>Execution</code> instance.
		 *
		 * @return the execution start time in milliseconds
		 *
		 */
		public function get stopTime() : int
		{
			return executionStopTime;
		}
	}
}