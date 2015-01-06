
CREATE PROCEDURE [MeDriAnchor].[sspAddKnot]
(
@DBTableSchema SYSNAME,
@DBTableName SYSNAME,
@KnotMnemonic NVARCHAR(7),
@IsHistorised BIT = 0,
@IDRoleName NVARCHAR(30),
@ValRoleName NVARCHAR(30),
@IDKnotJoinColumn SYSNAME,
@ValKnotJoinColumn SYSNAME,
@ValTableColumnAlias SYSNAME,
@IDDBTableColumnName SYSNAME,
@ValDBTableColumnName SYSNAME,
@Environment_ID SMALLINT
)
AS
SET NOCOUNT ON;

DECLARE @DBTableID BIGINT = (SELECT [DBTableID] FROM [MeDriAnchor].[DBTable] WHERE [DBTableSchema] = @DBTableSchema
	AND [DBTableName] = @DBTableName); -- table or view that contains the anchor

-- validate the table or view is one we know about
IF (@DBTableID IS NULL)
	THROW 51000, 'No table matches @DBTableSchema and @DBTableName.', 1;

IF (NOT EXISTS (SELECT * FROM [MeDriAnchor].[DBTableColumn] WHERE [DBTableID] = @DBTableID
	AND [DBTableColumnName] = @IDDBTableColumnName) OR NOT EXISTS (SELECT * FROM [MeDriAnchor].[DBTableColumn] WHERE [DBTableID] = @DBTableID
	AND [DBTableColumnName] = @ValDBTableColumnName))
	THROW 51000, 'Two columns must exist for a table to be knotted: a numeric id column and a value column.', 1;

BEGIN TRAN;

BEGIN TRY

	UPDATE [MeDriAnchor].[DBTableColumn] SET 
		[IsKnot] = 1,
		[KnotMnemonic] = @KnotMnemonic,
		[IsHistorised] = @IsHistorised,
		[RoleName] = @IDRoleName,
		[PKColumn] = 1,
		[PKColOrdinal] = 1,
		[KnotJoinColumn] = @IDKnotJoinColumn,
		[GenerateID] = 0,
		[IdentityColumn] = 1,
		[Environment_ID] = @Environment_ID
	WHERE [DBTableID] = @DBTableID
		AND [DBTableColumnName] = @IDDBTableColumnName;

	UPDATE [MeDriAnchor].[DBTableColumn] SET 
		[IsKnot] = 1,
		[KnotMnemonic] = @KnotMnemonic,
		[IsHistorised] = @IsHistorised,
		[RoleName] = @ValRoleName,
		[PKColumn] = 0,
		[PKColOrdinal] = 0,
		[KnotJoinColumn] = @ValKnotJoinColumn,
		[DBTableColumnAlias] = @ValTableColumnAlias,
		[Environment_ID] = @Environment_ID
	WHERE [DBTableID] = @DBTableID
		AND [DBTableColumnName] = @ValDBTableColumnName;

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
