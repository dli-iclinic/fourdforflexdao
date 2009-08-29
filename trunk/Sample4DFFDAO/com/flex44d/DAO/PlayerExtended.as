package com.flex44d.DAO
{
	public class PlayerExtended extends Player
	{
		public function PlayerExtended()
		{
			super();
			_tableDescription.appendChild(<field name="PlayerPosition" longname="PlayerPosition.Name" type="text" isrelated="true"/>);
			_tableDescription.appendChild(<field name="YOBSQL" formula="YEAR(Current_Date())-Player.Age" type="int"/>);
			_tableDescription.appendChild(<field name="FullName" formula="CONCAT(CONCAT(Player.First_Name,' '),Player.Name)" type="text"/>);
		}

		public static const kPlayerPosition:String = 'PlayerPosition.Name';
		private var _PlayerPosition:String;
		public function set PlayerPosition (v:String):void {this._PlayerPosition = v;}
		public function get PlayerPosition ():String {return this._PlayerPosition;}

		private var _YOBSQL:int;
		public function set YOBSQL (v:int):void {this._YOBSQL = v;}
		public function get YOBSQL ():int {return this._YOBSQL;}

		private var _FullName:String;
		public function set FullName (v:String):void {this._FullName = v;}
		public function get FullName ():String {return this._FullName;}
		
	}
}