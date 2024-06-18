# azureadf-DI-framework (In progress)
This is a pet project done as a part of my azure adf learning.  In this project I have tried to build a Data Ingestion framework for JDBC sources. It is tested on  Azure SQL DB.
## Requirement
1. Easy to onboard new JDBC type with minimal changes in the ingestion framework.
2. Rerun only the failed tables in the subsequent run
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
- Pictorical representation of Incremental logic.
    - Ref: [https://techcommunity.microsoft.com/t5/azure-data-factory-blog/metadata-driven-pipelines-for-dynamic-full-and-incremental/ba-p/3925362]
    - ![Alt text](/diagram/ADF_incremental_DI_flow.png?raw=true "Incremental Data Ingestion Flow")
  
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
- Master Orchestrator Pipeline [pl_master_orch_jdbc]
    -  Generate the batch execution date. [[flowchart](https://github.com/ZosBHAI/azureadf-DI-framework/blob/main/diagram/batch_execution_date_logic.md)]
        -  inputs:
            -  sourcename
            -  firstloadflag
                - description : This flag is an indicator for first load.
                - default value : F
                - accepted values :  T or F 
            -  retryfailedflag
                - description : This flag selectively restart the failed tables from previous run. 
                - default value : F
                - accepted values :  T or F   
    -  Get the list of objects associated with source. [[flowchart](https://github.com/ZosBHAI/azureadf-DI-framework/blob/main/diagram/get_list_of_objects_tobe_ingested.md)]
    -  Trigger the Config Parser Pipeline  for each table associated with the source.
- Config Parser Pipeline [[pl_jdbc_config_parser](https://github.com/ZosBHAI/azureadf-DI-framework/blob/main/diagram/parser_pipelineflow.png)]
    - Get the configuration for specific table from `TestMetadataControlTable`.
    - Compute the last succesfull execution logic.
    	- if the first load flag is True, then return `-1` as last successfull execution date.
     	- if the first load flag is False, then return execution date of table's last successfully completed from  TestPipelineRun.
      	- if the table is not present in the  TestPipelineRun, then return `-1` as last successfull execution date.
    - Check for  the ingestion stratergy and trigger the load.
        - For full load, trigger `pl_fullload_jdbc_sql_child`
        - For incremental load, trigger `pl_incr_jdbc_sql_child`
    - Capture the status of ingestion in `TestPipelineRun` control table.
  
- Ingestion Pipeline
    - Incremental load  Pipeline [pl_incr_jdbc_sql_child]
        - If the first load flag is True, read entire table.Else read the records greater than the last successfull execution date.
        - Data read from the source table is stored in the Azure blob storage.
        - Read the data from Azure blob storage to Stage table
        - Stage tables stores the delta records for the day.
        - For first load, drop the table and recreate the table. Table structure is same as the Stage table structure.
        - For subsequent load, merge the stage table with target table.
    - Full load Pipeline [pl_fullload_jdbc_sql_child]
        - Read all the  records from source
        - Write all the records to Azure blob storage and target table.
## Installing and Configuring the Framework
1) Download or Clone this repo. `adfcode` has all the artificats related to   Ingestion framework.
2) Create the Control table. DDL is available here. [DDL](https://github.com/ZosBHAI/azureadf-DI-framework/blob/main/tools/SQLused.sql)
3) Use the sample configure mentioned above or it is available in the `tools --> SQLused.sql`. 
4) To run the framework, refer the DEMO SECTION in the Youtube vedio.
## Limitation 
- If you are using SQL Server to host control table, it must be SQL Server 2016 (13.x) and later in order to support OPENJSON function.
- Framework expects `Watermark column` to be of timestamp datatype. But copy data tool from ADF support identity column or column with monotonically increasing value.
- For onboarding new JDBC source, say for example if the source is ORACLE, then the framework has to be modified to inlcude new LinkedService, Dataset poinitng to ORACLE.
  - Schema evolution cases are not handled.
## Things learned as part of building this framework
   [Lessons Learned](https://github.com/ZosBHAI/azureadf-DI-framework/blob/main/notes/notes_leasons_learned.md)
