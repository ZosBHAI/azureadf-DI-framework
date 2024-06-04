# azureadf-DI-framework (In progress)
This is a pet project done as a part of my azure adf learning.  In this project I have tried to build a Data Ingestion framework for JDBC sources. It is tested on  Azure SQL DB.
## Requirement
1. Onboarding of any new JDBC source with no code changes or minimal modifications to the existing framework.
2. Restart only the failed tables in the subsequent run
3. Track the run status of each table associated with a source.
4. Adding a new type of source doesn't change the structure of the existing configuration table.
## Design
- Use 2 control table:  
        1. TestMetadataControlTable - Store the configuration related to ingestion.All  the configuration are stored in JSON format.  
        2. TestPipelineRun - Capture the run status of each table.
- Configuration related to Tables are stored as JSON struture in the Control table under a single column. So,adding  or removing the configuration will not alter the structure of the  TestMetadataControlTable. This would fulfill requirement 4. Idea of saving the configuration as JSON is from the COPY DATATOOL in ADF. 
    - Ref:[Copy Datatool reference](https://learn.microsoft.com/en-us/azure/data-factory/copy-data-tool-metadata-driven)
- TestPipelineRun will satisfy the requirement 2 and 3.
- Each run would create a batch execution date, that is used identify the run status of table for that day. Batch execution date is generated only the previous run is successful. Uses the last successful batch execution date , if previous run is failed for any of the object associated with the source.
- 2 ingestion pattern supported (full load and incremental)
- For incremental load, use Watermark column to read the delta records. Watermark column needs to be timestamp column.  
- For incremental load , delta records are identified using the logic `Watermark column >= last succesful execution`
- Pictorical representation of Incremental logic
- Description of important columns in Control tables.
    | Column | Table Name |Description |
    | ------ | ------ |  ------ |
    | sourceName | TestMetadataControlTable | Unique name that identify the source. All the tables under a source should be grouped using this value.|
    | TableName | TestMetadataControlTable | Name of the object to be ingested.|
    | Config | TestMetadataControlTable | Store the configuration related to ingestion in JSON format.|
    | Status | TestPipelineRun | Data ingestion status of a table. It can be `Success` or `Failed`. |
    | ExecDate | TestPipelineRun | Date that  is generated as a part of Pipeline run and it is unique for a run. |
    | LastSuccessfullExecDate | TestPipelineRun |  Last successfull execution of the data ingestion pipeline. Upon successful ingestion of the table, this value will be the same as `ExecDate`. |
## Sample incremental table configuration 
    {
        "SourceObjectSettings": {
            "schema": "dbo",
            "table": "Orders",
            "url": "vvtestadf-sname-sn.database.windows.net",
            "username": "adfadmin",
            "password":"Password123",
            "database" : "vvtestadf_dbname_sqldb"
        },
        "SinkObjectSettings": {
            "storageAccount" : "vvtestadfdevsg",
            "fileName": "dbo_orders",
            "directory": "source1",
            "fileSystem": "raw",
            "partitionColName": "exec_date",
            "targetTable": "dbo_orders",
            "targetSchema": "dest_dbo",
            "stageSchema": "stage_dbo"

        },
        "CopySourceSettings": {
            "partitionOption": "None",
            "sqlReaderQuery": "None",
            "partitionLowerBound": null,
            "partitionUpperBound": null,
            "partitionColumnName": null,
            "partitionNames": null
        },
        "DataLoadingBehaviorSettings": {
            "dataLoadingBehavior": "incr",
            "watermarkColumnName": "OrderDate",
            "watermarkLookbackDays": 0,
			"primaryKey":"OrderID"
              }
        }
## Framework Structure 
- Master Orchestrator Pipeline
- Config Parser Pipeline
- Ingestion Pipeline
