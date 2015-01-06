-- Version 1.10
PRINT 'START: Loading MeDriAnchor default servers and database data...';

SET NOCOUNT ON;

DECLARE @DBServerTypeID_SQLSERVER SMALLINT = (SELECT [DBServerTypeID] FROM [MeDriAnchor].[DBServerType] WHERE [DBServerType] = 'SQLSERVER');
DECLARE @DBServerID BIGINT;
DECLARE @DBServerID_DWH BIGINT;

-- Control server (the server the MeDriAnchor database will reside on)
IF NOT EXISTS(SELECT * FROM [MeDriAnchor].[DBServer] WHERE [ServerName] = 'TECHNOBITCH')
BEGIN
	INSERT INTO [MeDriAnchor].[DBServer]
		(
		[DBServerTypeID],
		[ServerName]
		)
	VALUES
		(
		@DBServerTypeID_SQLSERVER,
		'TECHNOBITCH'
		);
	SET @DBServerID = SCOPE_IDENTITY();
END
ELSE
BEGIN
	SET @DBServerID = (SELECT [DBServerID] FROM [MeDriAnchor].[DBServer] WHERE [ServerName] = 'TECHNOBITCH');
END

-- DWH (the server the DWH databases will sit on - one here but you could have three, so repeat for each needed)
IF NOT EXISTS(SELECT * FROM [MeDriAnchor].[DBServer] WHERE [ServerName] = 'TECHNOBITCH')
BEGIN
	INSERT INTO [MeDriAnchor].[DBServer]
		(
		[DBServerTypeID],
		[ServerName]
		)
	VALUES
		(
		@DBServerTypeID_SQLSERVER,
		'TECHNOBITCH'
		);
	SET @DBServerID_DWH = SCOPE_IDENTITY();
END
ELSE
BEGIN
	SET @DBServerID_DWH = (SELECT [DBServerID] FROM [MeDriAnchor].[DBServer] WHERE [ServerName] = 'TECHNOBITCH');
END

-- MeDriAnchor database (add and attach the control database onto the control server)
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
		NULL, -- NULL = integrated (windows auth)
		NULL,
		1, -- local to the control db
		0, -- flag unimportant to the control db
		0, -- flag unimportant to the control db
		NULL; -- environment unimportant to the control db

END

/*
ONE DWH DB PER ENVIRONMENT (STANDARD SETUP)
*/

-- DWH (Development)
IF NOT EXISTS(SELECT * FROM [MeDriAnchor].[DB] WHERE [DBServerID] = @DBServerID_DWH AND [DBName] = 'DWH_DEV')
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
		@DBServerID_DWH, -- server id, can be same for each environment DWH or different
		'DWH_DEV',
		CONVERT(VARBINARY(256), N'MeDriAnchorUser'),
		CONVERT(VARBINARY(256), N'hwud76s7djdd7D7346!£$'),
		1, -- is local to control
		0, -- not a source
		1, -- is a destination
		(SELECT [Environment_ID] FROM [MeDriAnchor].[Environment] WHERE [EnvironmentName] = 'DEVELOPMENT');

END

-- DWH (UAT)
IF NOT EXISTS(SELECT * FROM [MeDriAnchor].[DB] WHERE [DBServerID] = @DBServerID_DWH AND [DBName] = 'DWH_UAT')
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
		'DWH_UAT',
		CONVERT(VARBINARY(256), N'MeDriAnchorUser'),
		CONVERT(VARBINARY(256), N'hwud76s7djdd7D7346!£$'),
		1, -- is local to control
		0, -- not a source
		1, -- is a destination
		(SELECT [Environment_ID] FROM [MeDriAnchor].[Environment] WHERE [EnvironmentName] = 'UAT');

END

-- DWH (Production)
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
		CONVERT(VARBINARY(256), N'MeDriAnchorUser'),
		CONVERT(VARBINARY(256), N'hwud76s7djdd7D7346!£$'),
		1, -- is local to control
		0, -- not a source
		1, -- is a destination
		(SELECT [Environment_ID] FROM [MeDriAnchor].[Environment] WHERE [EnvironmentName] = 'PRODUCTION');

END

/*
ONE DWH DB FOR ALL ENVIRONMENTS (HAPPY WITH THIS IF ALL ENVIRONMENTS ARE GOING INTO ONE DWH)
*/

/*

-- DWH (All)
IF NOT EXISTS(SELECT * FROM [MeDriAnchor].[DB] WHERE [DBServerID] = @DBServerID_DWH AND [DBName] = 'DWH_DEV')
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
		CONVERT(VARBINARY(256), N'MeDriAnchorUser'),
		CONVERT(VARBINARY(256), N'hwud76s7djdd7D7346!£$'),
		1, -- is local to control
		0, -- not a source
		1, -- is a destination
		NULL;

END

*/

-- Add a default batch if none exists (a default batch will give a starting date for date comparisions, so adjust
--  to the lowest data required)
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
		'2000-01-01 00:00:00.000',
		1,
		0
		);
END
GO

-- Create the linked servers (tell MeDriAnchor to create any linked servers needed)
EXEC [MeDriAnchor].[amsp_ETLSQL_CreateLinkedServers];
GO

PRINT 'END: Loading MeDriAnchor default servers and database data...';
GO