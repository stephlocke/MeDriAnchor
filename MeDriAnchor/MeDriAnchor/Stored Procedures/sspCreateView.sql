
-- CREATE VIEW
CREATE PROCEDURE [MeDriAnchor].[sspCreateView]
(
	@TableSchema SYSNAME,
	@TableName SYSNAME,
	@TableColumnsCV [MeDriAnchor].[TableColumns] READONLY,
	@Debug BIT = 0
)
AS
/*
GENERATES THE SQL FOR THE CREATION OF A VIEW
*/
DECLARE @SQL NVARCHAR(MAX) = '';
DECLARE @COLUMNS_NO_DATA_TYPE NVARCHAR(MAX) = '';
DECLARE @ViewNamePrefix NVARCHAR(20) = 'av';
DECLARE @ViewNamePostfix NVARCHAR(20) = '';

BEGIN TRY

	SELECT	@ViewNamePrefix = [ViewNamePrefix],
			@ViewNamePostfix = [ViewNamePostfix]
	FROM [MeDriAnchor].[svExtProps];

	SET @SQL += 'CREATE VIEW [' + @TableSchema + '].[' + @ViewNamePrefix + @TableName + ']' + CHAR(13)

	SELECT @COLUMNS_NO_DATA_TYPE += QUOTENAME(ColumnName) + ',' + CHAR(13)
	FROM @TableColumnsCV
	ORDER BY ColPosition;
	SET @COLUMNS_NO_DATA_TYPE = left(@COLUMNS_NO_DATA_TYPE, len(@COLUMNS_NO_DATA_TYPE) - 2);

	SET @SQL += 'AS' + CHAR(13)
	
	-- YAML metadata here
	SET @SQL += '/**' + CHAR(13);
	SET @SQL += 'revisions:' + CHAR(13);
	SET @SQL += ' - author: MeDriAnchor' + CHAR(13);
	SET @SQL += '	date: ' + CONVERT(VARCHAR(11), GETDATE(), 106) + CHAR(13);
	SET @SQL += 'summary:	>' + CHAR(13);
	SET @SQL += '				Retrieves ' + QUOTENAME(@TableSchema) + '.' + QUOTENAME(@TableName) + ' table records' + CHAR(13);
	SET @SQL += ' - code:	SELECT * FROM [' + @TableSchema + '].[' + @ViewNamePrefix + @TableName + ']' + CHAR(13);
	SET @SQL += '	parameters: n/a' + CHAR(13);
	SET @SQL += 'returns: ' + QUOTENAME(@TableSchema) + '.' + QUOTENAME(@TableName) + ' table records' + CHAR(13);
	SET @SQL += '**/' + CHAR(13);
	
	-- body here
	SET @SQL += 'SELECT' + CHAR(13)
	SET @SQL += @COLUMNS_NO_DATA_TYPE + CHAR(13)
	SET @SQL += 'FROM [' + @TableSchema + '].[' + @TableName + ']' + CHAR(13) + CHAR(13)

	IF (@Debug = 0)
	BEGIN
		EXEC sys.sp_executesql @SQL;
	END
	ELSE
	BEGIN
		PRINT @SQL;
	END

	RETURN 0;

END TRY

BEGIN CATCH

	DECLARE @ErrorMessage NVARCHAR(4000);
	DECLARE @ErrorSeverity INT;
	DECLARE @ErrorState INT;

	SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();

	RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);

	RETURN -1;

END CATCH;
