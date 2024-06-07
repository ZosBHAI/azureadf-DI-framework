---How to INSERT the configuration ----



DROP PROCEDURE GetExecutionDate;
CREATE PROCEDURE controlTable.GetExecutionDateV05(
    @sourcename VARCHAR(50),
	@firstload VARCHAR(3),
    @execdate VARCHAR(30) OUTPUT,
	@previousrunstatus VARCHAR(10) OUTPUT)

AS
BEGIN
	SET NOCOUNT ON
	DECLARE @totaltables int;
	DECLARE @lastexecdate VARCHAR(30);
	DECLARE @failedtables int;
	if @firstload = 'T'
	BEGIN 
		SET @execdate = format(GETDATE(),'yyyy-MM-dd-hh-mm-ss');
		SET @previousrunstatus = 'SUCCESS';
	END	
	else 
		BEGIN
			SELECT @totaltables = count(1) from [controlTable].[TestMetadataControlTable]
			where sourceName = @sourcename
			PRINT 'NUMBER OF OBJECTS FOR THE SOURCE';
			PRINT @totaltables;
			SELECT @lastexecdate = max(ExecDate) from [controlTable].[TestPipelineRun] 
			where sourceName = @sourcename
			SELECT @failedtables = count(1) from [controlTable].[TestPipelineRun]  	
			where sourceName = @sourcename 
			and Status = 'Failed' and ExecDate = @lastexecdate
			-- checking all the tables
			if @failedtables > 0
			   BEGIN 
				SET @execdate = @lastexecdate
				SET @previousrunstatus = 'FAILED';
			   END
			else
			   BEGIN 
				SET @execdate = format(GETDATE(),'yyyy-MM-dd-hh-mm-ss')
				SET @previousrunstatus = 'SUCCESS';
			   END
			END
			SELECT @execdate as execdate , @previousrunstatus as previousrunstatus
		
END
DECLARE @op VARCHAR(30);
DECLARE @st VARCHAR(30);
exec controlTable.GetExecutionDateV04 @sourcename = 'source1',@firstload ='F' ,@execdate= @op OUTPUT, @previousrunstatus= @st OUTPUT;
PRINT @op;
PRINT @st;
--------Testing the logic 
DECLARE @sourcename VARCHAR(50);
DECLARE @firstload VARCHAR(3);
DECLARE @totaltables int;
DECLARE @lastexecdate VARCHAR(30);
DECLARE @failedtables int;
DECLARE @execdate VARCHAR(30);
SET @firstload = 'F'
SET @sourcename = 'source1'
	if @firstload = 'T'
	BEGIN 
		SET @execdate = format(GETDATE(),'yyyy-MM-dd-hh-mm-ss');
	END	
	else 
		BEGIN
			SELECT @lastexecdate = max(ExecDate) from [controlTable].[TestPipelineRun] where sourceName = @sourcename
			SELECT @failedtables = count(1) from [controlTable].[TestPipelineRun]  	where sourceName = @sourcename and Status = 'Failed' and ExecDate = @lastexecdate
            PRINT 'SUBSEQUENT LOAD';
		    PRINT @lastexecdate;
            PRINT @failedtables;
			if @failedtables > 0 
			   SET @execdate = @lastexecdate
			else 
			   SET @execdate = format(GETDATE(),'yyyy-MM-dd-hh-mm-ss')
        END
	PRINT @execdate;
-------------------------------------------
CREATE PROCEDURE controlTable.GetListOfObjects(
    @sourcename VARCHAR(50),
	@previousrunstatus VARCHAR(10),
    @retryfailedflag  VARCHAR(3)
	)

AS
BEGIN
	SET NOCOUNT ON

	DECLARE @lastexecdate VARCHAR(30);

	if @previousrunstatus  = 'FAILED' and @retryfailedflag = 'T'
		BEGIN
			SELECT @lastexecdate = max(ExecDate) from [controlTable].[TestPipelineRun] 
			 where sourceName = @sourcename
			 SELECT TableName from [controlTable].[TestPipelineRun]  	
					where sourceName = @sourcename 
					and Status = 'Failed' and ExecDate = @lastexecdate
		END
		
	 
	else
		select TableName from [controlTable].[TestMetadataControlTable]
		where sourceName = @sourcename
	   
END
--------TEsting the logic
DECLARE @lastexecdate VARCHAR(30);
DECLARE @sourcename VARCHAR(50);
DECLARE @previousrunstatus VARCHAR(10);
DECLARE @retryfailedflag  VARCHAR(3);
SET @previousrunstatus = 'SUCCESS'
SET @sourcename = 'source1'
SET @retryfailedflag = 'T'
if @previousrunstatus  = 'FAILED' and @retryfailedflag = 'T'
		BEGIN
			SELECT @lastexecdate = max(ExecDate) from [controlTable].[TestPipelineRun] 
			 where sourceName = @sourcename
			 SELECT TableName from [controlTable].[TestPipelineRun]  	
					where sourceName = @sourcename 
					and Status = 'Failed' and ExecDate = @lastexecdate
		END
		
	 
	else
		select TableName from [controlTable].[TestMetadataControlTable]
		where sourceName = @sourcename
		
		
DECLARE @lastexecdate VARCHAR(30);
DECLARE @sourcename VARCHAR(50);
DECLARE @previousrunstatus VARCHAR(10);
DECLARE @retryfailedflag  VARCHAR(3);
SET @previousrunstatus = 'FAILED'
SET @sourcename = 'source1'
SET @retryfailedflag = 'F'
if @previousrunstatus  = 'FAILED' and @retryfailedflag = 'T'
		BEGIN
			SELECT @lastexecdate = max(ExecDate) from [controlTable].[TestPipelineRun] 
			 where sourceName = @sourcename
			 SELECT * from [controlTable].[TestPipelineRun]  	
					where sourceName = @sourcename 
					and Status = 'Failed' and ExecDate = @lastexecdate
		END
		
	 
	else
		select * from [controlTable].[TestMetadataControlTable]
		where sourceName = @sourcename


--------- config prep

 ---1) Insert sql
INSERT INTO [controlTable].[TestMetadataControlTable] (sourceName,TableName,Config) 
values ('source1','project_table_incr', N'{
        "SourceObjectSettings": {
            "schema": "dbo",
            "table": "project_table",
            "url": "vvtestadf-sname-sn.database.windows.net",
            "username": "adfadmin",
            "password":"Password123",
            "database" : "vvtestadf_dbname_sqldb"
        },
        "SinkObjectSettings": {
            "storageAccount" : "vvtestadfdevsg",
            "fileName": "dbo_project_table",
            "directory": "source1",
            "fileSystem": "raw",
            "partitionColName": "exec_date",
            "targetTable": "dbo_incr_project_table",
            "targetSchema": "dest_dbo",
            "stageSchema": "stage_dbo"

        },
        "CopySourceSettings": {
            "partitionOption": "None",
            "sqlReaderQuery": "select * from [dbo].[project_table]",
            "partitionLowerBound": null,
            "partitionUpperBound": null,
            "partitionColumnName": null,
            "partitionNames": null
        },
        "DataLoadingBehaviorSettings": {
            "dataLoadingBehavior": "incr",
            "watermarkColumnName": "Creationtime",
            "watermarkLookbackDays": 0
              }
        }
       '
); 
INSERT INTO [controlTable].[TestMetadataControlTable] (sourceName,TableName,Config) 
values ('source1','project_table', N'{
        "SourceObjectSettings": {
            "schema": "dbo",
            "table": "project_table",
            "url": "vvtestadf-sname-sn.database.windows.net",
            "username": "adfadmin",
            "password":"Password123",
            "database" : "vvtestadf_dbname_sqldb"
        },
        "SinkObjectSettings": {
            "storageAccount" : "vvtestadfdevsg",
            "fileName": "dbo_project_table",
            "directory": "source1",
            "fileSystem": "raw",
            "partitionColName": "exec_date",
            "targetTable": "dbo_project_table",
            "targetSchema": "dest_dbo"

        },
        "CopySourceSettings": {
            "partitionOption": "None",
            "sqlReaderQuery": "select * from [dbo].[project_table]",
            "partitionLowerBound": null,
            "partitionUpperBound": null,
            "partitionColumnName": null,
            "partitionNames": null
        },
        "DataLoadingBehaviorSettings": {
            "dataLoadingBehavior": "full",
            "watermarkColumnName": null,
            "watermarkLookbackDays": null
              }
        }
       '
) ;

---Query to validate the Config is  in JSON format
SELECT sourceName, Config FROM [controlTable].[TestMetadataControlTable] WHERE ISJSON(Config) = 1 
		
---Modified MERGE LOGIC 
/* DECLARE @TargetTable VARCHAR (500)
DECLARE @StagingTable VARCHAR (500)
DECLARE @WhereClause VARCHAR(MAX) 
DECLARE @StagingSchema VARCHAR (50)
DECLARE @TargetSchema VARCHAR (50)
DECLARE @FullStagingTableName VARCHAR (500)
DECLARE @FullTargetTableName VARCHAR (500)
DECLARE @TargetTableColumnList NVARCHAR(MAX)
DECLARE @DeleteStatementSQL NVARCHAR (MAX)
DECLARE @InsertStatementSQL NVARCHAR (MAX)
DECLARE @StatisticsUpdateSQL NVARCHAR (MAX)
SET @TargetTable = '@{pipeline().parameters.targetTable}'
SET @TargetSchema = '@{pipeline().parameters.targetSchema}'
SET @StagingTable = '@{pipeline().parameters.targetTable}'
SET @StagingSchema = '@{pipeline().parameters.stageSchema}'
SET @FullStagingTableName = CONCAT(@StagingSchema, '.', @StagingTable)
SET @FullTargetTableName = CONCAT(@TargetSchema, '.', @TargetTable)
SET @TargetTableColumnList = (	SELECT 
									ColumnList = STRING_AGG('[' + col.NAME + ']', ',' )
								FROM
									sys.tables tab
										LEFT JOIN 
									sys.schemas sch
										ON tab.schema_id = sch.schema_id
										LEFT JOIN 
									sys.columns col
										ON tab.object_id = col.object_id
								WHERE 
									sch.name = @TargetSchema
									AND tab.name = @TargetTable
									AND col.is_identity = 0
							)
 ;

 CREATE TABLE #ADLS_Metadata
(
   
    ColumnKey VARCHAR(100),
	TargetTable VARCHAR(50)
)
INSERT INTO #ADLS_Metadata
(
    ColumnKey,
    TargetTable
)
VALUES
('project,Creationtime', 'dest_project_table');
 WITH PrimaryKeyList AS (
						SELECT 
							ColumnKey = RTRIM(LTRIM(Value)),
							RowNumber = ROW_NUMBER () OVER (ORDER BY value ASC)

						FROM
							#ADLS_Metadata
								CROSS APPLY 
							STRING_SPLIT( ColumnKey, ',')
						WHERE 
							TargetTable = @TargetTable
						)
 
SELECT
    @WhereClause = CONCAT(	'CONCAT(', 
							STRING_AGG(CASE 
											WHEN E.ColumnKey IS NOT NULL THEN  Beg.ColumnKey
											ELSE CONCAT(Beg.ColumnKey, ') ')
										END, ', '
										),
							'IN (SELECT CONCAT(', 
							STRING_AGG(CASE 
											WHEN E.ColumnKey IS NOT NULL THEN  Beg.ColumnKey
											ELSE CONCAT(Beg.ColumnKey, ') ')
										END, ', '
										),
							'FROM ', @FullStagingTableName, ')'
						)
FROM 
    PrimaryKeyList Beg
        LEFT JOIN
    PrimaryKeyList E
        ON Beg.Rownumber = E.Rownumber - 1 
        ;
print @WhereClause
SELECT
    @DeleteStatementSQL = CONCAT('DELETE FROM ', @FullTargetTableName, ' WHERE ', @WhereClause) ;
 
SELECT 
    @InsertStatementSQL = CONCAT('INSERT INTO ', @FullTargetTableName, ' (', @TargetTableColumnList, ') ', ' SELECT ', @TargetTableColumnList, ' FROM ', @FullStagingTableName)

EXECUTE sp_executesql @DeleteStatementSQL; 

EXECUTE sp_executesql @InsertStatementSQL; */

-----Replace temp table with TABLE variable --it needs more than one primary key 
DECLARE @tmp TABLE (ColumnKey VARCHAR(100),
	TargetTable VARCHAR(50));
DECLARE @WatermarkColumn VARCHAR (500)
DECLARE @TargetTable VARCHAR (500)
DECLARE @StagingTable VARCHAR (500)
DECLARE @WhereClause VARCHAR(MAX) 
DECLARE @StagingSchema VARCHAR (50)
DECLARE @TargetSchema VARCHAR (50)
DECLARE @FullStagingTableName VARCHAR (500)
DECLARE @FullTargetTableName VARCHAR (500)
DECLARE @TargetTableColumnList NVARCHAR(MAX)
DECLARE @DeleteStatementSQL NVARCHAR (MAX)
DECLARE @InsertStatementSQL NVARCHAR (MAX)
DECLARE @StatisticsUpdateSQL NVARCHAR (MAX)
SET @TargetTable = '@{pipeline().parameters.targetTable}'
SET @TargetSchema = '@{pipeline().parameters.targetSchema}'
SET @StagingTable = '@{pipeline().parameters.targetTable}'
SET @StagingSchema = '@{pipeline().parameters.stageSchema}'
SET @WatermarkColumn = '@{pipeline().parameters.watermarkColumnName}'
SET @FullStagingTableName = CONCAT(@StagingSchema, '.', @StagingTable)
SET @FullTargetTableName = CONCAT(@TargetSchema, '.', @TargetTable)
SET @TargetTableColumnList = (	SELECT 
									ColumnList = STRING_AGG('[' + col.NAME + ']', ',' )
								FROM
									sys.tables tab
										LEFT JOIN 
									sys.schemas sch
										ON tab.schema_id = sch.schema_id
										LEFT JOIN 
									sys.columns col
										ON tab.object_id = col.object_id
								WHERE 
									sch.name = @TargetSchema
									AND tab.name = @TargetTable
									AND col.is_identity = 0
							)
 ;

INSERT INTO @tmp
(
    ColumnKey,
    TargetTable
)
VALUES
(@WatermarkColumn, @TargetTable);
 WITH PrimaryKeyList AS (
						SELECT 
							ColumnKey = RTRIM(LTRIM(Value)),
							RowNumber = ROW_NUMBER () OVER (ORDER BY value ASC)

						FROM
							@tmp
								CROSS APPLY 
							STRING_SPLIT( ColumnKey, ',')
						WHERE 
							TargetTable = @TargetTable
						)
 
SELECT
    @WhereClause = CONCAT(	'CONCAT(', 
							STRING_AGG(CASE 
											WHEN E.ColumnKey IS NOT NULL THEN  Beg.ColumnKey
											ELSE CONCAT(Beg.ColumnKey, ') ')
										END, ', '
										),
							'IN (SELECT CONCAT(', 
							STRING_AGG(CASE 
											WHEN E.ColumnKey IS NOT NULL THEN  Beg.ColumnKey
											ELSE CONCAT(Beg.ColumnKey, ') ')
										END, ', '
										),
							'FROM ', @FullStagingTableName, ')'
						)
FROM 
    PrimaryKeyList Beg
        LEFT JOIN
    PrimaryKeyList E
        ON Beg.Rownumber = E.Rownumber - 1 
        ;
print @WhereClause;
SELECT
    @DeleteStatementSQL = CONCAT('DELETE FROM ', @FullTargetTableName, ' WHERE ', @WhereClause) ;
 
SELECT 
    @InsertStatementSQL = CONCAT('INSERT INTO ', @FullTargetTableName, ' (', @TargetTableColumnList, ') ', ' SELECT ', @TargetTableColumnList, ' FROM ', @FullStagingTableName)
EXECUTE sp_executesql @DeleteStatementSQL; 

EXECUTE sp_executesql @InsertStatementSQL;


-----Merge Logic for One Primary key 
DECLARE @tmp TABLE (ColumnKey VARCHAR(100),
	TargetTable VARCHAR(50));
DECLARE @WatermarkColumn VARCHAR (500)
DECLARE @TargetTable VARCHAR (500)
DECLARE @StagingTable VARCHAR (500)
DECLARE @WhereClause VARCHAR(MAX) 
DECLARE @StagingSchema VARCHAR (50)
DECLARE @TargetSchema VARCHAR (50)
DECLARE @FullStagingTableName VARCHAR (500)
DECLARE @FullTargetTableName VARCHAR (500)
DECLARE @TargetTableColumnList NVARCHAR(MAX)
DECLARE @DeleteStatementSQL NVARCHAR (MAX)
DECLARE @InsertStatementSQL NVARCHAR (MAX)
DECLARE @StatisticsUpdateSQL NVARCHAR (MAX)
SET @TargetTable = 'dest_project_table'
SET @TargetSchema = 'dest_dbo'
SET @StagingTable = 'dest_project_table'
SET @StagingSchema = 'stage_dbo'
SET @WatermarkColumn = 'Creationtime'
SET @FullStagingTableName = CONCAT(@StagingSchema, '.', @StagingTable)
SET @FullTargetTableName = CONCAT(@TargetSchema, '.', @TargetTable)
SET @TargetTableColumnList = (	SELECT 
									ColumnList = STRING_AGG('[' + col.NAME + ']', ',' )
								FROM
									sys.tables tab
										LEFT JOIN 
									sys.schemas sch
										ON tab.schema_id = sch.schema_id
										LEFT JOIN 
									sys.columns col
										ON tab.object_id = col.object_id
								WHERE 
									sch.name = @TargetSchema
									AND tab.name = @TargetTable
									AND col.is_identity = 0
							)
 ;

INSERT INTO @tmp
(
    ColumnKey,
    TargetTable
)
VALUES
(@WatermarkColumn, @TargetTable);
 WITH PrimaryKeyList AS (
						SELECT 
							ColumnKey = RTRIM(LTRIM(Value)),
							RowNumber = ROW_NUMBER () OVER (ORDER BY value ASC)

						FROM
							@tmp
								CROSS APPLY 
							STRING_SPLIT( ColumnKey, ',')
						WHERE 
							TargetTable = @TargetTable
						)
 
SELECT
 @WhereClause =   STRING_AGG(CASE 
                                            WHEN E.ColumnKey IS NOT NULL THEN CONCAT( Beg.ColumnKey,' IN (SELECT ', Beg.ColumnKey, ' FROM ', @FullStagingTableName, ') AND')
                                            ELSE CONCAT( Beg.ColumnKey,' IN (SELECT ', Beg.ColumnKey, ' FROM ', @FullStagingTableName, ')' )
                                        END, ' ')
    
FROM 
    PrimaryKeyList Beg
        LEFT JOIN
    PrimaryKeyList E
        ON Beg.Rownumber = E.Rownumber - 1 
        ;
print @WhereClause;
SELECT
    @DeleteStatementSQL = CONCAT('DELETE FROM ', @FullTargetTableName, ' WHERE ', @WhereClause) ;
 
SELECT 
    @InsertStatementSQL = CONCAT('INSERT INTO ', @FullTargetTableName, ' (', @TargetTableColumnList, ') ', ' SELECT ', @TargetTableColumnList, ' FROM ', @FullStagingTableName)
print @DeleteStatementSQL;
print @InsertStatementSQL;



---------Logic to convert the LAST succesfull execution date from String to Datetime format 
DECLARE @inputString VARCHAR(20) = '2019-05-17-11-25-51';

DECLARE @formattedString VARCHAR(20) = 
    LEFT(@inputString, 10) + ' ' +REPLACE( SUBSTRING(@inputString, 12, 2) + ':' + SUBSTRING(@inputString, 15, 2) + ':' + SUBSTRING(@inputString, 18, 2), '-', ' ');
PRINT @formattedString;

DECLARE @dateConvertedString DATETIME =  CONVERT(DATETIME, @formattedString, 120) ;
PRINT @dateConvertedString;
select * from  dest_dbo.dbo_project_table where Creationtime >= @dateConvertedString


-------Modifying the logic in ADF ,as ADF expects all the  variables to be declared
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = '@{pipeline().parameters.targetSchema}' AND TABLE_NAME =  '@{pipeline().parameters.targetTable}')
    BEGIN 
        DECLARE @inputString VARCHAR(20); 
		DECLARE @formattedString VARCHAR(20);
		DECLARE @dateConvertedString DATETIME;
		SET @inputString = @{pipeline().parameters.lastSuccessExecDate}
        IF @inputString != '-1'
            BEGIN
            SET @formattedString  = 
            LEFT(@inputString, 10) + ' ' +REPLACE( SUBSTRING (@inputString, 12, 2) + ':' + SUBSTRING(@inputString, 15, 2) + ':' + SUBSTRING(@inputString, 18, 2), '-', ' ')
            SET @dateConvertedString  =  CONVERT(DATETIME, @formattedString,120) 

            Select * from [@{pipeline().parameters.schema}].[@{pipeline().parameters.tablename}] where @{pipeline().parameters.watermarkColumnName} >= DATEADD(DAY,@{pipeline().parameters.watermarkLookbackDays},@dateConvertedString)
            END
        ELSE 
            BEGIN 
                Select * from [@{pipeline().parameters.schema}].[@{pipeline().parameters.tablename}]
            END
    END 
ELSE 
    Select * from [@{pipeline().parameters.schema}].[@{pipeline().parameters.tablename}]
	
-------Sample data link--------------------------------------
https://github.com/microsoft/sql-server-samples/blob/master/samples/databases/northwind-pubs/instnwnd.sql
-----------------------JDBC configuration
delete from  [controlTable].[TestMetadataControlTable] where TableName = 'project_table';
INSERT INTO [controlTable].[TestMetadataControlTable] (sourceName,TableName,Config) 
values ('source2','orders', N'{
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
       '
); 
INSERT INTO [controlTable].[TestMetadataControlTable] (sourceName,TableName,Config) 
values ('source2','order_details', N'{
        "SourceObjectSettings": {
            "schema": "dbo",
            "table": "Order Details",
            "url": "vvtestadf-sname-sn.database.windows.net",
            "username": "adfadmin",
            "password":"Password123",
            "database" : "vvtestadf_dbname_sqldb"
        },
        "SinkObjectSettings": {
            "storageAccount" : "vvtestadfdevsg",
            "fileName": "dbo_order_details",
            "directory": "source2",
            "fileSystem": "raw",
            "partitionColName": "exec_date",
            "targetTable": "dbo_order_details",
            "targetSchema": "dest_dbo"

        },
        "CopySourceSettings": {
            "partitionOption": "None",
            "sqlReaderQuery": null,
            "partitionLowerBound": null,
            "partitionUpperBound": null,
            "partitionColumnName": null,
            "partitionNames": null
        },
        "DataLoadingBehaviorSettings": {
            "dataLoadingBehavior": "full",
            "watermarkColumnName": null,
            "watermarkLookbackDays": null
              }
        }
       '
) ;
----Update the configuration 
UPDATE [controlTable].[TestMetadataControlTable]
                SET [Config]=JSON_MODIFY([Config],'$.SinkObjectSettings.targetTable', 'source2_dbo_project_table')
                where sourceName = 'source1' and TableName = 'project_table'
				
------Query to get the status

----------------------------------------File based configuration

            /****** Object:  Table [fileBasedingestion].[MainControlTable_vp9] ******/
            CREATE TABLE [fileBasedingestion].[MainControlTable_vp9](
                [Id] [int] IDENTITY(1,1) NOT NULL PRIMARY KEY,
                [SourceObjectSettings] [nvarchar](max) NULL,
                [SourceConnectionSettingsName] [varchar](max) NULL,
                [CopySourceSettings] [nvarchar](max) NULL,
                [SinkObjectSettings] [nvarchar](max) NULL,
                [SinkConnectionSettingsName] [varchar](max) NULL,
                [CopySinkSettings] [nvarchar](max) NULL,
                [CopyActivitySettings] [nvarchar](max) NULL,
                [TopLevelPipelineName] [varchar](max) NULL,
                [TriggerName] [nvarchar](max) NULL,
                [DataLoadingBehaviorSettings] [nvarchar](max) NULL,
                [TaskId] [int] NULL,
                [CopyEnabled] [bit] NULL
        ) 
            DECLARE @MainControlMetadata NVARCHAR(max)  = N'[
    {
        "SourceObjectSettings": {
            "fileName": null,
            "folderPath": "sampledata",
            "fileSystem": "raw"
        },
        "SinkObjectSettings": {
            "fileName": null,
            "folderPath": null,
            "fileSystem": "base"
        },
        "CopySourceSettings": {
            "recursive": true,
            "wildcardFileName": "*"
        },
        "CopySinkSettings": {
            "copyBehavior": "PreserveHierarchy"
        },
        "CopyActivitySettings": {
            "translator": null,
            "enableSkipIncompatibleRow": false,
            "logSettings": {
                "enableCopyActivityLog": true,
                "copyActivityLogSettings": {
                    "logLevel": "Info",
                    "enableReliableLogging": false
                },
                "logLocationSettings": {
                    "linkedServiceName": {
                        "referenceName": "ls_adlsconnection",
                        "type": "LinkedServiceReference"
                    },
                    "path": "dataingestionlogs"
                }
            },
            "skipErrorFile": {
                "fileMissing": true,
                "dataInconsistency": true
            }
        },
        "TopLevelPipelineName": "MetadataDrivenCopyTask_vp9_TopLevel",
        "TriggerName": [
            "Sandbox",
            "Manual"
        ],
        "DataLoadingBehaviorSettings": {
            "dataLoadingBehavior": "FullLoad"
        },
        "TaskId": 0,
        "CopyEnabled": 1
    }
]';
            INSERT INTO [fileBasedingestion].[MainControlTable_vp9] (
                [SourceObjectSettings],
                [SourceConnectionSettingsName],
                [CopySourceSettings],
                [SinkObjectSettings],
                [SinkConnectionSettingsName],
                [CopySinkSettings],
                [CopyActivitySettings],
                [TopLevelPipelineName],
                [TriggerName],
                [DataLoadingBehaviorSettings],
                [TaskId],
                [CopyEnabled])
            SELECT * FROM OPENJSON(@MainControlMetadata)
                WITH ([SourceObjectSettings] [nvarchar](max) AS JSON,
                [SourceConnectionSettingsName] [varchar](max),
                [CopySourceSettings] [nvarchar](max) AS JSON,
                [SinkObjectSettings] [nvarchar](max) AS JSON,
                [SinkConnectionSettingsName] [varchar](max),
                [CopySinkSettings] [nvarchar](max) AS JSON,
                [CopyActivitySettings] [nvarchar](max) AS JSON,
                [TopLevelPipelineName] [varchar](max),
                [TriggerName] [nvarchar](max) AS JSON,
                [DataLoadingBehaviorSettings] [nvarchar](max) AS JSON,
                [TaskId] [int],
                [CopyEnabled] [bit])	
				
				
				