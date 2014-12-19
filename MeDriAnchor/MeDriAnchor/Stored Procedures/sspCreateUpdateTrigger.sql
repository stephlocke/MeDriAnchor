
-- CREATE UPDATE TRIGGER
CREATE PROCEDURE [MeDriAnchor].[sspCreateUpdateTrigger]
(
	@TableSchema SYSNAME,
	@TableName SYSNAME,
	@TableColumnsCUT [MeDriAnchor].[TableColumns] READONLY,
	@UsingShadow BIT,
	@Debug BIT = 0
)
AS
/*
GENERATES THE SQL FOR THE CREATION OF AN UPDATE TRIGGER
*/
DECLARE @SQL NVARCHAR(MAX) = '';
DECLARE @COLUMNS_NO_DATA_TYPE_QUOTED NVARCHAR(MAX) = '';
DECLARE @TriggerNamePrefix NVARCHAR(20) = 'atr';
DECLARE @TriggerNamePostfix NVARCHAR(20) = '_Update';
DECLARE @ShadowTableNamePrefix NVARCHAR(20) = '';
DECLARE @ShadowTableNamePostfix NVARCHAR(20) = '_Shadow'; 

BEGIN TRY

	SELECT	@TriggerNamePrefix = [UpdateTriggerNamePrefix],
			@TriggerNamePostfix = [UpdateTriggerNamePostfix],
			@ShadowTableNamePrefix = [ShadowTableNamePrefix],
			@ShadowTableNamePostfix = [ShadowTableNamePostfix]
	FROM [MeDriAnchor].[svExtProps];

	-- get a list of all columns with no datatype (quoted)
	SELECT @COLUMNS_NO_DATA_TYPE_QUOTED += QUOTENAME(ColumnName) + ','
	FROM @TableColumnsCUT
	ORDER BY ColPosition;
	SET @COLUMNS_NO_DATA_TYPE_QUOTED = SUBSTRING(@COLUMNS_NO_DATA_TYPE_QUOTED, 1, LEN(@COLUMNS_NO_DATA_TYPE_QUOTED) - 1);

	-- create and parameters
	SET @SQL += 'CREATE TRIGGER [' + @TableSchema + '].[' + @TriggerNamePrefix + @TableName + @TriggerNamePostfix + ']' + CHAR(13)
	SET @SQL += 'ON [' + @TableSchema + '].[' + @TableName + '] WITH EXECUTE AS ''MeDriAnchorUser''' + CHAR(13)
	SET @SQL += 'FOR UPDATE' + CHAR(13)
	SET @SQL += 'AS' + CHAR(13)
	SET @SQL += '' + CHAR(13)
	
	-- YAML metadata here
	SET @SQL += '/**' + CHAR(13);
	SET @SQL += 'revisions:' + CHAR(13);
	SET @SQL += ' - author: MeDriAnchor' + CHAR(13);
	SET @SQL += '	date: ' + CONVERT(VARCHAR(11), GETDATE(), 106) + CHAR(13);
	SET @SQL += 'revisions:' + CHAR(13);
	SET @SQL += ' - author: MeDriAnchor' + CHAR(13);
	SET @SQL += '	date: ' + CONVERT(VARCHAR(11), GETDATE(), 106) + CHAR(13);
	SET @SQL += 'summary:	>' + CHAR(13);
	SET @SQL += '				Records the update of an ' + QUOTENAME(@TableSchema) + '.' + QUOTENAME(@TableName) + ' table record' + CHAR(13);
	SET @SQL += ' - code:	Cannot be called from client code' + CHAR(13);
	SET @SQL += '	parameters: n/a' + CHAR(13);
	SET @SQL += 'returns: on success nothing, otherwise throws an error' + CHAR(13);
	SET @SQL += '**/' + CHAR(13);
	
	-- body
	SET @SQL += 'BEGIN TRY' +  + CHAR(13) +  + CHAR(13)
	SET @SQL += '	INSERT INTO [' + @TableSchema + '].[' + @ShadowTableNamePrefix + @TableName + @ShadowTableNamePostfix + ']' + CHAR(13);
	SET @SQL += '	([' + RIGHT(@ShadowTableNamePostfix, LEN(@ShadowTableNamePostfix) - 1) + 'Type],' + @COLUMNS_NO_DATA_TYPE_QUOTED + ')' + CHAR(13);
	SET @SQL += '	SELECT ''U'',' + REPLACE(REPLACE(@COLUMNS_NO_DATA_TYPE_QUOTED, '[', '[DELETED].['), 'DELETED.[ModifiedDate]', 'GETDATE()') + CHAR(13);
	SET @SQL += '	FROM DELETED;' + CHAR(13) + CHAR(13);
	SET @SQL += 'END TRY' + CHAR(13) + CHAR(13)
	
	-- catch block
	SET @SQL += 'BEGIN CATCH' + CHAR(13) + CHAR(13)  
	SET @SQL += '	DECLARE @ErrorMessage NVARCHAR(4000);' + CHAR(13)
	SET @SQL += '	DECLARE @ErrorSeverity INT;' + CHAR(13)
	SET @SQL += '	DECLARE @ErrorState INT;' + CHAR(13) + CHAR(13)
	SET @SQL += '	SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();' + CHAR(13) + CHAR(13)
	SET @SQL += '	RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);' + CHAR(13) + CHAR(13) 
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
