
-- CREATE INSERT
CREATE PROCEDURE [MeDriAnchor].[sspCreateInsertSP]
(
	@TableSchema SYSNAME,
	@TableName SYSNAME,
	@TableColumnsCISP [MeDriAnchor].[TableColumns] READONLY,
	@UsingShadow BIT,
	@Debug BIT = 0
)
AS
/*
GENERATES THE SQL FOR THE CREATION OF AN INSERT STORED PROCEDURE
*/
DECLARE @SQL NVARCHAR(MAX) = '';
DECLARE @PARAMETER_COLUMNS NVARCHAR(MAX) = '';
DECLARE @COLUMN_LIST_NO_DATA_TYPE_MINUS_IDENTITY_PK_QUOTED NVARCHAR(MAX) = '';
DECLARE @COLUMN_LIST_NO_DATA_TYPE_MINUS_IDENTITY_PK_QUOTED_PARAMS NVARCHAR(MAX) = '';
DECLARE @COLUMNS_NO_DATA_TYPE_QUOTED NVARCHAR(MAX) = '';
DECLARE @PARAMETER_SETS NVARCHAR(MAX) = '';
DECLARE @PK_COLUMN NVARCHAR(2000) = '';
DECLARE @IDENTITY_COL NVARCHAR(200);
DECLARE @InsertProcNamePrefix NVARCHAR(20) = 'asp';
DECLARE @InsertProcNamePostfix NVARCHAR(20) = '_Insert';
DECLARE @ShadowTableNamePrefix NVARCHAR(20) = '';
DECLARE @ShadowTableNamePostfix NVARCHAR(20) = '_Shadow';

BEGIN TRY

	SELECT	@InsertProcNamePrefix = [InsertProcNamePrefix],
			@InsertProcNamePostfix = [InsertProcNamePostfix],
			@ShadowTableNamePrefix = [ShadowTableNamePrefix],
			@ShadowTableNamePostfix = [ShadowTableNamePostfix]
	FROM [MeDriAnchor].[svExtProps];

	-- string together the pk column(s) with no data type
	SELECT @PK_COLUMN += QUOTENAME(ColumnName) + ' = @' + ColumnName  + ' AND '
	FROM @TableColumnsCISP
	WHERE PKColumn = 1
	ORDER BY ColPosition;
	SET @PK_COLUMN = SUBSTRING(@PK_COLUMN, 1, LEN(@PK_COLUMN) - 4);

	-- get the identity column if there is one
	SELECT @IDENTITY_COL = '@' + ColumnName
	FROM @TableColumnsCISP
	WHERE IdentityColumn = 1
	
	-- build the parameter list (all columns and datatypes with defaults)
	SELECT @PARAMETER_COLUMNS += '@' + ColumnName + ' as ' + ParameterType + ',' + CHAR(13)
	FROM @TableColumnsCISP
	WHERE IsComputedCol = 0
	ORDER BY ColPosition;
	SET @PARAMETER_COLUMNS = SUBSTRING(@PARAMETER_COLUMNS, 1, LEN(@PARAMETER_COLUMNS) - 2);

	-- get a list of all columns with no datatype (quoted)
	SELECT @COLUMNS_NO_DATA_TYPE_QUOTED += QUOTENAME(ColumnName) + ','
	FROM @TableColumnsCISP
	ORDER BY ColPosition;
	SET @COLUMNS_NO_DATA_TYPE_QUOTED = SUBSTRING(@COLUMNS_NO_DATA_TYPE_QUOTED, 1, LEN(@COLUMNS_NO_DATA_TYPE_QUOTED) - 1);

	-- get a list of all columns with no datatype minus the pk column(s) (quoted)
	SELECT @COLUMN_LIST_NO_DATA_TYPE_MINUS_IDENTITY_PK_QUOTED += QUOTENAME(ColumnName) + ','
	FROM @TableColumnsCISP
	WHERE IsComputedCol = 0
		AND (PKColumn = 0 OR (PKColumn = 1 AND IdentityColumn = 0))
	ORDER BY ColPosition;
	SET @COLUMN_LIST_NO_DATA_TYPE_MINUS_IDENTITY_PK_QUOTED = SUBSTRING(@COLUMN_LIST_NO_DATA_TYPE_MINUS_IDENTITY_PK_QUOTED, 1, LEN(@COLUMN_LIST_NO_DATA_TYPE_MINUS_IDENTITY_PK_QUOTED) - 1);

	-- get a list of all columns with no datatype minus the pk column(s) (parameters)
	SELECT @COLUMN_LIST_NO_DATA_TYPE_MINUS_IDENTITY_PK_QUOTED_PARAMS += '@' + ColumnName + ','
	FROM @TableColumnsCISP
	WHERE IsComputedCol = 0
		AND (PKColumn = 0 OR (PKColumn = 1 AND IdentityColumn = 0))
	ORDER BY ColPosition;
	SET @COLUMN_LIST_NO_DATA_TYPE_MINUS_IDENTITY_PK_QUOTED_PARAMS = SUBSTRING(@COLUMN_LIST_NO_DATA_TYPE_MINUS_IDENTITY_PK_QUOTED_PARAMS, 1, LEN(@COLUMN_LIST_NO_DATA_TYPE_MINUS_IDENTITY_PK_QUOTED_PARAMS) - 1);

	SELECT @PARAMETER_SETS += ParameterTypeSet + CHAR(13)
	FROM @TableColumnsCISP
	WHERE ParameterTypeSet <> ''
	ORDER BY ColPosition;

	-- create and parameters
	SET @SQL += 'CREATE PROC [' + @TableSchema + '].[' + @InsertProcNamePrefix + @TableName + @InsertProcNamePostfix + ']' + CHAR(13)
	SET @SQL += '(' + CHAR(13)
	SET @SQL += @PARAMETER_COLUMNS + CHAR(13)
	SET @SQL += ')' + CHAR(13)
	SET @SQL += 'AS' + CHAR(13)
	SET @SQL += '' + CHAR(13)
	
	-- YAML metadata here
	SET @SQL += '/**' + CHAR(13);
	SET @SQL += 'revisions:' + CHAR(13);
	SET @SQL += ' - author: MeDriAnchor' + CHAR(13);
	SET @SQL += '	date: ' + CONVERT(VARCHAR(11), GETDATE(), 106) + CHAR(13);
	SET @SQL += 'summary:	>' + CHAR(13);
	SET @SQL += '				Creates an ' + QUOTENAME(@TableSchema) + '.' + QUOTENAME(@TableName) + ' table record' + CHAR(13);
	SET @SQL += ' - code:	EXEC [' + @TableSchema + '].[' + @InsertProcNamePrefix + @TableName + @InsertProcNamePostfix + ']' + CHAR(13);
	SET @SQL += '	parameters: ' + REPLACE(REPLACE(@PARAMETER_COLUMNS, CHAR(13), ''), ' as ', ' : ') + CHAR(13);
	IF ISNULL(@IDENTITY_COL, '') = ''
	BEGIN
		SET @SQL += 'returns: 0 if success, otherwise -1' + CHAR(13);
	END
	ELSE
	BEGIN
		SET @SQL += 'returns: new ' + REPLACE(CONVERT(SYSNAME, @IDENTITY_COL), '@', '') + ' value if success, otherwise -1' + CHAR(13);
	END
	SET @SQL += '**/' + CHAR(13);
	
	-- body
	SET @SQL += 'BEGIN TRANSACTION;' + CHAR(13) + CHAR(13)
	SET @SQL += 'BEGIN TRY' + CHAR(13) + CHAR(13)
	IF (@PARAMETER_SETS <> '')
		SET @SQL += @PARAMETER_SETS + CHAR(13)
	SET @SQL += '	INSERT INTO  [' + @TableSchema + '].[' + @TableName + '](' + @COLUMN_LIST_NO_DATA_TYPE_MINUS_IDENTITY_PK_QUOTED + ')' + CHAR(13)
	IF (@UsingShadow = 1)
	BEGIN
		SET @SQL += 'OUTPUT ''I'', ' + REPLACE(@COLUMNS_NO_DATA_TYPE_QUOTED, '[', '[INSERTED].[')
		SET @SQL += '	INTO [' + @TableSchema + '].[' + @ShadowTableNamePrefix + @TableName + @ShadowTableNamePostfix + ']([' + Replace(@ShadowTableNamePostfix, '_', '') + 'Type],' + @COLUMNS_NO_DATA_TYPE_QUOTED + ')' + CHAR(13)
	END
	SET @SQL += '	VALUES (' + @COLUMN_LIST_NO_DATA_TYPE_MINUS_IDENTITY_PK_QUOTED_PARAMS + ');' + CHAR(13) + CHAR(13)
	IF (ISNULL(@IDENTITY_COL, '') <> '')
		SET @SQL += '	SET ' + @IDENTITY_COL + ' = SCOPE_IDENTITY();' + CHAR(13) + CHAR(13)
	SET @SQL += '	COMMIT TRANSACTION;' + CHAR(13) + CHAR(13)
	SET @SQL += '	RETURN ' + ISNULL(@IDENTITY_COL, 0) + ';' + CHAR(13) + CHAR(13)
	SET @SQL += 'END TRY' + CHAR(13) + CHAR(13)
	
	-- catch block
	SET @SQL += 'BEGIN CATCH' + CHAR(13) + CHAR(13)  
	SET @SQL += '	DECLARE @ErrorMessage NVARCHAR(4000);' + CHAR(13)
	SET @SQL += '	DECLARE @ErrorSeverity INT;' + CHAR(13)
	SET @SQL += '	DECLARE @ErrorState INT;' + CHAR(13) + CHAR(13)
	SET @SQL += '	SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();' + CHAR(13) + CHAR(13)
	SET @SQL += '	RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);' + CHAR(13) + CHAR(13)
	SET @SQL += '	ROLLBACK TRANSACTION;' + CHAR(13) + CHAR(13) 
	SET @SQL += '	RETURN -1;' + CHAR(13) + CHAR(13) 
	SET @SQL += 'END CATCH;' + CHAR(13) + CHAR(13)
	
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
