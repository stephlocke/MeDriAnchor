# Gateways

# TLDR

Gateway databases provide a layer of abstraction between the source and the MeDriAnchor database. The concept here is simple: 
you create a local database to the MeDriAnchor database (on the same server), configure a linked server that can read from the 
source database, then expose whatever data you want to put in the Anchor model via views.

This gives the flexibility to present data in a cleaner and more consise way than sucking the whole source schema in. Also 
computed columns are far easier and quicker to add here, as these are just another computed view column as opposed to a 
separate scalar function.

# Intro

A Gateway database provides a clean way to present data to the MeDriAnchor database. Also the source here is unimportant to 
MeDriAnchor, it just sees the connection to the local database and doesn't care where the data originates from, which could be 
from a variety of database sources, flat files, etc.

This also means that MeDriAnchor doesn't need a login on the source server, as it only needs to communicate with the local 
database (the security for pulling data into the Gateway database is either held securely in the linked server security settings 
or in whatever ETL package fills this up).

# Prerequisites

The only prerequisite is that the `[dbo].[vIndexDetails]` and `[dbo].[vTableColumns]` views from the MeDriAnchor project must be 
created in the Gateway database.

# Initial Configuration

The process for creating and integrating a Gateway database into the MeDriAnchor process is straight forward:

* Create a Gateway database on the same server as the MeDriAnchor control database
* Create the MeDriAnchor schema in the database and give the user you will be calling it with full permissions to this schema (this is 
either the username/password user registered against the database or, if Windows authentication, the user that the ETL will be run as 
(as this will be the user that needs the permissions)
* Add the [dbo].[vIndexDetails] and [dbo].[vTableColumns] views to it from the MeDriAnchor project
* If needed, create the linked server(s) to the source databases
* Create the local tables and views needed (in the MeDriAnchor schema)
* Add the database to MeDriAnchor, flagging as local
* Finally do the markup needed

Once the database is created, MeDriAnchor just sees it as any other data source. You can then add more views\tables as you go along, 
refreshing the schema data held in MeDriAnchor as and when needed.

# Adding into MeDriAnchor

To add a Gateway database into MeDriAnchor:

```sql
/*
NOTE: THE [dbo].[vIndexDetails] and [dbo].[vTableColumns] VIEWS MUST BE ADDED TO THE SOURCE DATABASE PRIOR TO ANY ATTEMPT TO GET THE SOURCE SCHEMA. IF THE DATABSE IS SQL SERVER THEN JUST RUN THESE IN, OTHERWISE YOU WILL HAVE TO WRITE NEW VERSIONS THAT PRODUCE THE SAME OUTPUT FOR THE GIVEN DATABASE TYPE
*/

DECLARE @DBServerID BIGINT;
DECLARE @DBID BIGINT;
DECLARE @Environment_ID SMALLINT = (SELECT [Environment_ID] FROM [MeDriAnchor].[Environment] 
	WHERE [EnvironmentName] = 'DEVELOPMENT');

-- 1.1 Add the server if it doesn't exist
EXEC [MeDriAnchor].[sspAddDBServer]
	@DBServerType = 'SQLSERVER', -- Type
	@DBServerName = '{SERVERNAME}', -- Server name (Same as for MeDriAnchor, will return the Id of the existing server)
	@DBServerID = @DBServerID OUTPUT;

-- 1.2: Create the database if it doesn't exist
EXEC [MeDriAnchor].[sspAddDB]
	@DBServerID = @DBServerID, -- Server ID
	@DBName = '{GATEWAYDATABASENAME}', -- Database name
	@DBUserName = NULL, -- Database user name (NULL if using windows trusted authentication)
	@DBUserPassword = NULL, -- Database password (NULL if using windows trusted authentication and you will want to encrypt this column if using it)
	@DBIsLocal = 1, -- Flag to say whether this is local to the MreDriAnchor database (on the same server)
	@DBIsSource = 1, -- Flag to say whether this is a source database (one that you are pulling data from)
	@DBIsDestination = 0, -- Flag to say whether this is a destination database (an Anchor DWH)
	@Environment_ID = @Environment_ID, -- Environment (so for multiple DHW destinations, add one per environment, leave as NULL if only one)
	@DBID = @DBID OUTPUT;
	
-- 1.3: Hoover in the source schema
EXEC [MeDriAnchor].[sspGetSchemaFromSourceDB]
	@DBID = @DBID,
	@Environment_ID = @Environment_ID;
GO
```
You can then implement the markup as explained in the Changes documentation. If you add new items to the Gateway database and need to 
refresh the schema in MeDriAnchor, simply rerun the SQL to get the schema from the source database. This will only add new records and leave 
the existing ones unchanged (flagging any columns that were there before and are no longer there as inactive rather than deleting them).

```sql
EXEC [MeDriAnchor].[sspGetSchemaFromSourceDB]
	@DBID = @DBID,
	@Environment_ID = @Environment_ID;
GO
```
The Gateway database provides an ideal way to present the data to MeDriAnchor and avoids adding schema data for unneeded tables. It gives 
greater control over permissions and provides a far easier way of adding computed columns.

The Gateway database can also be remote if the performance of maintaining the data in it is better. In this case just flag the database as 
not being local when you add it and MeDriAnchor will create a linked server to it.

# Populating Local Tables Via Remote Queries

Prior to doing any ETL with local sources (such as Gateway databases), the MeDriAnchor routine checks for a stored procedure in the databases 
called [MeDriAnchor].[sspSynchLocalLookups] and if it finds one it runs it. This gives you the flexibility to code this however you want to 
achieve given objectives.

As an example, when first designing the CROW solution we had a MariaDB source. SQL Server could happily communicate with most of the tables 
via a linked server but not all, as it couldn't read the table schema data correctly (would get nullable wrong in certain cases). Plus 
queries via the linked server were very slow. To alleviate this, we created a Gateway database with local tables and coded the 
`[MeDriAnchor].[sspSynchLocalLookups]` to incrementally populate these via remotely executed queries.

```sql
INSERT INTO [MeDriAnchor].[..]
	(
	...
	)
EXEC (@SQL) AT [LINKEDSERVER] ;
```

This proved to be both faster and more reliable. Plus this way MeDriAnchor knows nothing about the source database, only the Gateway.

# Creating Lookup Tables For Knots When Not In The Correct Format

At present, MeDriAnchor only understand Knots when there is a numeric ID in the source table which relates to an ID in a lookup table that then has the textual description of the lookup. If you are lucky to have this then fantastic but this is not always the case, as sometimes lookups are text and relate to a table of items that simply hold a textual list of available values. Using the `[MeDriAnchor].[sspSynchLocalLookups]` and a local table we can achieve what is needed.

Here would be an example using a person gender lookup where it is stored in the source table as a text value ("Male", "Female", "M", "F", etc.).

In the Gateway database:

```sql
CREATE TABLE [MeDriAnchor].[LookupPersonGender](
	[Gender] [varchar](10) NULL,
	[PersonGenderID] [int] IDENTITY(1,1) NOT NULL,
 CONSTRAINT [PK_LookupPersonGender] PRIMARY KEY CLUSTERED 
(
	[PersonGenderID] ASC
));
```
In the `[MeDriAnchor].[sspSynchLocalLookups]` procedure:

```sql
INSERT INTO [MeDriAnchor].[LookupPersonGender]([Gender])
SELECT a.[Gender] FROM [MeDriAnchor].[vLookupPersonGender] a -- this view would contain the text values from the source table 
															 -- could be a derived query
WHERE NOT EXISTS(SELECT * FROM [MeDriAnchor].[LookupPersonGender] WHERE [Gender] = a.[Gender]);
```

So in the same way that you can populate local tables you can maintain local lookup tables that are perfectly valid for use as Knots 
in the MeDriAnchor markup.

# Multi-using Knots

Anchor does not like a Knot with the same mnemonic being used on multiple attributes. This is easy to get around in a Gateway database 
as you simply create a view over the Lookup table and then mark that up as a new Knot with a different mnemonic. So for example you could 
have a vPersonGender view and a vContactGender view which both reference the LookupPersonGender table but are seen as two entirely separate 
Knots in Anchor.