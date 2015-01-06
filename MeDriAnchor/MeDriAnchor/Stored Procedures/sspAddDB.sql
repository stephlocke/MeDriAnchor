CREATE PROCEDURE [MeDriAnchor].[sspAddDB]
(
@DBServerID BIGINT,
@DBName SYSNAME, 
@DBUserName VARBINARY(256) = NULL, 
@DBUserPassword VARBINARY(256) = NULL,
@DBIsLocal BIT,
@DBIsSource BIT,
@DBIsDestination BIT,
@Environment_ID SMALLINT,
@StageData BIT = 0,
@UseSchemaPromotion BIT = 0,
@DBID BIGINT OUTPUT
)
AS
SET NOCOUNT ON;

DECLARE @DBServerTypeID SMALLINT;

-- validate the server id is valid
IF NOT EXISTS (SELECT * FROM [MeDriAnchor].[DBServer] WHERE [DBServerID] = @DBServerID)
	THROW 51000, 'Invalid @DBServerID.', 1;

-- validate the environment id is valid
IF @Environment_ID IS NOT NULL AND NOT EXISTS (SELECT * FROM [MeDriAnchor].[Environment] WHERE [Environment_ID] = @Environment_ID)
	THROW 51000, 'Invalid @Environment_ID.', 1;

BEGIN TRAN;

BEGIN TRY

	-- here so have valid values to work with, so add the db if it doesn't already exist
	IF NOT EXISTS(SELECT * FROM [MeDriAnchor].[DB] WHERE [DBServerID] = @DBServerID AND [DBName] = @DBName)
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
			[Environment_ID],
			[StageData],
			[UseSchemaPromotion]
			)
		SELECT
			@DBServerID,
			@DBName,
			@DBUserName, -- NULL for windows auth or username for connection
			@DBUserPassword, -- NULL for windows auth or password for connection
			@DBIsLocal, -- 0 for on the same server instance as the Control DB (MeDriAnchor) or 1 for remote
			@DBIsSource, -- 1 if a source
			@DBIsDestination, -- 1 if a destination (DWH)
			@Environment_ID,
			@StageData,
			@UseSchemaPromotion;

		SET @DBID = SCOPE_IDENTITY();

	END
	ELSE
	BEGIN
		SET @DBID = (SELECT [DBID] FROM [MeDriAnchor].[DB] WHERE [DBServerID] = @DBServerID AND [DBName] = @DBName);
	END

	COMMIT TRANSACTION;

	RETURN 0;

END TRY

BEGIN CATCH

	DECLARE @ErrorMessage NVARCHAR(4000);
	DECLARE @ErrorSeverity INT;
	DECLARE @ErrorState INT;

	RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);

	ROLLBACK TRANSACTION;

	RETURN -1;

END CATCH;