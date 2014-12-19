CREATE PROCEDURE [MeDriAnchor].[sspAddDBServer]
(
@DBServerType NVARCHAR(100), -- Constraint SQLSERVER, SQLAZURE, MYSQL, PostgreSQL
@DBServerName SYSNAME = NULL, -- one of the below 2 must contain a value
@DBServerIP NVARCHAR(30) = NULL,
@DBServerID BIGINT OUTPUT
)
AS
SET NOCOUNT ON;

DECLARE @DBServerTypeID SMALLINT;

-- validate the server type is one we know about
IF (@DBServerType NOT IN('SQLSERVER', 'SQLAZURE', 'MYSQL', 'PostgreSQL'))
	THROW 51000, '@DBServerType must be one of: SQLSERVER, SQLAZURE, MYSQL, or PostgreSQL.', 1;

-- validate that either a server name OR ip has been passed (two empty strings are just as bad)
IF (ISNULL(@DBServerName, '') = '' AND ISNULL(@DBServerIP, '') = '')
	THROW 51000, 'Either @DBServerName or @DBServerIP must be a valid value.', 1;

BEGIN TRAN;

BEGIN TRY

	-- here so have valid values to work with, so add the server if it doesn't already exist
	SET @DBServerTypeID = (SELECT [DBServerTypeID] FROM [MeDriAnchor].[DBServerType] 
	WHERE [DBServerType] = @DBServerType);

	IF NOT EXISTS(SELECT * FROM [MeDriAnchor].[DBServer] WHERE [ServerName] = @DBServerName)
	BEGIN
		INSERT INTO [MeDriAnchor].[DBServer]
			(
			[DBServerTypeID],
			[ServerName],
			[ServerIP]
			)
		VALUES
			(
			@DBServerTypeID,
			@DBServerName,
			@DBServerIP
			);

		SET @DBServerID = SCOPE_IDENTITY();

	END
	ELSE
	BEGIN
		SET @DBServerID = (SELECT [DBServerID] FROM [MeDriAnchor].[DBServer] 
			WHERE [ServerName] = @DBServerName OR [ServerIP] = @DBServerIP);
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