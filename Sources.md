---
title: MeDriAnchor Data Sources
author: Steph Locke
output: html_document
---

# Introduction

The MeDirAnchor database can connect to any data source that SQL Server can use as a linked server. 
By default it has defined server types for SQL Server, SQL Azure (Windows SQL Database), MySQL, and PostgreSQL. 
The linked servers are created dynamically from a combination of data held at the server (which references Server Type) and the database level.

# Prerequisites

The only prerequisite for a data source is that SQL server must be able to use it as a linked server directly, without having a separate ODBC
 data source created. The MeDriAnchor database will create the linked servers as needed, so if this can't be done just via the system stored 
procedures then you will not be able to use that as a data source.

As with everything though, you can easily get around this by simply altering the `[MeDriAnchor].[amsp_ETLSQL_CreateLinkedServers]` procedure to 
no longer drop and recreate the linked servers (which it does to account for changes) and to leave alone any linked servers with names of 
existing servers. This way you can set up and verify that your linked server works as intended safe in the knowledge that the ETL routine will 
use it but never drop it.

## Setting up new types of connections

The MeDriAnchor database needs to know the connection string format for linked servers. By default it comes with connection strings for SQL Server, 
SQL Azure, MySQL (which also works for MariaDB), and PostgreSQL. If you need to add a new server type simply add it to this table.

Add server types to the `[MeDriAnchor].[ServerType]` table.

```{sql
INSERT INTO [MeDriAnchor].[DBServerType]
	(
	[DBServerType], 
	[DBServerConnectionString],
	[DBServerConnectionStringTrusted]
	)
	SELECT 'SQLSERVER', 'Server={SERVER};Database={DATABASE};User Id={USER};Password={PASSWORD};', 'Server={SERVER};Database={DATABASE};Trusted_Connection=True;'
	UNION ALL
	SELECT 'SQLAZURE', 'Server=tcp:{SERVER};Database={DATABASE};User ID={USER}@{SERVER_SHORT};Password={PASSWORD};', ''
	UNION ALL
	SELECT 'MYSQL', 'Server={SERVER};Database={DATABASE};Uid={USER};Pwd={PASSWORD};', ''
	UNION ALL
	SELECT 'PostgreSQL', 'User ID={USER};Password={PASSWORD};Host={SERVER};Port=5432;Database={DATABASE};Pooling=true;Min Pool Size=0;Max Pool Size=100;Connection Lifetime=0;', '';
```

Place holders are required for all configurable items in the connection and these are stored with the Server and Database record; User, 
Password, Server, etc. The curly bracketed parameters are swapped at create time for the appropriate values.

# Add a new data source

The first step in any source database integration is to add the source server and database(s). The server isn't environment aware but 
the databases are, so you can have a server that contains a test and a live database and happily deal with them separately.

```sql
/*
NOTE: THE [dbo].[vIndexDetails] and [dbo].[vTableColumns] VIEWS MUST BE ADDED TO THE SOURCE DATABASE PRIOR TO ANY ATTEMPT TO
GET THE SOURCE SCHEMA. IF THE DATABSE IS SQL SERVER THEN JUST RUN THESE IN, OTHERWISE YOU WILL HAVE TO WRITE NEW VERSIONS
THAT PRODUCE THE SAME OUTPUT FOR THE GIVEN DATABASE TYPE
*/

DECLARE @DBServerID BIGINT;
DECLARE @DBID BIGINT;
DECLARE @Environment_ID SMALLINT = (SELECT [Environment_ID] FROM [MeDriAnchor].[Environment] 
	WHERE [EnvironmentName] = 'DEVELOPMENT');

-- 1.1 Add the server if it doesn't exist
EXEC [MeDriAnchor].[sspAddDBServer]
	@DBServerType = 'SQLSERVER', -- Type
	@DBServerName = '{SERVERNAME}', -- Server name
	@DBServerID = @DBServerID OUTPUT;

-- 1.2: Create the database if it doesn't exist
EXEC [MeDriAnchor].[sspAddDB]
	@DBServerID = @DBServerID, -- Server ID
	@DBName = '{DATABASENAME}', -- Database name
	@DBUserName = NULL, -- Database user name (NULL if using windows trusted authentication)
	@DBUserPassword = NULL, -- Database password (NULL if using windows trusted authentication and you will want to encrypt this column if using it)
	@DBIsLocal = 1, -- Flag to say whether this is local to the MreDriAnchor database (on the same server)
	@DBIsSource = 1, -- Flag to say whether this is a source database (one that you are pulling data from)
	@DBIsDestination = 0, -- Flag to say whether this is a destination database (an Anchor DWH)
	@Environment_ID = @Environment_ID, -- Environment (so for multiple DHW destinations, add one per environment, leave as NULL if only one)
	@StageData = 1, -- Flag to say if you want to stage data (does a two-step import - once into a has table, another to push to the DWH)
	@DBID = @DBID OUTPUT;

-- 1.3: Run the linked server routine to do any necessary adjustments or creations
EXEC [MeDriAnchor].[amsp_ETLSQL_CreateLinkedServers];

-- 1.4: Hoover in the source schema
EXEC [MeDriAnchor].[sspGetSchemaFromSourceDB]
	@DBID = @DBID,
	@Environment_ID = @Environment_ID;
GO
```

Notes: When adding the database via the `[MeDriAnchor].[sspAddDB]` procedure, a user name and password can be supplied. If none are 
supplied then the linked server will be configured for pass-through windows authentication. The quickest way to get up and running 
is to copy this script and change according to your data source (ensuring you add the call to the file in the post-deployment script 
in the MeDriAnchor folder root).

# Editing existing sources

Any changes to an existing data source, such as server relocation or database renaming, will be automatically picked up on the next ETL run and 
the linked server and source synonyms reconfigured accordingly (the linked server will be dropped and recreated).

# Troubleshooting

The same troubleshooting for a MeDriAnchor linked server would be as for any SQL Server Linked Server. You need to create the linked server 
manually and fix any connection problems before transferring the correct definition back into the metadata.

# Roadmap

As more common server types are identified, these will be added into the default metadata.
