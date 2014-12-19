
-- CREATE DELETE
CREATE PROCEDURE [MeDriAnchor].[sspCreateDeleteSP]
(
	@TableSchema SYSNAME,
	@TableName SYSNAME,
	@TableColumnsCDSP [MeDriAnchor].[TableColumns] READONLY,
	@UsingShadow BIT,
	@Debug BIT = 0
)
AS
/*
GENERATES A DELETE STORED PROCEDURE
*/
DECLARE @SQL NVARCHAR(MAX) = '';
DECLARE @PK_COLUMN_TYPE NVARCHAR(MAX) = '';
DECLARE @PK_COLUMN NVARCHAR(200) = '';
DECLARE @ALL_COLUMNS NVARCHAR(MAX) = '';
DECLARE @DeletedProcNamePrefix NVARCHAR(20) = 'asp';
DECLARE @DeletedProcNamePostfix NVARCHAR(20) = '_Delete';
DECLARE @ShadowTableNamePrefix NVARCHAR(20) = '';
DECLARE @ShadowTableNamePostfix NVARCHAR(20) = '_Shadow';

BEGIN TRY 

	SELECT	@DeletedProcNamePrefix = [DeleteProcNamePrefix],
			@DeletedProcNamePostfix = [DeleteProcNamePostfix],
			@ShadowTableNamePrefix = [ShadowTableNamePrefix],
			@ShadowTableNamePostfix = [ShadowTableNamePostfix]
	FROM [MeDriAnchor].[svExtProps];

	-- string together the pk column(s) with no data type
	SELECT @PK_COLUMN += QUOTENAME(ColumnName) + ' = @' + ColumnName  + ' AND '
	FROM @TableColumnsCDSP
	WHERE PKColumn = 1
	ORDER BY ColPosition;
	SET @PK_COLUMN = SUBSTRING(@PK_COLUMN, 1, LEN(@PK_COLUMN) - 4);
	
	-- string together the pk column(s) details
	SELECT @PK_COLUMN_TYPE += '@' + ColumnName 
			+ ' as ' 
			+ (CASE DataType WHEN 'numeric' THEN DataType + '(' + CONVERT(VARCHAR(10), NumericPrecision) + ',' + CONVERT(VARCHAR(10), NumericScale) + ')' ELSE DataType END)
			+ (CASE WHEN CharMaxLength IS NOT NULL AND DataType NOT IN('hierarchyid') THEN '(' + CASE WHEN CONVERT(VARCHAR(10), CharMaxLength) = '-1' THEN 'MAX' ELSE CONVERT(VARCHAR(10), CharMaxLength) END + ')' ELSE '' END)
			+ ',' + CHAR(13) 
	FROM @TableColumnsCDSP
	WHERE PKColumn = 1
	ORDER BY ColPosition;
	SET @PK_COLUMN_TYPE = SUBSTRING(@PK_COLUMN_TYPE, 1, LEN(@PK_COLUMN_TYPE) - 2);

	-- string together all the columns
	SELECT @ALL_COLUMNS += 'DELETED.' + QUOTENAME(ColumnName) + ','
	FROM @TableColumnsCDSP
	ORDER BY ColPosition;
	SET @ALL_COLUMNS = SUBSTRING(@ALL_COLUMNS, 1, LEN(@ALL_COLUMNS) - 1);
	
	-- create and parameters (pks)
	SET @SQL += 'CREATE PROC [' + @TableSchema + '].[' + @DeletedProcNamePrefix + @TableName + @DeletedProcNamePostfix + ']' + CHAR(13);
	SET @SQL += '(' + CHAR(13);
	SET @SQL += @PK_COLUMN_TYPE + CHAR(13);
	SET @SQL += ')' + CHAR(13);
	SET @SQL += 'AS' + CHAR(13);
	SET @SQL += '' + CHAR(13);
	
	-- YAML metadata here
	SET @SQL += '/**' + CHAR(13);
	SET @SQL += 'revisions:' + CHAR(13);
	SET @SQL += ' - author: MeDriAnchor' + CHAR(13);
	SET @SQL += '	date: ' + CONVERT(VARCHAR(11), GETDATE(), 106) + CHAR(13);
	SET @SQL += 'summary:	>' + CHAR(13);
	SET @SQL += '				Deletes an ' + QUOTENAME(@TableSchema) + '.' + QUOTENAME(@TableName) + ' table record' + CHAR(13);
	SET @SQL += ' - code:	EXEC [' + @TableSchema + '].[' + @DeletedProcNamePrefix + @TableName + @DeletedProcNamePostfix + ']' + CHAR(13);
	SET @SQL += '	parameters: ' + REPLACE(REPLACE(@PK_COLUMN_TYPE, CHAR(13), ''), ' as ', ' : ') + CHAR(13);
	SET @SQL += 'returns: 0 if success, otherwise -1' + CHAR(13);
	SET @SQL += '**/' + CHAR(13);
	
	-- body
	SET @SQL += 'BEGIN TRANSACTION' + CHAR(13) + CHAR(13); 
	SET @SQL += 'BEGIN TRY' + CHAR(13) + CHAR(13);
	SET @SQL += '	-- DELETE' + CHAR(13);
	SET @SQL += '	DELETE FROM [' + @TableSchema + '].[' + @TableName + ']' + CHAR(13);
	IF (@UsingShadow = 1)
	BEGIN
		SET @SQL += '	OUTPUT ''D'',' + REPLACE(@ALL_COLUMNS, 'DELETED.[ModifiedDate]', 'GETDATE()') + CHAR(13);
		SET @SQL += '	INTO [' + @TableSchema + '].[' + @ShadowTableNamePrefix + @TableName + @ShadowTableNamePostfix + ']';
		SET @SQL += '([' + REPLACE(@ShadowTableNamePostfix, '_', '') + 'Type], ' + REPLACE(@ALL_COLUMNS, 'Deleted.', '') + ')' + CHAR(13);
	END
	SET @SQL += '	WHERE ' + @PK_COLUMN + ';' + CHAR(13) + CHAR(13);
	SET @SQL += '	COMMIT TRANSACTION' + CHAR(13) + CHAR(13);
	SET @SQL += '	RETURN 0;' + CHAR(13) + CHAR(13);
	SET @SQL += 'END TRY' + CHAR(13) + CHAR(13);

	-- catch block
	SET @SQL += 'BEGIN CATCH' + CHAR(13) + CHAR(13);
	SET @SQL += '	DECLARE @ErrorMessage NVARCHAR(4000);' + CHAR(13);
	SET @SQL += '	DECLARE @ErrorSeverity INT;' + CHAR(13);
	SET @SQL += '	DECLARE @ErrorState INT;' + CHAR(13) + CHAR(13);
	SET @SQL += '	SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();' + CHAR(13) + CHAR(13);
	SET @SQL += '	RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);' + CHAR(13) + CHAR(13);
	SET @SQL += '	ROLLBACK TRANSACTION' + CHAR(13) + CHAR(13);
	SET @SQL += '	RETURN -1;' + CHAR(13) + CHAR(13);
	SET @SQL += 'END CATCH;' + CHAR(13) + CHAR(13);
  
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
