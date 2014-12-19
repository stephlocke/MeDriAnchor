-- Version 1.10
DECLARE @MeDriAnchorLocationType VARCHAR = 'SQLSERVER';
DECLARE @DWHAnchorLocationType VARCHAR = 'SQLAZURE';
DECLARE @MeDriAnchorLocation VARCHAR = 'dummysrvr\dummyinstance';
DECLARE @DWHLocation VARCHAR = 'dummysrvr\dummydwhinstance';
DECLARE @DWHAcct VARCHAR = 'dummyusr';
DECLARE @DWHPassword VARCHAR = 'dummypwd';
DECLARE @DWHDefaultSchema VARCHAR = 'DEVELOPMENT';


PRINT 'START: Loading MeDriAnchor default servers and database data...';

SET NOCOUNT ON;

DECLARE @DBServerTypeID_SQLSERVER SMALLINT = (SELECT [DBServerTypeID] FROM [MeDriAnchor].[DBServerType] WHERE [DBServerType] = @MeDriAnchorLocationType);
DECLARE @DBServerTypeID_SQLAZURE SMALLINT = (SELECT [DBServerTypeID] FROM [MeDriAnchor].[DBServerType] WHERE [DBServerType] = @DWHAnchorLocationType);
DECLARE @DBServerID BIGINT;
DECLARE @DBServerID_DWH BIGINT;
DECLARE @DBID BIGINT;
DECLARE @DBID_DWH BIGINT;
DECLARE @Environment_ID_DEV SMALLINT = (SELECT [Environment_ID] FROM [MeDriAnchor].[Environment] WHERE [EnvironmentName] = @DWHDefaultSchema);

-- Control server
IF NOT EXISTS(SELECT * FROM [MeDriAnchor].[DBServer] WHERE [ServerName] = @MeDriAnchorLocation)
BEGIN
	INSERT INTO [MeDriAnchor].[DBServer]
		(
		[DBServerTypeID],
		[ServerName]
		)
	VALUES
		(
		@DBServerTypeID_SQLSERVER,
		@MeDriAnchorLocation
		);
	SET @DBServerID = SCOPE_IDENTITY();
END
ELSE
BEGIN
	SET @DBServerID = (SELECT [DBServerID] FROM [MeDriAnchor].[DBServer] WHERE [ServerName] = @MeDriAnchorLocation);
END

-- Azure DWH
IF NOT EXISTS(SELECT * FROM [MeDriAnchor].[DBServer] WHERE [ServerName] = @DWHLocation)
BEGIN
	INSERT INTO [MeDriAnchor].[DBServer]
		(
		[DBServerTypeID],
		[ServerName]
		)
	VALUES
		(
		@DBServerTypeID_SQLAZURE,
		@DWHLocation
		);
	SET @DBServerID_DWH = SCOPE_IDENTITY();
END
ELSE
BEGIN
	SET @DBServerID_DWH = (SELECT [DBServerID] FROM [MeDriAnchor].[DBServer] WHERE [ServerName] = @DWHLocation);
END

-- MeDriAnchor
IF NOT EXISTS(SELECT * FROM [MeDriAnchor].[DB] WHERE [DBServerID] = @DBServerID AND [DBName] = 'MeDriAnchor')
BEGIN

	INSERT INTO [MeDriAnchor].[DB]
		(
		[DBServerID], 
		[DBName], 
		[DBUserName], 
		[DBUserPassword],
		[DBIsLocal],
		[DBIsSource],
		[DBIsDestination],
		[Environment_ID]
		)
	-- MeDriAnchor
	SELECT
		@DBServerID,
		'MeDriAnchor',
		NULL,
		NULL,
		1,
		0,
		0,
		NULL;

END

-- DWH
IF NOT EXISTS(SELECT * FROM [MeDriAnchor].[DB] WHERE [DBServerID] = @DBServerID_DWH AND [DBName] = 'DWH')
BEGIN

	INSERT INTO [MeDriAnchor].[DB]
		(
		[DBServerID], 
		[DBName], 
		[DBUserName], 
		[DBUserPassword],
		[DBIsLocal],
		[DBIsSource],
		[DBIsDestination],
		[Environment_ID]
		)
	SELECT
		@DBServerID_DWH,
		'DWH',
		CONVERT(VARBINARY(256), @DWHAcct ),
		CONVERT(VARBINARY(256), @DWHPassword ),
		0,
		0,
		1,
		@Environment_ID_DEV;

END

-- Create the linked servers
EXEC [MeDriAnchor].[amsp_ETLSQL_CreateLinkedServers];
GO

-- Add a default batch if none exists
DECLARE @BatchTypeID SMALLINT = (SELECT [BatchTypeID] FROM [MeDriAnchor].[BatchType] WHERE [BatchType] = 'ETL');

IF NOT EXISTS(SELECT * FROM [MeDriAnchor].[Batch])
BEGIN
	INSERT INTO [MeDriAnchor].[Batch]
		(
		[BatchTypeID],
		[BatchDescription],
		[BatchDate],
		[BatchSuccessful],
		[InProgress]
		)
	VALUES
		(
		@BatchTypeID,
		'Start batch',
		'2014-12-02 09:01:00.000',
		1,
		0
		);
END
GO

PRINT 'END: Loading MeDriAnchor default servers and database data...';
GO