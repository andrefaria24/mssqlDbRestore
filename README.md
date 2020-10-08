Microsoft SQL Database Restore Script
-------------------------------------------------

Description
-------------------------------------------------

A PowerShell script that will restore a MSSQL backup to a given server.

The script will use the default location for SQL data and log file storage.

Execution
-------------------------------------------------
restoreMssqlDb.ps1 -server [TARGET MSSQL INSTANCE] -dbname [NAME OF DATABASE TO BE RESTORED] -backup [FULL PATH OF BACKUP FILE TO BE RESTORED]