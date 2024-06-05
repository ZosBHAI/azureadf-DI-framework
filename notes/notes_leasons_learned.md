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
