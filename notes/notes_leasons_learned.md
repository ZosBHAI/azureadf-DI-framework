# Lessons learned as part of Framework development
- To copy or move data from on-premise environment to cloud, recommended approach is  to use Self Hosted Integration Runtime. Inital thought was to use Dataflow for data ingestion, Dataflow will not 
     work on self hosted runtime,so moved to COPY activity for data ingestion.
- Global Parameters are not same as Airflow variable.Intial thoughts was to store the  execution date and previous successful execution date in Global Parameters. Plan was to use these global parameter to generate the execution date.  Unfortunately, cannot find any  activity  to modify Global parameters. On my investigation, I discovered that these parameters can be modified using Powershell. So, the entire logic  for execution date generation is shifted to Stored procedure.
- Stored Procedure (SP) activity does not support SP with OUTPUT parameter; Should use LOOOKUP or SCRIPT activity.
-  When a Stored Procedure is called by a Lookup Activity, it expects a result set. Therefore, the last statement in the Stored Procedure should be a SELECT of the OUTPUT parameter.  
        - [Discussion](https://learn.microsoft.com/en-us/answers/questions/104471/store-procedure-with-output-param-in-lookup)
        - [Implementation & Demo](https://www.youtube.com/watch?v=vU2ZOIPO_So)
- Better to use QUery option in COPY activity , in this approach we have the control over the list of columns  to be extracted from source.
- The COPY activity cannot delete the folder in the SINK part, which is needed for idempotency. The solutions are:
    - Mention the filename in the FILENAME field, so the same file will be overwritten every time.
    - Or, add a Delete activity before the COPY activity.
    [Reference](https://learn.microsoft.com/en-us/answers/questions/962366/clear-folder-before-writing-in-parquet-using-copy)
- Foreach activity which has EXECUTE PIPELINE  in debug mode does not run parallelly.
- You can add additional Column using `COPY ACTIVITY`.[Reference](https://www.youtube.com/watch?v=Q39H3lgtirY)
- There are certain intricacies related to restartability for `COPY ACTIVITY`. Like there is no automatic way to restart  the  failed ingestions from previous run, it has to handled using custom logic. Seems like retry  works only for `file based source` and the format is `BINARY`.[Reference](https://learn.microsoft.com/en-us/azure/data-factory/copy-activity-overview?source=recommendations#resume-from-last-failed-run)

# Notes
 ## `Intergration Runtime`
Azure services Data Factory, Purview, and Synapse Workspace all require the installation of a Self Hosted Integration Runtime  in your network.
  Integration Runtime is where the actual compute happens and is responsible for  the data manipulation & movement. 
 #### Why do i need an Integration Runtime
  [Reference](https://medium.com/version-1/what-are-integration-runtimes-da7d24db1174)
  >  When deploying services in the cloud that require data from an existing on-premise network, you need to either move that  data to the cloud or make it available to the new cloud service from its current location.
  Any network will have a firewall to restrict connectivity from external services, and those that are allowed access  to the network must be trusted by the network’s identity service if they are to be authorised to move data.  In practice, it gives administrators far greater control and allows for stronger governance if the data movement  is happening within the network, authenticating using an identity controlled within the organisation.  This is what the integration runtime provides: compute power, running within your network, that is granted appropriate access to  data sources and has a trusting relationship with the cloud service that controls it.
  
   #### How many do i need?
  ##### Usecase: 
Moving a Data from ON-PREMISE to CLOUD, you would need 2 Runtime.  
     1. In the ONpremise  that support the data movement , with some data validation.
     2. In the Private network of SINK.
   >  Even though the sink is in the cloud it will be in a discrete network behind a firewall so still requires an Integration Runtime for Data Factory to access it.
#### Types of IR     
 1) Azure Runtime
 2) Self Hosted Runtime:
      - Used when we need to migrate something from ON-PREMISE
      - Max 4 machines are allowed in a Self Hosted Runtime
      - We can share the Self Hosted Runtime with  Multiple ADF
      - Dataflow will not work in Self Hosted Runtime; Work around is to bring it in the DATA from ON-PREMISE to CLOUD Storage(BLOB)
        and then perform the transformation in Dataflow

 3) SSIS Runtime
    - Steps in creating Integration Runtime:
      1) Go to Intergartion Runtime tab in AZure ADF portal, choose SELF-HOSTED RUNtime
      2) Download the installer and install it in the ON PREMISE environment
      3) Paste the keys generated from the  Azure ADF portal
      4) Create the LINKED SERVICE pointing to ON premise
            - Choose the SELF HOsted RUntinme
            - Select SQL Server in the Service not Azure SQL
      5) In the Pipeline to COPY the data
 
## `USER PROPERTIES`
  1) There can be only 5  User properties in a pipeline
  Ref: https://www.youtube.com/watch?v=0QExfRwhhDo
## `Web Activity`
1) It enables to call the  child pipeline at runtime.  Call `Pipeline activity` does not support this,as the calling pipeline name is constant.
  2) Add CONTRIBUTOR role to call the Web Activity
  Ref: https://www.youtube.com/watch?v=5OESBjLxwHE&t=316s
## `Trigger`
1) You need to disable the trigger, before you are going to update the trigger  using Web Activity.
2) Trigger defintion can be modified using Azure CLI or Web Activity or Powershell. To use powershell or python you need Azure Batch Service.
3) For creating multiple trigger  for same pipeline, try creating a seperate Metadata. 
Ref: https://global.hitachi-solutions.com/blog/azure-synapse-triggers/

## `Global Parameter`
  1)  Used to switch environment parameters as a part of deployment
  2)  Not Like Airflow variable ,does not provide API to modify Global Variable  dynamically.
  3) These variables are shared by all the pipelines in the ADF.
## `Dataset` 
 - `Inline Dataset` 
      1) This will not be present under DATASET. It is kind of a virtual.Copy activity does not support Inline Dataset.
      2) Usecase : Migrate N tables from JDBC to ADLS convert it to one format
      3) INLINE dataset cannot be used with COPY ACTIVITY
      4) It does not support PARAMETERISED LINKED Service.  
Ref:https://learn.microsoft.com/en-us/answers/questions/724428/parameters-of-linked-services-not-showed-in-data-f
## `Ways to execute SQL in ADF` 
SQL Script can be executed using following Activity
  Ref:https://azurede.com/2021/09/08/execute-custom-sql-code-in-azure-data-factory/
  1) Stored Procedure:
        This activity does not support a Stored Procedure that returns OUTPUT.
  2) Using Lookup Activity
     > The Lookup Activity is designed to perform a lookup on a database table based on an existing column (or variable), but it also provides the option
       to write a custom SQL statement on the Database (using a Linked Service, of course).
          The only catch here is that the Lookup activity expects an output result set from the SQL Query. To ensure that the custom SQL runs properly,
          we can add the following SQL code at the end of the custom SQL code.
          `Select 0 as id;`
          This will trick the Lookup Activity to execute the custom SQL code.

 - Limitation:
        Max 5k rows are returned or 2 MB of Data

  3) Pre Copy Script in COPY ACTIVITY (u can Paste the SQL)
  4) Script Activity
  - Support following type of query:
       - Query Radio Button
            - SELECT * from table.
       - Non-Query Radio Button
          - Examples of DDL – CREATE, DROP, ALTER . 
         - Examples of DML – INSERT, UPDATE, MERGE etc.
- Limitations: By default, the activity output is limited to 4MB, so if the result
             set returned by the query is larger than 4 MB then the result set will be truncated. To avoid this limitation, click on the advanced section in the
             settings and click on the enable logging check box to enable it.
## `Copy Activity`<in progress>
  1) Copy multiple sheets in an excel to blob storgae use BINARY COPY.
  2) For BINARY format,there is a delete option after the COPY.
  3) Copy a large table  Using ADF. 
     - Use Partitioning (similar to Spark Num partition)
     - Feature to select the column
     - Upper bound , Lower bound and Degree of parallelism
       Ref:https://www.youtube.com/watch?v=9bRqVnqZXh4
4) Restartability:
  - Of 10 files that needs to be moved, only 6 are successful then  how do we restart it?
      1) After the successful run of each file , it should be moved from the inbound location, so inbound loc has unprocessed file;
      Retrigger the pipeline
      2) We  have the option to Restart the failed Activity from Monitor tab
      3) For Copying Files, enable the Binary OPTION, you see the Multiple OPTION to skip under FAULT TOLERANCE (Skip incompatible rows)
          https://www.youtube.com/watch?v=8YDlgpCSmPg

## ADF Limitation:
1) No of activities in a Pipeline:
   Maximum activities per pipeline, which includes inner activities for containers - 80 and 120 (SoftLimit)
 2) Number of Pipeline per workspace:
    Total number of entities, such as pipelines, activities, triggers within a workspace - 5000
 3) Concurrency:
      Concurrent pipeline runs per data factory that's shared among all pipelines in workspace   - 10000
      External activities like stored procedure, Web, Web Hook, and others  - 3000  (per region; per subscription)
      Pipeline activities execute on integration runtime, including Lookup, GetMetadata, and Delete - 1000 (per region; per subscription)
 4) Timeout of Pipeline Activity:
      Maximum timeout for pipeline activity runs - 24 hours
5) Nesting of IF is not possible - Solution is to Split the Pipeline; Sample applies to Switch,Foreach
6) Maximum number of Parameters - 50
7) Cannot Choose a  Dynamic Pipeline name ;Also you cannot set the variable dynamically.
