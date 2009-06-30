package com.flex44d.datamodel
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.utils.getDefinitionByName;
	import flash.utils.getQualifiedClassName;
	
	import fourD.sql.SQLField;
	import fourD.sql.SQLResultSet;
	import fourD.sql.SQLService;
	import fourD.sql.events.resultSet.SQLFetchResultCompleteEvent;
	import fourD.sql.events.resultSet.SQLResultSetEvent;
	import fourD.sql.events.statement.SQLInsertCompleteEvent;
	import fourD.sql.events.statement.SQLSelectCompleteEvent;
	import fourD.sql.events.statement.SQLStatementEvent;
	import fourD.utils.Tracer;
	
	import mx.collections.ArrayCollection;
	import mx.rpc.AsyncToken;

	/*******************************************************
	 * 
	 * Release Notes
	 * 
	 * 3.09.04.09a - julio, Apr 9, 2009
	 *  - add option to getRecord with a query string
	 * 
	 * 3.09.04.25a - julio, Apr 25, 2009
	 *  - set current record # after insert
	 * 
	 * 3.09.05.04 - julio, May 04, 2009
	 *  - if multiple records retrieved in a getRecord() call, populate record collection
	 * 		and use the first record to populate fields.
	 * 
	 *********************************************************/	
	
	[Bindable]
	public class DataModelBase extends EventDispatcher
	{
		//--------------------------------------
		//  Version...
		//--------------------------------------
		public static var version:String = "1.09.05.04a";					// DataModelBase Version MUST be updated

		//-------------------
		// Events
		//-------------------
		/**
		 * dispatched when a record has been loaded 
		 */
		[Event(name='loaded', type='flash.events.Event')]
		public static const LOADED:String = 'loaded';
		

		//-------------------
		// Overridable Properties
		//-------------------
		/**
		 * Name of the table the record maps to
		 */
		public var TableName_:String;
		
		/**
		 * Table's primary key field name 
		 */
		public var PrimaryKey_:String;
		
		/**
		 * 4D SQL Connection
		 */
		public function set fourDConnection(v:SQLService):void {
			_v11Connection = v;
		}
		
		
		//-------------------
		// Properties
		//-------------------
		
		/**
		 * 4D's resultSet after getRecord or getRecordList 
		 */
		public var resultSet:SQLResultSet;
		
		/**
		 * this record's index into 4D's resultSet after getRecord or getRecordList 
		 */
		public var recordIndex:int = -1;
		
		
		/**
		 * Collection of records loaded after getRecord or getRecordList 
		 */
		public var recordCollection:ArrayCollection = new ArrayCollection();
		
		//-------------------
		// Variables
		//-------------------
		private static var _v11Connection:SQLService;	// keep 1 single connection to 4D

		/**
		 * 4D Table description in XML format
		 * 
		 * table metadata in the format:
		 * <record primaryKey="" tablename="">
		 *    <field name=""
		 * 			 longname="table.field"
		 * 			 type="text | date | time | boolean | int | real"
		 * 			 length=""
		 * 			 list="associated 4D list name"
		 * 			 isrelated="true | false"
		 * 			 formula="4D expression for calculated fields"
		 * 			 readonly="true"
		 * 			 required="true"/>
		 */
		protected var _tableDescription:XML = <record/>;
		
		//-------------------
		// Constructor
		//-------------------
		public function DataModelBase()
		{
		}

		
		//-------------------
		// Public methods
		//-------------------
		/**
		 * Retrieve a record from 4D and populate its instance variables.
		 *  
		 * @param callback callback function that gets called when the record is loaded.
		 * @param recordID primary key value for the record to retrieve (optional, it defaults to the rowID property)
		 * @param query query string for the record to retrieve (optional, it defaults to the rowID property)
		 * 
		 * <p>callback function signature is</p>
		 * <pre>callback(recordData:XML):void<pre>
		 * 
		 * @param recordID optional record ID, if specified the record is retrieved by querying on its primary key field
		 * 
		 */
		public function getRecord(callback:Function=null, recordID:String=null, query:String=null):void
		{
			var tok:AsyncToken;
			
			if (recordID) {
				if (!PrimaryKey_) {
					// uh-oh no primary key field for this record, duh!
					throw new ReferenceError("No Primary Key specified for "+TableName_);
					return;
				} else {
					// getting a record based on its primary key
					tok=buildVOSelectFrom4D(TableName_,TableName_+'.'+PrimaryKey_+';=;'+recordID,buildColumnList());
				}
			} else if (query) {
					// getting a record based on a query
					tok=buildVOSelectFrom4D(TableName_,query,buildColumnList());				
			} else {
				throw new ReferenceError('No valid query or record ID indicated for '+TableName_);
				return
			}
			
			recordCollection = new ArrayCollection();		// clean up current record collection
			resultSet = null;								// and no current result Set either
						
			// now stuff some parameters into the AsyncToken so we can get to them when the request completes
			
			tok.callback = callback;										// pass along callback method
			tok.addEventListener(SQLStatementEvent.SELECT_COMPLETE,gotRecordFrom4D);
			
		}
		
		// handle record received from 4D
		private function gotRecordFrom4D(e:SQLSelectCompleteEvent):void {
			// the event target is our AsyncToken request
			var tok:AsyncToken = AsyncToken(e.target);
						
			// retrieve our parameters from the AsyncToken
			var callback:Function = tok.callback;
			
			// save the request's resultSet instance, we need it in case user wants to update/delete record
			resultSet = e.resultSet;		
			resultSet.autoSubmitChanges = false;						// disable auto commit
			
			if (resultSet.length >= 1) {			// did we get anything back from 4D?
				deserializeRecord(resultSet[0]); 	// and populate received fields
				recordIndex = 0;
				recordCollection = new ArrayCollection([this]); // save current record list				
				
				if (callback != null) callback(); 	// if a callback method set, call it
				dispatchEvent(new Event(LOADED));	// dispatch record loaded event
			} else {
				// no record retrieved
			}
		}

		
		/**
		 * Retrieve a list of records using a query string 
		 * @param query
		 * @param callback callback function that gets called when the record is loaded.
		 * 
		 * <p>callback function signature is</p>
		 * <pre>callback(resultSet:ArrayCollection):void<pre>
		 * <i>(see Flex44DInterface.getRecordList() for details)</i>
		 * 
		 * 	@param columnList custom column list to retrieve, XML listing the columns to retrieve.
		 * <p>if informed, only the columns listed will be retrieve instead of the whole record</p>
		 * 
		 * 	@param startRec the starting record number to retrieve, used for paging.
		 * 	@param numOfRecords the number of records to retrieve, the default -1 will retrieve all records in the resulting query.
		 * @param filterOptions
		 * 
		 */
		public static function getRecordList(modelVO:DataModelBase,
											 query:String,
											 callback:Function=null,
											 columnList:XML=null,
											 startRec:int=0,
											 numOfRecords:int=-1,
											 orderBy:String=''):AsyncToken {
											 	
			// prepare and send SELECT request to 4D
			var tok:AsyncToken = buildVOSelectFrom4D(modelVO.TableName_,query,(columnList)?columnList:modelVO.buildColumnList(),startRec,numOfRecords,orderBy);
			
			// now stuff some parameters into the AsyncToken so we can get to them when the request completes
			
			tok.callback = callback;										// pass along callback method
			tok.VO = getDefinitionByName(getQualifiedClassName(modelVO));	// and the record VO definition 
			
			// listen on a SELECT_COMPLETE event, wait till 4D tells us the select has executed..
			tok.addEventListener(SQLStatementEvent.SELECT_COMPLETE,selectCompleteHandler);
			
			// we return our AsyncToken to the user and he/she want to do something with it
			return tok;
		}
		
		// SELECT_COMPLETE comes before records are loaded, all we do here is save the resultSet object to use it after a Fetch completes
		private static function selectCompleteHandler(e:SQLSelectCompleteEvent):void {
			// the event target is our AsyncToken request
			var tok:AsyncToken = AsyncToken(e.target);
			
			// save the request's resultSet instance, we need it when the Fetch completes
			tok.resultSet = e.resultSet;
			
			// make sure select retrieved any records
			if (e.resultSet.nbRecords == 0) {
				// no records retrieved... call user's callback method if set
				if (tok.callback != null) tok.callback(new ArrayCollection());	// call users's callback with an empty record collection
				return; 		// and we are done here...
			}
			
			// we do have records to fetch, so now wait for record fetch to complete
			tok.addEventListener(SQLResultSetEvent.FETCH_RESULT_COMPLETE,fetchCompleteHandler);
			trace('SELECT: ','nbLoadedRecords:',e.resultSet.nbLoadedRecords,', nbRecords:',e.resultSet.nbRecords);
		}
		
		// FETCH_RESULT_COMPLETE handler, use 4D's resultSet to instantiate a collection of record VOs
		private static function fetchCompleteHandler(e:SQLFetchResultCompleteEvent):void {
			// the event target is our AsyncToken request
			var tok:AsyncToken = AsyncToken(e.target);
			
			// retrieve our parameters from the AsyncToken
			var cls:Class = tok.VO as Class;							// the record VO class 
			var callback:Function = tok.callback;						// a user specified callback method
			var resultSet:SQLResultSet = SQLResultSet(tok.resultSet); 	// the resultSet from 4D
			
			resultSet.autoSubmitChanges = false;						// disable auto commit
			
			// now build a collection of record VO instances and send that back to the user.
			var recordCollection:ArrayCollection = new ArrayCollection();
			trace('FETCH: ','nbLoadedRecords:',resultSet.nbLoadedRecords,', nbRecords:',resultSet.nbRecords);
			//----------------------
			// there's a bug in 4D for Flex where more records are fetched than indicated by the preFetch property
			// and you cannot rely on nbLoadedRecords.
			// so we use preFetch to loop on the # of records retrieved
			// nbLoadedRecords is also bogus when NO record is found... it always returns the preFetch, when no record was retrieved.
			//----------------------
			var recordCount:int = (resultSet.nbLoadedRecords < resultSet.prefetch)?resultSet.nbLoadedRecords:resultSet.prefetch;
			for (var i:uint=0; (i<recordCount) && (i<resultSet.length);i++) {
				var rec:Object = resultSet.getItemAt(i);	// get this one record
				if (rec == null) {trace (i);break;}			// make sure it is a valid one....
				
				// instantiate a new VO 
				var obj:* = new cls();
				
				// and deserialize 4D's record to populate our VO
				DataModelBase(obj).deserializeRecord(rec);
				
				// save this record's index (we need that for update/delete down the road)
				DataModelBase(obj).recordIndex = recordCollection.length;
				
				// add this VO to the record collection
				recordCollection.addItem(obj);
				
				// we also store link back to the record collection and resultSet in the VO
				DataModelBase(obj).resultSet = resultSet;
				DataModelBase(obj).recordCollection = recordCollection;
			}
			
			// call user's callback method if set.
			if (callback != null) callback(recordCollection);
			
			//----------------------
			// there's a bug in 4D for Flex where more records are fetched than indicated by the preFetch property
			// so we remove our listener to avoid retrieving ALL records
			//----------------------			
			tok.removeEventListener(SQLResultSetEvent.FETCH_RESULT_COMPLETE,fetchCompleteHandler);
		}
				
		
		/**
		 * insert a new record in the database.
		 *  
		 * @param callback method to be called after the record insertion completes (optional).
		 * <p>the callback signature is:</p>
		 * <pre>callback():void</pre>
		 * 
		 * <p><i>the primary key property is set after the record is inserted</i>/<p>
		 * 
		 */
		public function insertRecord(callback:Function=null):void {
			if (resultSet) {
				// if we have a result Set already... proceed with the insert
				
				//
				// 4D for Flex's insert does not work for Images
				// so we need to build an Insert Object with only those fields we can populate
				//
				var insertObject:Object = new Object();
				for each (var field:XML in _tableDescription.field) {
					var fieldName:String = field.@name;
					if (!isCalculatedField(field) && !isRelatedField(field) && !isReadOnly(field)) { // May/15/09 send all non-read only fields, empty or not
						if (field.@type != 'picture') insertObject[fieldName] = this[fieldName];
					}
				}
				
				// now that we have our insert object ready, send it to 4D
				resultSet.insertRecord(insertObject);
				// make sure we do commit our changes
				if (!resultSet.autoSubmitChanges) resultSet.submitChanges();
				
				// now wait for the insert to complete
				resultSet.addEventListener(SQLResultSetEvent.SUBMIT_CHANGES_COMPLETE,function (e:Event):void {insertRecordDone(callback)})

			} else {
				//
				// to use 4D for Flex insert method we need a SQLResultSet
				// I could not find any other way to 'create' a SQLResultSet then to do a fake select
				// that will surely get me a SQLResultSet
				// stupid, I know but till we get some more feedback from 4D, this will do the trick...
				//
				buildVOSelectFrom4D(TableName_,'',buildColumnList(),0,1).addEventListener(SQLStatementEvent.SELECT_COMPLETE,function (e:SQLSelectCompleteEvent):void {resultSet = e.resultSet; insertRecord(callback);});
			}
			
		}
			
		private function insertRecordDone(callback:Function=null):void {
//			if (PrimaryKey_ != null) this[PrimaryKey_]=recID;
			
			recordCollection = new ArrayCollection([this]); // save current record list
			recordIndex = resultSet.length-1;
			if (callback != null) callback();
		}
		
		/**
		 * update record in the database.
		 *  
		 * @param callback method to be called after the record update completes (optional).
		 * <p>the callback signature is:</p>
		 * <pre>callback():void</pre>
		 * 
		 * 
		 */
		private var _updateCallback:Function;
		public function updateRecord(callback:Function=null):void {
			// make sure we do have a record to update
			if (resultSet.length > 0 && recordIndex >= 0) {
				for each (var field:XML in _tableDescription.field) {
					var fieldName:String = field.@name;
					if (!isCalculatedField(field) && !isRelatedField(field) && !isReadOnly(field)) { // May/15/09 send all non-read only fields, empty or not
						// find this field index...
						for (var fieldIndex:int=0; fieldIndex < resultSet.fields.length; fieldIndex++) {
							if (SQLField(resultSet.fields[fieldIndex]).name == fieldName) {
								resultSet.updateRecordAt(recordIndex,fieldIndex,this[fieldName]); // update this field
								break;
							} 
						}
					}
				}
				
				resultSet.submitChanges();
				if (callback != null) {
					_updateCallback = callback;
					resultSet.addEventListener(SQLResultSetEvent.SUBMIT_CHANGES_COMPLETE,updateRecordDone);
				}
					
			} else {
				// uh oh, can't update if no current record!!
				throw new ReferenceError("no current record for update action");
				return;
			}
		}
		private function updateRecordDone(e:SQLResultSetEvent):void {
			if (_updateCallback != null) _updateCallback();
		}
		
		/**
		 * delete current record
		 *  
		 * @param callback method to be called when record deletion completes (optional).
		 * <p>the callback signature is:</p>
		 * <pre>callback():void</pre>
		 * 
		 * 
		 */
		private var _deleteCallback:Function;
		public function deleteRecord(callback:Function=null):void {
			// make sure we do have a record to delete
			if (resultSet.length > 0 && recordIndex >= 0) {
				resultSet.deleteRecordAt(recordIndex);
				resultSet.submitChanges();
				if (callback != null) {
					_deleteCallback = callback;
					resultSet.addEventListener(SQLResultSetEvent.SUBMIT_CHANGES_COMPLETE,deleteRecordDone);
				}
			} else {
				// uh oh, can't update if no current record!!
				throw new ReferenceError("no current record for delete action");
				return;
			}
		}
		private function deleteRecordDone(e:SQLResultSetEvent):void {
			resultSet.removeEventListener(SQLResultSetEvent.SUBMIT_CHANGES_COMPLETE,deleteRecordDone); // stop listening to this event
			if (_deleteCallback != null) _deleteCallback();
		}
		
		
		
		/**
		 * test to see if the instance contains a valid record loaded
		 * @return true, is a valid record is present
		 * 
		 */
		public function doWeHaveARecordLoaded():Boolean {
			return (resultSet.length > 0);
		}
		
		//-------------------
		// Utility methods
		//-------------------
		public function clear():void {
			recordIndex = -1;
			resultSet = null;
			recordCollection = null;
		}
		
		//-------------------
		// Private Utility methods
		//-------------------
		
		/**
		 * Populate fields in our VO from a record retrieved from 4D
		 *  
		 * @param rec serialized record contents as received from 4D.
		 * 
		 */
		private function deserializeRecord(rec:Object):void {
			for (var field:String in rec) { 		// loop thru all fields in the received record
				if (this.hasOwnProperty(field)) { 	// make sure field name is indeed valid and we have it in our VO
					this[field] = rec[field]; 		// the get field value coming from 4D
				}
			}
		}


		 private static function buildVOSelectFrom4D(tableName:String, queryString:String, columnList:XML, startRec:int=0, numOfRecords:int=-1, orderBy:String=''):AsyncToken {
	   			var builtSQL:String = "";
	   			var fromString:String = " from "+tableName;
	   			var joinString:String = '';
	   			
	   			if (columnList.children().length() == 0) builtSQL = "*";
				for each (var col:XML in columnList.children()) {
					if (builtSQL == "") builtSQL+=String(col.valueOf()) else builtSQL+=', '+String(col.valueOf());
					if (String(col.@name) != '') builtSQL+=" as "+String(col.@name);
					var parts:Array = String(col.valueOf()).split('.');
					if (String(parts[0]).toLowerCase() != tableName.toLowerCase() ) {
						// field is from a related table, so we need to add join to the sql statement
						var joinTable:String = String(parts[0]).toUpperCase();
						if (fromString.indexOf(joinTable) <= 0) { // test if we've joined this table already
							// new join
							fromString += ', '+joinTable;
/* 							var index:int = relateOneTables.indexOf(joinTable);
							if (index >= 0) {
								if ((queryData == null ) || (queryData == 'all') || (queryData == '')) joinString = ' where '+ browseTable+'.'+relateManyFields[index] + '=' + joinTable+'.'+relateOneFields[index]
								else joinString += ' and '+ browseTable+'.'+relateManyFields[index] + '=' + joinTable+'.'+relateOneFields[index];						
							}
 */						}
					}
				}
				
				builtSQL+= fromString;
	   			
				if ((queryString != null ) && (queryString != '') && (queryString != 'all')) builtSQL+= ' where '+queryString;
				
				builtSQL+= joinString + orderBy;
				
				if (startRec > 0) builtSQL+= " OFFSET "+String(startRec);
				if (numOfRecords >0) builtSQL+= " LIMIT "+String(numOfRecords);
				
				trace();
				Tracer.traceInformation('sql: '+builtSQL);

				return _v11Connection.execute('select '+builtSQL);
		 }
		 
		/**
		 * @private
		 * build list of fields to retrieve from the database.
		 *  
		 * @return XML in the format
		 *    <columns>;
		 *      <column name="rowid">ROWID(table)</column>;
		 *      <column name="field">table.field</column>;
		 *      ...
		 *    </columns>
		 * 
		 */
		private function buildColumnList():XML {
			var columnList:XML = <columns/>;
			var col:XML;

			for each (var field:XML in _tableDescription.field) {
				if (isCalculatedField(field)) {
					var expression:String = String(field.@formula);
					col = <column>{'['+expression+']'}</column>;
				} else {
					col = <column>{String(field.@longname)}</column>;
				}
				col.@name = field.@name;
				columnList.appendChild(col);
				
			}
			return columnList;
		}
		
		/**
		 * @private 
		 * Checks to see if a field is from a related table
		 * 
		 * @param field field description for the Class definition
		 * @return true if field is on a related table
		 * 
		 */
		private function isRelatedField(field:XML):Boolean {
			return (field.@isrelated == 'true');
		}
		
		/**
		 * @private 
		 * Checks to see if a field is a calculated field
		 * 
		 * @param field field description for the Class definition
		 * @return true if field is on a related table
		 * 
		 */
		private function isCalculatedField(field:XML):Boolean {
			return (String(field.@formula) != '');	
		}
		
		/**
		 * @private 
		 * Checks to see if a field is read only
		 * 
		 * @param field field description for the Class definition
		 * @return true if field is read only
		 * 
		 */
		private function isReadOnly(field:XML):Boolean {
			return (String(field.@readonly) == 'true');	
		}
			
			
	}
}