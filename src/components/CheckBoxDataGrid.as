package components
{
import flash.display.Sprite;
import flash.events.KeyboardEvent;

import mx.collections.ArrayCollection;
import mx.controls.CheckBox;
import mx.controls.DataGrid;
import mx.controls.listClasses.IListItemRenderer;

/** 
 *  DataGrid that uses checkboxes for multiple selection
 */
public class CheckBoxDataGrid extends DataGrid
{
	public var rowColorFunction:Function;
	/**********************************************************************/
	//						PUBLIC FUNCTIONS 							 //
	/**********************************************************************/
	public function selectAllItems():void
{
		var indices:Array = new Array();
		var listUsers:ArrayCollection = ArrayCollection(this.dataProvider) as ArrayCollection

		for (var i:int = 0; i < listUsers.length; i++) {
			indices[i] = i;
			trace("selecting item");
		}
	
	
		this.selectedIndices = indices;
	}
	
	
	public function deselectAllItems():void{
		this.selectedIndices = new Array();
	}

	
	override protected function selectItem(item:IListItemRenderer,
                                  shiftKey:Boolean, ctrlKey:Boolean,
                                  transition:Boolean = true):Boolean
	{
	
		// only run selection code if a checkbox was hit and always
		// pretend we're using ctrl selection
		if (item is CheckBox){
		//		trace("select!!");
			var shift:Boolean = shiftKey;
			return super.selectItem(item, shiftKey, true, transition);
		}
		return false;
	}

	// turn off selection indicator
    override protected function drawSelectionIndicator(
                                indicator:Sprite, x:Number, y:Number,
                                width:Number, height:Number, color:uint,
                                itemRenderer:IListItemRenderer):void
    {
	}

	// whenever we draw the renderer, make sure we re-eval the checked state
    override protected function drawItem(item:IListItemRenderer,
                                selected:Boolean = false,
                                highlighted:Boolean = false,
                                caret:Boolean = false,
                                transition:Boolean = false):void
    {
		CheckBox(item).invalidateProperties();
		super.drawItem(item, selected, highlighted, caret, transition);
	}

	// fake all keyboard interaction as if it had the ctrl key down
	override protected function keyDownHandler(event:KeyboardEvent):void
	{
		// this is technically illegal, but works
		event.ctrlKey = true;
		//event.shiftKey = false;
		super.keyDownHandler(event);
	}
	override protected function drawRowBackground(s:Sprite, rowIndex:int, y:Number, height:Number, color:uint, dataIndex:int):void
	{
		if(rowColorFunction != null && dataProvider != null)
		{
			var item:Object;
			if(dataIndex < dataProvider.length)
			{
				item = dataProvider[dataIndex];
			}
			
			if(item)
			{
				color = rowColorFunction(item, rowIndex, dataIndex, color);
			}
		}
		
		super.drawRowBackground(s, rowIndex, y, height, color, dataIndex);
	}
}

}