package com.flex44d.DAO
{
	public class PlayerExtended extends Player
	{
		public function PlayerExtended()
		{
			super();
			_tableDescription.appendChild(<field name="PlayerPosition" longname="PlayerPosition.Name" type="text" isrelated="true"/>);
			_tableDescription.appendChild(<field name="YOB" formula="YEAR(Current_Date())-Player.Age" type="int"/>);
			_tableDescription.appendChild(<field name="FullName" formula="CONCAT(CONCAT(Player.First_Name,' '),Player.Name)" type="text"/>);
		}

		public static const kPlayerPosition:String = 'PlayerPosition.Name';
		private var _PlayerPosition:String;
		public function set PlayerPosition (v:String):void {this._PlayerPosition = v;}
		public function get PlayerPosition ():String {return this._PlayerPosition;}

		private var _YOB:int;
		public function set YOB (v:int):void {this._YOB = v;}
		public function get YOB ():int {return this._YOB;}

		private var _FullName:String;
		public function set FullName (v:String):void {this._FullName = v;}
		public function get FullName ():String {return this._FullName;}
		
		//-----------------
		// Overrides
		//-----------------
		override public function set First_Name(v:String):void {
			super.First_Name = v;  // run super class setter
			setFullName();			// calculate our Full Name
		}
		override public function set Name(v:String):void {
			super.Name = v;  // run super class setter
			setFullName();
		}
		
		public var calcFullName:String;	// calcualte Full Name storage
		private function setFullName():void {
			// assemble Full Name as 'lastname, firstname'
			if (First_Name || First_Name == '' ) {
				calcFullName = Name		// no first name, use last name alone
			} else {
				calcFullName = Name + ', ' + First_Name;
			}
		}
		
	}
}