CREATE PROCEDURE [MeDriAnchor].[sspAddDBTableColumnTest]
(
@DBTableSchema SYSNAME,
@DBTableName SYSNAME,
@DBTableColumnName SYSNAME,
@TestType NVARCHAR(50),
@TestValue1 SQL_VARIANT = NULL,
@TestValue2 SQL_VARIANT = NULL,
@LkpDBTableSchema SYSNAME = NULL,
@LkpDBTableName SYSNAME = NULL,
@LkpDBTableColumnName SYSNAME = NULL
)
AS
SET NOCOUNT ON;

DECLARE @DBTableID BIGINT = (SELECT [DBTableID] FROM [MeDriAnchor].[DBTable] WHERE [DBTableSchema] = @DBTableSchema
	AND [DBTableName] = @DBTableName); -- table or view that contains the column to test

DECLARE @DBTableColumnID BIGINT = (SELECT [DBTableColumnID] FROM [MeDriAnchor].[DBTableColumn] 
	WHERE ([DBTableID] = @DBTableID AND [DBTableColumnName] = @DBTableColumnName)); -- column to test

DECLARE @DBTableColumnTestID INT = (SELECT [DBTableColumnTestID] FROM [MeDriAnchor].[DBTableColumnTest] 
	WHERE [TestType] = @TestType); -- the test type

DECLARE @LkpDBTableColumnID BIGINT = (SELECT [DBTableColumnID] FROM [MeDriAnchor].[DBTableColumn] tc
	INNER JOIN [MeDriAnchor].[DBTable] t ON t.[DBTableID] = tc.[DBTableID]
	WHERE t.[DBTableSchema] = @LkpDBTableSchema AND t.[DBTableName] = @LkpDBTableName
	AND tc.[DBTableColumnName] = @LkpDBTableColumnName);

-- validate the table or view is one we know about
IF (@DBTableID IS NULL)
	THROW 51000, 'No table matches the @DBTableSchema and @DBTableName passed in.', 1;

IF (@DBTableColumnID IS NULL)
	THROW 51000, '@DBTableColumnName does not exists in this table.', 1;

IF (@DBTableColumnTestID IS NULL)
	THROW 51000, 'The test type (@TestType) passed in does not match a test in the [MeDriAnchor].[DBTableColumnTest] table.', 1;

IF (@LkpDBTableSchema IS NOT NULL AND @LkpDBTableColumnID IS NULL)
	THROW 51000, 'The lookup test column cannot be found.', 1;

BEGIN TRAN;

BEGIN TRY

	-- we have a table id and the column exists so attach the test
	UPDATE [MeDriAnchor].[DBTableColumn] SET 
		[TestValue1] = @TestValue1,
		[TestValue2] = @TestValue2,
		[TestLkpDBTableColumnID] = @LkpDBTableColumnID
	WHERE [DBTableColumnID] = @DBTableColumnID;

	-- associate the column with the test
	INSERT INTO [MeDriAnchor].[DBTableColumnTests]
		(
		[DBTableColumnID],
		[DBTableColumnTestID],
		[Active]
		)
	VALUES
		(
		@DBTableColumnID,
		@DBTableColumnTestID,
		1
		);

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
