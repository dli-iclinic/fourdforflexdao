package com.flex44d.utils
{
	import flash.display.Bitmap;
	import flash.display.Loader;
	import flash.events.KeyboardEvent;
	import flash.ui.Keyboard;
	import flash.utils.ByteArray;
	
	import mx.controls.DateField;
	import mx.controls.Image;
	import mx.formatters.CurrencyFormatter;
	import mx.formatters.DateFormatter;
	import mx.formatters.NumberBaseRoundType;
	
	
	/**
	 *This is a utility class with a bunch of static methods to provide some useful/cool utility functions.
	 *  
	 * @author julio
	 * 
	 */
	public final class FLEX44DUtils
	{
			
	// global vars		
		private static var dateFormatString:String = 'MM/DD/YYYY';


// format Dates for 4D use (YYYYMMDD)
		/**
		 * Converts a Flex date to 4D format (YYYYMMDD).
		 *  
		 * @param theDate a Flex date value
		 * @return a 4D formatted date string (YYYYMMDD)
		 * 
		 */
		public static function dateTo4DFormat(theDate:Date):String {
			var dateFormat:DateFormatter = new DateFormatter;
			dateFormat.formatString = 'YYYYMMDD';
			return dateFormat.format(theDate);
		}

// format Dates for Flex use (from 4D format YYYYMMDD)
		/**
		 * Converts 4D formatted dates into Flex Date values
		 *  
		 * @param theDate a 4D formatted date string (YYYYMMDD)
		 * @return a Flex date value
		 * 
		 */
		public static function dateToFlexFormat(theDate:String):Date {
			if (theDate == '00000000' || theDate == '') return null;
  			var dd:int = int(theDate.substr(6,2));
  			var mm:int = int(theDate.substr(4,2));
  			var yy:int = int(theDate.substr(0,4));
			return new Date(yy,mm-1,dd);
		}
		
// format dates for DateField
		/**
		 * Formats a date according to a globally set Date Format string
		 *  
		 * @param theDate a Flex date value
		 * @return a formatted Date string
		 * 
		 */
		public static function formatDate(theDate:Date):String {
 			var dateFormat:DateFormatter = new DateFormatter;
			dateFormat.formatString=dateFormatString;				// still need to handle Localization
			return dateFormat.format(theDate);
		}

// convert dollar string to number
		/**
		 * Converts a currency formatted text into a number value
		 * 
		 * @param theDollar the text formatted as a currency value ($xxx,xxx.xx)
		 * @return the number corresponding to the text
		 * 
		 */
		public static function dollarToNumber(theDollar:String):Number {
			return Number(theDollar.replace('$','').replace(',',''));
		}
		

//
// utility functions to format values in grid columns
//
		/**
		 * Utility function to use as <b>labelFunction</b> parameter on a Object that formats a value as Currency
		 *  
		 * @param item the dataGrid row item
		 * @param gridCol the dataGrid column
		 * @return the Currency formatted string
		 * 
		 */
		public static function formatGridDollar(item:Object, gridCol:Object):String {
			if (!item) return ''; // make sure we do have an item...

			if (item[gridCol.dataField]) {
	 			var format:CurrencyFormatter = new CurrencyFormatter();
				format.precision = 2;
				format.rounding = NumberBaseRoundType.NEAREST;
				format.useNegativeSign = false;
				
//				trace(ObjectUtil.toString(item[gridCol.dataField]));
				var strValue:String = item[gridCol.dataField];
				strValue = strValue.replace('$','').replace(",",""); // make sure we get rid of currency symbols before formatting
				var value:Number = Number(strValue);
				
				if (value == 0) return '-' else return format.format(value);
			} else return '';
		}

// format dates in grid columns
		/**
		 * Utility function to use as <b>labelFunction</b> parameter on a Object that formats a value as Date
		 *  
		 * @param item the dataGrid row item
		 * @param gridCol the dataGrid column
		 * @return the formatted Date string
		 * 
		 */
		public static function formatGridDate(item:Object, dataField:Object):String {
  			var dateValue:String;
			var dateFormat:DateFormatter = new DateFormatter;
			var dd:int;
			var mm:int;
			var yy:int;
			dateFormat.formatString=dateFormatString;				// still need to handle Localization
			
			if (!item) return ''; // make sure we do have an item...
			
			if (!item[dataField.dataField]) return ''; // null date
			
			// if the field value is already a date, simply format it...
  			if (item[dataField.dataField] is Date) return dateFormat.format(item[dataField.dataField]);  			
			
  			// populate date fields
  			dateValue = item[dataField.dataField].toString();
  			dd = int(dateValue.substr(6,2));
  			mm = int(dateValue.substr(4,2));
  			yy = int(dateValue.substr(0,4));
  			if ((dd == 0) && (mm == 0) && (yy == 0)) return ''; // if null date...
			return dateFormat.format(new Date(yy,mm-1,dd));
		}

		
// format times in grid columns
		/**
		 * Utility function to use as <b>labelFunction</b> parameter on a Object that formats a value as Time
		 *  
		 * @param item the dataGrid row item
		 * @param gridCol the dataGrid column
		 * @return the formatted Time string
		 * 
		 */
		public static function formatGridTime(item:Object, dataField:Object):String {
  			var timeValue:Date = new Date();
			var timeSecs:int;
			
			if (!item) return ''; // make sure we do have an item...
			
			if (!item[dataField.dataField]) return ''; // null time
			
  			// Time values comes from 4D in seconds
  			timeSecs = int(item[dataField.dataField].toString());
  			if (timeSecs == 0) return ''; // null time
  			timeValue.hours	= timeSecs/(60*60);
  			timeValue.minutes = (timeSecs/60)%60;
  			timeValue.seconds = timeSecs%60;
			return timeValue.toTimeString().substr(0,8);
			
		}
		
// format booleans in grid columns as Yes/blank
		/**
		 * Utility function to use as <b>labelFunction</b> parameter on a Object that formats a value as Yes/No
		 *  
		 * @param item the dataGrid row item
		 * @param gridCol the dataGrid column
		 * @return the 'boolean' value as Yes or 'blank'
		 * 
		 */
		public static function formatGridBooleanYes(item:Object, dataField:Object):String {
  			var itemValue:String;
			
			if (!item) return ''; // make sure we do have an item...
 			
			if (!item[dataField.dataField]) return ''; // null value
			
 			itemValue = item[dataField.dataField].toString().toUpperCase();
  			return ((itemValue == 'TRUE') || (itemValue == 'YES'))?'Yes':'';
		}
		
// format booleans in grid columns as tick/blank
		/**
		 * Utility function to use as <b>labelFunction</b> parameter on a Object that formats a value as a tick mark
		 *  
		 * @param item the dataGrid row item
		 * @param gridCol the dataGrid column
		 * @return the 'boolean' value as √ or 'blank'
		 * 
		 */
		public static function formatGridBooleanTick(item:Object, dataField:Object):String {
  			var itemValue:String;
			
			if (!item) return ''; // make sure we do have an item...
			
			if (!item[dataField.dataField]) return ''; // null value
			
  			itemValue = item[dataField.dataField].toString().toUpperCase();
  			return ((itemValue == 'TRUE') || (itemValue == 'YES'))?'√':'';
		}
		
// format booleans in grid columns as bullet/blank
		/**
		 * Utility function to use as <b>labelFunction</b> parameter on a Object that formats a value as a bullet
		 *  
		 * @param item the dataGrid row item
		 * @param gridCol the dataGrid column
		 * @return the 'boolean' value as • or 'blank'
		 * 
		 */
		public static function formatGridBooleanBullet(item:Object, dataField:Object):String {
  			var itemValue:String;
			
			if (!item) return ''; // make sure we do have an item...
			
			if (!item[dataField.dataField]) return ''; // null value
			
  			itemValue = item[dataField.dataField].toString().toUpperCase();
  			return ((itemValue == 'TRUE') || (itemValue == 'YES'))?'•':'';
		}
		
// allow clearing of date fields via Esc or Del keys
 		/**
 		 * Generic KeyUp event handler to use for DateFields.
 		 * 
 		 * <p>it allows using Esc to clear out a date value
 		 *  
 		 * @param e the KeyboardEvent
 		 * 
 		 */
 		public static function clearDateOnEscapeOrDeleteKey(e:KeyboardEvent):void {
 			if ((e.charCode == Keyboard.ESCAPE) || (e.keyCode == Keyboard.DELETE) || (e.keyCode == Keyboard.BACKSPACE)) {
 				try {
	 				var theField:DateField = DateField(e.currentTarget);
	 				theField.selectedDate = null;
	 				e.preventDefault();
	 				e.stopImmediatePropagation();
 				} finally {};
 			}
 		}
 		
 
// convert byte array to Image
		/**
		 * Convert a ByteArray containg an image (pgn,jpg,gif) into a bitmap and assig to an Image control.
		 * 
		 * @param ba the ByteArray with the image contents. must be one of the formats supported by Flex
		 * @param img the Image control to assign the image to
		 * 
		 */
		public static function byteArrayToImage(ba:ByteArray, img:Image):void {
			if (ba.length > 0) {
	       		var loader:Loader = new Loader();
	         	loader.loadBytes(ba);
	         	img.callLater(setImage,[loader,img]);
   			} else img.source = null;
        }
        private static function setImage(loader:Loader, img:Image):void {
        	if (loader.content) img.source = Bitmap(loader.content) else img.callLater(setImage,[loader,img]);
        }

	}
}