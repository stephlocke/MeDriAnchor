
/*
EXEC [dbo].[sspGenerateDWHIndexes] @metadataPrefix = 'Batch';
*/

CREATE PROC [dbo].[sspGenerateDWHIndexes]
(
@metadataPrefix NVARCHAR(100) = 'Batch',
@changedAtSuffix NVARCHAR(100) = 'ChangedAt'
)
AS

DECLARE @SQL NVARCHAR(MAX) = '';

BEGIN TRY

	BEGIN TRAN;

	-- meta data indexes
	SELECT	@SQL += 'IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N''' + QUOTENAME(c.[TABLE_SCHEMA]) + '.' + QUOTENAME(c.[TABLE_NAME]) + ''') AND name = N''IDX_METADATA'')' + CHAR(10)
		+ 'CREATE NONCLUSTERED INDEX [IDX_METADATA] ON ' 
		+ QUOTENAME(c.[TABLE_SCHEMA]) + '.' + QUOTENAME(c.[TABLE_NAME])
		+ '(' + QUOTENAME(c.[COLUMN_NAME]) + ' ASC);' + CHAR(13)
	FROM INFORMATION_SCHEMA.COLUMNS c
	INNER JOIN INFORMATION_SCHEMA.TABLES t
		ON c.[TABLE_SCHEMA] = t.[TABLE_SCHEMA]
		AND c.[TABLE_NAME] = t.[TABLE_NAME]
	WHERE c.[COLUMN_NAME] LIKE @metadataPrefix + '_%'
		AND t.[TABLE_TYPE] = 'BASE TABLE';

	EXEC sp_executesql @SQL;

	-- changed at indexes
	SELECT	@SQL += 'IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N''' + QUOTENAME(c.[TABLE_SCHEMA]) + '.' + QUOTENAME(c.[TABLE_NAME]) + ''') AND name = N''IDX_CHANGEDAT'')' + CHAR(10)
		+ 'CREATE NONCLUSTERED INDEX [IDX_CHANGEDAT] ON ' 
		+ QUOTENAME(c.[TABLE_SCHEMA]) + '.' + QUOTENAME(c.[TABLE_NAME])
		+ '(' + QUOTENAME(c.[COLUMN_NAME]) + ' ASC);' + CHAR(13)
	FROM INFORMATION_SCHEMA.COLUMNS c
	INNER JOIN INFORMATION_SCHEMA.TABLES t
		ON c.[TABLE_SCHEMA] = t.[TABLE_SCHEMA]
		AND c.[TABLE_NAME] = t.[TABLE_NAME]
	WHERE c.[COLUMN_NAME] LIKE '%_' + @changedAtSuffix
		AND t.[TABLE_TYPE] = 'BASE TABLE';

	EXEC sp_executesql @SQL;

	COMMIT TRAN;

END TRY

BEGIN CATCH

	DECLARE @ErrorMessage NVARCHAR(4000);
	DECLARE @ErrorSeverity INT;
	DECLARE @ErrorState INT;

	SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();

	ROLLBACK TRAN;

	RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);

	RETURN -1;

END CATCH;