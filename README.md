# azureadf-DI-framework (In progress)
This is a pet project done as a part of my azure adf learning.  In this project I have tried to build a Data Ingestion framework for JDBC sources. It is tested on  Azure SQL DB.
## Requirement
1. Onboarding of any new JDBC source with no code changes or minimal modifications to the existing framework.
2. Restart only the failed tables in the subsequent run
3. Track the run status of each table associated with a source.
4. Adding a new type of source doesn't change the structure of the existing configuration table.

