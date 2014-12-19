CREATE PROCEDURE [MeDriAnchor].[sspAddAnchor]
(
@DBTableSchema SYSNAME,
@DBTableName SYSNAME,
@DBTableColumnName SYSNAME,
@DBTableColumnAlias SYSNAME = '',
@IsAnchor BIT = 1,
@AnchorMnemonic NVARCHAR(3),
@PKColumn BIT = 1,
@PKColOrdinal BIT = 1,
@DBTableColumnNameDateComp SYSNAME = ''
)
AS
SET NOCOUNT ON;

DECLARE @DBTableID BIGINT = (SELECT [DBTableID] FROM [MeDriAnchor].[DBTable] WHERE [DBTableSchema] = @DBTableSchema
	AND [DBTableName] = @DBTableName); -- table or view that contains the anchor

-- validate the table or view is one we know about
IF (@DBTableID IS NULL)
	THROW 51000, 'No table matches @DBTableSchema and @DBTableName.', 1;

IF NOT EXISTS (SELECT * FROM [MeDriAnchor].[DBTableColumn] WHERE [DBTableID] = @DBTableID
	AND [DBTableColumnName] = @DBTableColumnName)
	THROW 51000, '@DBTableColumnName does not exists in this table.', 1;

IF (@DBTableColumnNameDateComp <> '')
BEGIN
	IF NOT EXISTS (SELECT * FROM [MeDriAnchor].[DBTableColumn] WHERE [DBTableID] = @DBTableID
		AND [DBTableColumnName] = @DBTableColumnNameDateComp)
		THROW 51000, '@DBTableColumnNameDateComp does not exists in this table.', 1;
END

BEGIN TRAN;

BEGIN TRY

	-- we have a table id and the column exists (plus the date comparison column if passed), so add the anchor
	UPDATE [MeDriAnchor].[DBTableColumn] SET 
		[IsAnchor] = @IsAnchor,
		[AnchorMnemonic] = @AnchorMnemonic,
		[PKColumn] = @PKColumn,
		[PKColOrdinal] = @PKColOrdinal,
		[DBTableColumnAlias] = @DBTableColumnAlias
	WHERE [DBTableID] = @DBTableID
		AND [DBTableColumnName] = @DBTableColumnName
		AND 
		(
		[IsAnchor] <> @IsAnchor
		OR [AnchorMnemonic] <> @AnchorMnemonic
		OR [PKColumn] <> @PKColumn
		OR [PKColOrdinal] <> @PKColOrdinal
		OR ISNULL([DBTableColumnAlias], '') <> @DBTableColumnAlias
		);

	-- if we have a date/time restriction column then also specify that
	IF (@DBTableColumnNameDateComp <> '')
	BEGIN
		UPDATE [MeDriAnchor].[DBTableColumn] SET 
			[IsDatetimeComparison] = 1
		WHERE [DBTableID] = @DBTableID
			AND [DBTableColumnName] = @DBTableColumnNameDateComp
			AND [IsDatetimeComparison] = 0;
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