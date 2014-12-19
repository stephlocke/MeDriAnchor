CREATE PROCEDURE [MeDriAnchor].[sspAddAttribute]
(
@DBTableSchema SYSNAME,
@DBTableName SYSNAME,
@DBTableColumnName SYSNAME,
@IsAttribute BIT = 1,
@IsHistorised BIT = 1,
@AnchorMnemonicRef NVARCHAR(3),
@AttributeMnemonic NVARCHAR(7),
@KnotMnemonic NVARCHAR(7) = '',
@CreateNCIndexInDWH BIT = 0
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

BEGIN TRAN;

BEGIN TRY

	-- we have a table id and the column exists, so add the attribute
	UPDATE [MeDriAnchor].[DBTableColumn] SET 
		[IsAttribute] = @IsAttribute,
		[IsHistorised] = @IsHistorised,
		[AttributeMnemonic] = @AttributeMnemonic,
		[AnchorMnemonicRef] = @AnchorMnemonicRef,
		[KnotMnemonic] = @KnotMnemonic,
		[CreateNCIndexInDWH] = @CreateNCIndexInDWH
	WHERE [DBTableID] = @DBTableID
		AND [DBTableColumnName] = @DBTableColumnName
		AND
		(
		[IsAttribute] <> @IsAttribute
		OR [IsHistorised] <> @IsHistorised
		OR [AttributeMnemonic] <> @AttributeMnemonic
		OR [AnchorMnemonicRef] <> @AnchorMnemonicRef
		OR [KnotMnemonic] <>@KnotMnemonic
		OR [CreateNCIndexInDWH] <> @CreateNCIndexInDWH
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