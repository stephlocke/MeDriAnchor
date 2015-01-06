CREATE PROCEDURE [MeDriAnchor].[sspCreateDWHTests]
(
	@Batch_ID BIGINT,
	@Metadata_ID BIGINT,
	@Environment_ID SMALLINT,
	@Debug BIT = 0
)
AS
SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
/*
GENERATES THE TESTS TO RUN OVER THE DWH
*/

-- Build the tests
DECLARE @ProcNamePrefix NVARCHAR(20) = 'amsp_TEST_';
DECLARE @ProcNamePostfix NVARCHAR(20) = '_Run';
DECLARE @DBTableName SYSNAME;
DECLARE @DBTableColumnName SYSNAME;
DECLARE @DBTableColumnID BIGINT;
DECLARE @DWHTableName SYSNAME;
DECLARE @DWHTableColumnData SYSNAME;
DECLARE @TestType NVARCHAR(50);
DECLARE @TestValue1 SQL_VARIANT;
DECLARE @TestValue2 SQL_VARIANT;
DECLARE @AnchorIDColumn SYSNAME;
DECLARE @MetadataColumn SYSNAME;
DECLARE @SQLTEST NVARCHAR(MAX) = '';
DECLARE @identitySuffix NVARCHAR(100) = '';
DECLARE @metadataPrefix NVARCHAR(100) = '';
DECLARE @encapsulation NVARCHAR(100) = '';
DECLARE @SQL NVARCHAR(MAX) = '';
DECLARE @LkpDBTable SYSNAME;
DECLARE @LkpDBTableColumn SYSNAME;
DECLARE @AnchorID SYSNAME;
DECLARE @AnchorTable SYSNAME;

BEGIN TRY

	SELECT	@identitySuffix = MAX(CASE WHEN s.[SettingKey] = 'identitySuffix' THEN COALESCE(se.[SettingValue], s.[SettingValue]) ELSE '' END),
			@metadataPrefix = MAX(CASE WHEN s.[SettingKey] = 'metadataPrefix' THEN COALESCE(se.[SettingValue], s.[SettingValue]) ELSE '' END),
			@encapsulation = MAX(CASE WHEN s.[SettingKey] = 'encapsulation' THEN COALESCE(se.[SettingValue], s.[SettingValue]) ELSE '' END)
	FROM [MeDriAnchor].[Settings] s
	LEFT OUTER JOIN [MeDriAnchor].[SettingsEnvironment] se
		ON s.[SettingKey] = se.[SettingKey]
		AND se.Environment_ID = @Environment_ID
	WHERE s.[SettingKey] IN('identitySuffix', 'metadataPrefix', 'encapsulation');

	-- generate the run procedure
	IF NOT EXISTS(SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_SCHEMA = @encapsulation
		AND ROUTINE_NAME = @ProcNamePrefix + 'DWH' + @ProcNamePostfix)
	BEGIN
		SET @SQL += 'CREATE PROC [' + @encapsulation + '].[' + @ProcNamePrefix + 'DWH' + @ProcNamePostfix + ']' + CHAR(13);
	END
	ELSE
	BEGIN
		SET @SQL += 'ALTER PROC [' + @encapsulation + '].[' + @ProcNamePrefix + 'DWH' + @ProcNamePostfix + ']' + CHAR(13);
	END
	SET @SQL += '(' + CHAR(13);
	SET @SQL += '@Batch_ID BIGINT' + CHAR(13);
	SET @SQL += ')' + CHAR(13);
	SET @SQL += 'AS' + CHAR(13);
	SET @SQL += '' + CHAR(13);
	SET @SQL += 'SET XACT_ABORT ON;' + CHAR(13);
	SET @SQL += 'SET NOCOUNT ON;' + CHAR(13);
	SET @SQL += 'SET QUOTED_IDENTIFIER ON;' + CHAR(13);
	SET @SQL += '' + CHAR(13);
	
	-- YAML metadata here
	SET @SQL += '/**' + CHAR(13);
	SET @SQL += 'revisions:' + CHAR(13);
	SET @SQL += ' - author: MeDriAnchor' + CHAR(13);
	SET @SQL += '	date: ' + CONVERT(VARCHAR(11), GETDATE(), 106) + CHAR(13);
	SET @SQL += 'summary:	>' + CHAR(13);
	SET @SQL += '				DWH Tests ' + CHAR(13);
	SET @SQL += ' - code:	EXEC [' + @encapsulation + '].[' + @ProcNamePrefix + 'DWH' + @ProcNamePostfix + ']' + CHAR(13);
	SET @SQL += '	parameters: @Batch_ID BIGINT' + CHAR(13);
	SET @SQL += '	returns: 0 if success, otherwise -1' + CHAR(13);
	SET @SQL += '	generated using Metadata_ID: ' + CONVERT(NVARCHAR(10), @Metadata_ID) 
		+ ' - Batch_ID: ' + CONVERT(NVARCHAR(10), @Batch_ID) + ' - Environment_ID: ' 
		+ CONVERT(NVARCHAR(10), @Environment_ID) + CHAR(13);
	SET @SQL += '**/' + CHAR(13) + CHAR(13);

	SET @SQL += 'DECLARE @SeverityValidation TINYINT = (SELECT [SeverityID] FROM [MeDriAnchor].[Severity] WHERE [ServerityName] = ''VALIDATION'');' + CHAR(13);
	SET @SQL += 'DECLARE @SeverityWarning TINYINT = (SELECT [SeverityID] FROM [MeDriAnchor].[Severity] WHERE [ServerityName] = ''WARNING'');' + CHAR(13) + CHAR(13);
	
	-- body
	--SET @SQL += 'BEGIN TRANSACTION;' + CHAR(13) + CHAR(13);
	SET @SQL += 'BEGIN TRY' + CHAR(13) + CHAR(13);

	DECLARE TESTSTORUN CURSOR
	READ_ONLY
	FOR
	(
	SELECT	mm.[DBTableName],
			mm.[DBTableColumnName],
			mm.[DBTableColumnID],
			mm.[DWHTableName],
			mm.[DWHTableColumnData],
			test.[TestType],
			tc.[TestValue1],
			tc.[TestValue2],
			(QUOTENAME(mm.[AnchorMnemonic] + '_' + mm.[AttributeMnemonic] + '_' + mm.[AnchorMnemonic] + '_' + @identitySuffix)) AS [AnchorIDColumn],
			(QUOTENAME(@metadataPrefix + '_' + mm.[AnchorMnemonic] + '_' + mm.[AttributeMnemonic])) AS [MetadataColumn],
			QUOTENAME(ldb.[DBName] + '_' + lt.[DBTableSchema] + '_' + lt.[DBTableName]),
			QUOTENAME(ltc.[DBTableColumnName]),
			ma.[DWHTableColumnData] AS [AnchorID],
			ma.[DWHTableName] AS [AnchorTable]
	FROM [MeDriAnchor].[_AnchorToMetadataMap] mm
	INNER JOIN [MeDriAnchor].[DBTableColumn] tc
		ON tc.[DBTableColumnID] = mm.[DBTableColumnID]
	INNER JOIN [MeDriAnchor].[DBTableColumnTests] tests
		ON tests.[DBTableColumnID] = mm.[DBTableColumnID]
	INNER JOIN [MeDriAnchor].[DBTableColumnTest] test
		ON test.[DBTableColumnTestID] = tests.[DBTableColumnTestID]
	INNER JOIN [MeDriAnchor].[_AnchorToMetadataMap] ma
		ON ma.[AnchorMnemonic] = mm.[AnchorMnemonic]
		AND ma.[DWHType] = 'Anchor'
		AND ma.[Environment_ID] = mm.[Environment_ID]
	LEFT OUTER JOIN [MeDriAnchor].[DBTableColumn] ltc
		ON ltc.[DBTableColumnID] = tc.[TestLkpDBTableColumnID]
	LEFT JOIN [MeDriAnchor].[DBTable] lt
		ON lt.[DBTableID] = ltc.[DBTableID]
	LEFT JOIN [MeDriAnchor].[DB] ldb
		ON ldb.[DBID] = lt.[DBID]
	WHERE mm.[DWHType] = 'Attribute'
		AND mm.[Metadata_ID] = @Metadata_ID
		AND mm.[Environment_ID] = @Environment_ID
	GROUP BY	mm.[DBTableName],
				mm.[DBTableColumnName],
				mm.[DBTableColumnID],
				mm.[DWHTableName],
				mm.[DWHTableColumnData],
				test.[TestType],
				tc.[TestValue1],
				tc.[TestValue2],
				(QUOTENAME(mm.[AnchorMnemonic] + '_' + mm.[AttributeMnemonic] + '_' + mm.[AnchorMnemonic] + '_' + @identitySuffix)),
				(QUOTENAME(@metadataPrefix + '_' + mm.[AnchorMnemonic] + '_' + mm.[AttributeMnemonic])),
				QUOTENAME(ldb.[DBName] + '_' + lt.[DBTableSchema] + '_' + lt.[DBTableName]),
				QUOTENAME(ltc.[DBTableColumnName]),
				ma.[DWHTableColumnData],
				ma.[DWHTableName]
	);

	OPEN TESTSTORUN;

	FETCH NEXT FROM TESTSTORUN INTO @DBTableName, @DBTableColumnName, @DBTableColumnID, @DWHTableName, 
		@DWHTableColumnData, @TestType, @TestValue1, @TestValue2, @AnchorIDColumn, @MetadataColumn,
		@LkpDBTable, @LkpDBTableColumn, @AnchorID, @AnchorTable;
	WHILE (@@fetch_status <> -1)
	BEGIN
		IF (@@fetch_status <> -2)
		BEGIN

			SET @SQLTEST = '';

			IF (@TestType = 'BETWEEN (NUMERIC)')
			BEGIN

				SET @SQLTEST += CHAR(9) + '-- Column ' + @DBTableName + '.' + @DBTableColumnName + ' test: Between ' + CONVERT(VARCHAR(50), @TestValue1) 
					+ ' AND ' + CONVERT(VARCHAR(50), @TestValue2) + CHAR(10);
				SET @SQLTEST += CHAR(9) + 'BEGIN TRY' + CHAR(10);
				SET @SQLTEST += CHAR(9) + CHAR(9) + 'INSERT INTO [MeDriAnchor].[EventAlerts]' + CHAR(10);
				SET @SQLTEST += CHAR(9) + CHAR(9) + '(' + CHAR(10);
				SET @SQLTEST += CHAR(9) + CHAR(9) + '[Batch_ID],[SeverityID],[AlertMessage],[AlertDate],[DBTableColumnID],[PKDBTableColumnValue]' + CHAR(10);
				SET @SQLTEST += CHAR(9) + CHAR(9) + ')' + CHAR(10);
				SET @SQLTEST += CHAR(9) + CHAR(9) + 'SELECT @Batch_ID, @SeverityValidation, ''The value '' + CONVERT(NVARCHAR(100), ' + @DWHTableColumnData + ') +' + ''' for this Attribute has failed testing: Between ' + CONVERT(VARCHAR(50), @TestValue1) 
					+ ' AND ' + CONVERT(VARCHAR(50), @TestValue2) + ' '', GETDATE(), ' + CONVERT(VARCHAR(10), @DBTableColumnID) + ', ' + @AnchorIDColumn + CHAR(10);
				SET @SQLTEST += CHAR(9) + CHAR(9) + 'FROM ' + @DWHTableName + CHAR(10);
				SET @SQLTEST += CHAR(9) + CHAR(9) + 'WHERE (' + @MetadataColumn + ' = @Batch_ID' + CHAR(10);
				SET @SQLTEST += CHAR(9) + CHAR(9) + CHAR(9) + ' AND NOT (' + @DWHTableColumnData + ' BETWEEN '
				SET @SQLTEST += CONVERT(NVARCHAR(50), @TestValue1) + ' AND ' + CONVERT(NVARCHAR(50), @TestValue2) + '));' + CHAR(10);
				SET @SQLTEST += CHAR(9) + 'END TRY' + CHAR(10);
				SET @SQLTEST += CHAR(9) + 'BEGIN CATCH' + CHAR(10);
				SET @SQLTEST += CHAR(9) + CHAR(9) + 'INSERT INTO [MeDriAnchor].[EventAlerts]' + CHAR(10);
				SET @SQLTEST += CHAR(9) + CHAR(9) + '(' + CHAR(10);
				SET @SQLTEST += CHAR(9) + CHAR(9) + '[Batch_ID],[SeverityID],[AlertMessage],[AlertDate],[DBTableColumnID],[PKDBTableColumnValue]' + CHAR(10);
				SET @SQLTEST += CHAR(9) + CHAR(9) + ')' + CHAR(10);
				SET @SQLTEST += CHAR(9) + CHAR(9) + 'VALUES(@Batch_ID, @SeverityWarning, ''Unable to run ' + @TestType + ' test for ' + @DBTableName + '.' + @DBTableColumnName + ': Between ' + CONVERT(VARCHAR(50), @TestValue1) 
					+ ' AND ' + CONVERT(VARCHAR(50), @TestValue2) + '. Error - '' + ERROR_MESSAGE(), GETDATE(), NULL, NULL);' + CHAR(10);
				SET @SQLTEST += CHAR(9) + 'END CATCH' + CHAR(10);

			END

			IF (@TestType = 'BETWEEN (YEARS FROM VALUE)')
			BEGIN

				SET @SQLTEST += CHAR(9) + '-- Column ' + @DBTableName + '.' + @DBTableColumnName + ' test: Year from value between ' + CONVERT(VARCHAR(50), @TestValue1) 
					+ ' AND ' + CONVERT(VARCHAR(50), @TestValue2) + CHAR(10);
				SET @SQLTEST += CHAR(9) + 'BEGIN TRY' + CHAR(10);
				SET @SQLTEST += CHAR(9) + CHAR(9) + 'INSERT INTO [MeDriAnchor].[EventAlerts]' + CHAR(10);
				SET @SQLTEST += CHAR(9) + CHAR(9) + '(' + CHAR(10);
				SET @SQLTEST += CHAR(9) + CHAR(9) + '[Batch_ID],[SeverityID],[AlertMessage],[AlertDate],[DBTableColumnID],[PKDBTableColumnValue]' + CHAR(10);
				SET @SQLTEST += CHAR(9) + CHAR(9) + ')' + CHAR(10);
				SET @SQLTEST += CHAR(9) + CHAR(9) + 'SELECT @Batch_ID, @SeverityValidation, ''The value '' + CONVERT(NVARCHAR(100), ' + @DWHTableColumnData + ') +' + ''' for this Attribute has failed testing: Between ' + CONVERT(VARCHAR(50), @TestValue1) 
					+ ' AND ' + CONVERT(VARCHAR(50), @TestValue2) + ' '', GETDATE(), ' + CONVERT(VARCHAR(10), @DBTableColumnID) + ', ' + @AnchorIDColumn + CHAR(10);
				SET @SQLTEST += CHAR(9) + CHAR(9) + 'FROM ' + @DWHTableName + CHAR(10);
				SET @SQLTEST += CHAR(9) + CHAR(9) + 'WHERE (' + @MetadataColumn + ' = @Batch_ID' + CHAR(10);
				SET @SQLTEST += CHAR(9) + CHAR(9) + CHAR(9) + ' AND NOT (YEAR(' + @DWHTableColumnData + ') BETWEEN '
				SET @SQLTEST += CONVERT(NVARCHAR(50), @TestValue1) + ' AND ' + CONVERT(NVARCHAR(50), @TestValue2) + '));' + CHAR(10);
				SET @SQLTEST += CHAR(9) + 'END TRY' + CHAR(10);
				SET @SQLTEST += CHAR(9) + 'BEGIN CATCH' + CHAR(10);
				SET @SQLTEST += CHAR(9) + CHAR(9) + 'INSERT INTO [MeDriAnchor].[EventAlerts]' + CHAR(10);
				SET @SQLTEST += CHAR(9) + CHAR(9) + '(' + CHAR(10);
				SET @SQLTEST += CHAR(9) + CHAR(9) + '[Batch_ID],[SeverityID],[AlertMessage],[AlertDate],[DBTableColumnID],[PKDBTableColumnValue]' + CHAR(10);
				SET @SQLTEST += CHAR(9) + CHAR(9) + ')' + CHAR(10);
				SET @SQLTEST += CHAR(9) + CHAR(9) + 'VALUES(@Batch_ID, @SeverityWarning, ''Unable to run ' + @TestType + ' test for ' + @DBTableName + '.' + @DBTableColumnName + ': Year from value between ' + CONVERT(VARCHAR(50), @TestValue1) 
					+ ' AND ' + CONVERT(VARCHAR(50), @TestValue2) + '. Error - '' + ERROR_MESSAGE(), GETDATE(), NULL, NULL);' + CHAR(10);
				SET @SQLTEST += CHAR(9) + 'END CATCH' + CHAR(10);

			END

			IF (@TestType = 'IS NOT BLANK')
			BEGIN

				SET @SQLTEST += CHAR(9) + '-- Column ' + @DBTableName + '.' + @DBTableColumnName + ' test: Is not blank' + CHAR(10);
				SET @SQLTEST += CHAR(9) + 'BEGIN TRY' + CHAR(10);
				SET @SQLTEST += CHAR(9) + CHAR(9) + 'INSERT INTO [MeDriAnchor].[EventAlerts]' + CHAR(10);
				SET @SQLTEST += CHAR(9) + CHAR(9) + '(' + CHAR(10);
				SET @SQLTEST += CHAR(9) + CHAR(9) + '[Batch_ID],[SeverityID],[AlertMessage],[AlertDate],[DBTableColumnID],[PKDBTableColumnValue]' + CHAR(10);
				SET @SQLTEST += CHAR(9) + CHAR(9) + ')' + CHAR(10);
				SET @SQLTEST += CHAR(9) + CHAR(9) + 'SELECT @Batch_ID, @SeverityValidation, ''The value '' + CONVERT(NVARCHAR(100), ' + @DWHTableColumnData + ') +' + ''' for this Attribute has failed testing: Is not blank'', GETDATE(), ' + CONVERT(VARCHAR(10), @DBTableColumnID) + ', ' + @AnchorIDColumn + CHAR(10);
				SET @SQLTEST += CHAR(9) + CHAR(9) + 'FROM ' + @DWHTableName + CHAR(10);
				SET @SQLTEST += CHAR(9) + CHAR(9) + 'WHERE (' + @MetadataColumn + ' = @Batch_ID' + CHAR(10);
				SET @SQLTEST += CHAR(9) + CHAR(9) + CHAR(9) + ' AND ' + @DWHTableColumnData + ' = '''');' + CHAR(10);
				SET @SQLTEST += CHAR(9) + 'END TRY' + CHAR(10);
				SET @SQLTEST += CHAR(9) + 'BEGIN CATCH' + CHAR(10);
				SET @SQLTEST += CHAR(9) + CHAR(9) + 'INSERT INTO [MeDriAnchor].[EventAlerts]' + CHAR(10);
				SET @SQLTEST += CHAR(9) + CHAR(9) + '(' + CHAR(10);
				SET @SQLTEST += CHAR(9) + CHAR(9) + '[Batch_ID],[SeverityID],[AlertMessage],[AlertDate],[DBTableColumnID],[PKDBTableColumnValue]' + CHAR(10);
				SET @SQLTEST += CHAR(9) + CHAR(9) + ')' + CHAR(10);
				SET @SQLTEST += CHAR(9) + CHAR(9) + 'VALUES(@Batch_ID, @SeverityWarning, ''Unable to run ' + @TestType + ' test for ' + @DBTableName + '.' + @DBTableColumnName + ': Is not blank. Error - '' + ERROR_MESSAGE(), GETDATE(), NULL, NULL);' + CHAR(10);
				SET @SQLTEST += CHAR(9) + 'END CATCH' + CHAR(10);

			END

			IF (@TestType = 'IS NOT NULL')
			BEGIN

				SET @SQLTEST += CHAR(9) + '-- Column ' + @DBTableName + '.' + @DBTableColumnName + ' test: Is not null' + CHAR(10);
				SET @SQLTEST += CHAR(9) + 'BEGIN TRY' + CHAR(10);
				SET @SQLTEST += CHAR(9) + CHAR(9) + 'INSERT INTO [MeDriAnchor].[EventAlerts]' + CHAR(10);
				SET @SQLTEST += CHAR(9) + CHAR(9) + '(' + CHAR(10);
				SET @SQLTEST += CHAR(9) + CHAR(9) + '[Batch_ID],[SeverityID],[AlertMessage],[AlertDate],[DBTableColumnID],[PKDBTableColumnValue]' + CHAR(10);
				SET @SQLTEST += CHAR(9) + CHAR(9) + ')' + CHAR(10);
				SET @SQLTEST += CHAR(9) + CHAR(9) + 'SELECT @Batch_ID, @SeverityValidation, ''This attribute has a null value for the Anchor.'', GETDATE(), ' + CONVERT(VARCHAR(10), @DBTableColumnID) + ', ' + @AnchorID + CHAR(10);
				SET @SQLTEST += CHAR(9) + CHAR(9) + 'FROM ' + @AnchorTable + CHAR(10);
				SET @SQLTEST += CHAR(9) + CHAR(9) + 'WHERE NOT EXISTS (SELECT * FROM ' + @DWHTableName + CHAR(10);
				SET @SQLTEST += CHAR(9) + CHAR(9) + 'WHERE ' + @AnchorIDColumn + ' = ' + @AnchorID + CHAR(10);
				SET @SQLTEST += CHAR(9) + CHAR(9) + 'AND ' + @MetadataColumn + ' <= @Batch_ID);' + CHAR(10);
				SET @SQLTEST += CHAR(9) + 'END TRY' + CHAR(10);
				SET @SQLTEST += CHAR(9) + 'BEGIN CATCH' + CHAR(10);
				SET @SQLTEST += CHAR(9) + CHAR(9) + 'INSERT INTO [MeDriAnchor].[EventAlerts]' + CHAR(10);
				SET @SQLTEST += CHAR(9) + CHAR(9) + '(' + CHAR(10);
				SET @SQLTEST += CHAR(9) + CHAR(9) + '[Batch_ID],[SeverityID],[AlertMessage],[AlertDate],[DBTableColumnID],[PKDBTableColumnValue]' + CHAR(10);
				SET @SQLTEST += CHAR(9) + CHAR(9) + ')' + CHAR(10);
				SET @SQLTEST += CHAR(9) + CHAR(9) + 'VALUES(@Batch_ID, @SeverityWarning, ''Unable to run ' + @TestType + ' test for ' + @DBTableName + '.' + @DBTableColumnName + ': Is not null. Error - '' + ERROR_MESSAGE(), GETDATE(), NULL, NULL);' + CHAR(10);
				SET @SQLTEST += CHAR(9) + 'END CATCH' + CHAR(10);
				
			END
			
			IF (@TestType = 'IS NUMERIC')
			BEGIN

				SET @SQLTEST += CHAR(9) + '-- Column ' + @DBTableName + '.' + @DBTableColumnName + ' test: Is numeric' + CHAR(10);
				SET @SQLTEST += CHAR(9) + 'BEGIN TRY' + CHAR(10);
				SET @SQLTEST += CHAR(9) + CHAR(9) + 'INSERT INTO [MeDriAnchor].[EventAlerts]' + CHAR(10);
				SET @SQLTEST += CHAR(9) + CHAR(9) + '(' + CHAR(10);
				SET @SQLTEST += CHAR(9) + CHAR(9) + '[Batch_ID],[SeverityID],[AlertMessage],[AlertDate],[DBTableColumnID],[PKDBTableColumnValue]' + CHAR(10);
				SET @SQLTEST += CHAR(9) + CHAR(9) + ')' + CHAR(10);
				SET @SQLTEST += CHAR(9) + CHAR(9) + 'SELECT @Batch_ID, @SeverityValidation, ''The value '' + CONVERT(NVARCHAR(100), ' + @DWHTableColumnData + ') +' + ''' for this Attribute has failed testing: Is numeric'', GETDATE(), ' + CONVERT(VARCHAR(10), @DBTableColumnID) + ', ' + @AnchorIDColumn + CHAR(10);
				SET @SQLTEST += CHAR(9) + CHAR(9) + 'FROM ' + @DWHTableName + CHAR(10);
				SET @SQLTEST += CHAR(9) + CHAR(9) + 'WHERE (' + @MetadataColumn + ' = @Batch_ID' + CHAR(10);
				SET @SQLTEST += CHAR(9) + CHAR(9) + CHAR(9) + ' AND ISNUMERIC(' + @DWHTableColumnData + ') = 0);' + CHAR(10);
				SET @SQLTEST += CHAR(9) + 'END TRY' + CHAR(10);
				SET @SQLTEST += CHAR(9) + 'BEGIN CATCH' + CHAR(10);
				SET @SQLTEST += CHAR(9) + CHAR(9) + 'INSERT INTO [MeDriAnchor].[EventAlerts]' + CHAR(10);
				SET @SQLTEST += CHAR(9) + CHAR(9) + '(' + CHAR(10);
				SET @SQLTEST += CHAR(9) + CHAR(9) + '[Batch_ID],[SeverityID],[AlertMessage],[AlertDate],[DBTableColumnID],[PKDBTableColumnValue]' + CHAR(10);
				SET @SQLTEST += CHAR(9) + CHAR(9) + ')' + CHAR(10);
				SET @SQLTEST += CHAR(9) + CHAR(9) + 'VALUES(@Batch_ID, @SeverityWarning, ''Unable to run ' + @TestType + ' test for ' + @DBTableName + '.' + @DBTableColumnName + ': Is numeric. Error - '' + ERROR_MESSAGE(), GETDATE(), NULL, NULL);' + CHAR(10);
				SET @SQLTEST += CHAR(9) + 'END CATCH' + CHAR(10);

			END

			IF (@TestType = '<> (STRING)')
			BEGIN

				SET @SQLTEST += CHAR(9) + '-- Column ' + @DBTableName + '.' + @DBTableColumnName + ' test: String <> ' + CONVERT(VARCHAR(50), @TestValue1) + CHAR(10);
				SET @SQLTEST += CHAR(9) + 'BEGIN TRY' + CHAR(10);
				SET @SQLTEST += CHAR(9) + CHAR(9) + 'INSERT INTO [MeDriAnchor].[EventAlerts]' + CHAR(10);
				SET @SQLTEST += CHAR(9) + CHAR(9) + '(' + CHAR(10);
				SET @SQLTEST += CHAR(9) + CHAR(9) + '[Batch_ID],[SeverityID],[AlertMessage],[AlertDate],[DBTableColumnID],[PKDBTableColumnValue]' + CHAR(10);
				SET @SQLTEST += CHAR(9) + CHAR(9) + ')' + CHAR(10);
				SET @SQLTEST += CHAR(9) + CHAR(9) + 'SELECT @Batch_ID, @SeverityValidation, ''The value '' + CONVERT(NVARCHAR(100), ' + @DWHTableColumnData + ') +' + ''' for this Attribute has failed testing: String <> "' + CONVERT(VARCHAR(50), @TestValue1) + '"'', GETDATE(), ' + CONVERT(VARCHAR(10), @DBTableColumnID) + ', ' + @AnchorIDColumn + CHAR(10);
				SET @SQLTEST += CHAR(9) + CHAR(9) + 'FROM ' + @DWHTableName + CHAR(10);
				SET @SQLTEST += CHAR(9) + CHAR(9) + 'WHERE (' + @MetadataColumn + ' = @Batch_ID' + CHAR(10);
				SET @SQLTEST += CHAR(9) + CHAR(9) + CHAR(9) + ' AND ' + @DWHTableColumnData + ' = ''' + CONVERT(VARCHAR(50), @TestValue1) + ''');' + CHAR(10);
				SET @SQLTEST += CHAR(9) + 'END TRY' + CHAR(10);
				SET @SQLTEST += CHAR(9) + 'BEGIN CATCH' + CHAR(10);
				SET @SQLTEST += CHAR(9) + CHAR(9) + 'INSERT INTO [MeDriAnchor].[EventAlerts]' + CHAR(10);
				SET @SQLTEST += CHAR(9) + CHAR(9) + '(' + CHAR(10);
				SET @SQLTEST += CHAR(9) + CHAR(9) + '[Batch_ID],[SeverityID],[AlertMessage],[AlertDate],[DBTableColumnID],[PKDBTableColumnValue]' + CHAR(10);
				SET @SQLTEST += CHAR(9) + CHAR(9) + ')' + CHAR(10);
				SET @SQLTEST += CHAR(9) + CHAR(9) + 'VALUES(@Batch_ID, @SeverityWarning, ''Unable to run ' + @TestType + ' test for ' + @DBTableName + '.' + @DBTableColumnName + ': String <> "' + CONVERT(VARCHAR(50), @TestValue1) + '". Error - '' + ERROR_MESSAGE(), GETDATE(), NULL, NULL);' + CHAR(10);
				SET @SQLTEST += CHAR(9) + 'END CATCH' + CHAR(10);

			END
			
			IF (@TestType = 'ISVALID (LOOKUP STRING)')
			BEGIN

				SET @SQLTEST += CHAR(9) + '-- Column ' + @DBTableName + '.' + @DBTableColumnName + ' test: Is a valid lookup in ' 
					+ @LkpDBTable + '(' + @LkpDBTableColumn + ')' + CHAR(10);
				SET @SQLTEST += CHAR(9) + 'BEGIN TRY' + CHAR(10);
				SET @SQLTEST += CHAR(9) + CHAR(9) + 'INSERT INTO [MeDriAnchor].[EventAlerts]' + CHAR(10);
				SET @SQLTEST += CHAR(9) + CHAR(9) + '(' + CHAR(10);
				SET @SQLTEST += CHAR(9) + CHAR(9) + '[Batch_ID],[SeverityID],[AlertMessage],[AlertDate],[DBTableColumnID],[PKDBTableColumnValue]' + CHAR(10);
				SET @SQLTEST += CHAR(9) + CHAR(9) + ')' + CHAR(10);
				SET @SQLTEST += CHAR(9) + CHAR(9) + 'SELECT @Batch_ID, @SeverityValidation, ''The value '' + CONVERT(NVARCHAR(100), ' + @DWHTableColumnData + ') +' + ''' for this Attribute has failed testing: Is valid lookup in ' + @LkpDBTable + '(' + @LkpDBTableColumn + ')'', GETDATE(), ' + CONVERT(VARCHAR(10), @DBTableColumnID) + ', ' + @AnchorIDColumn + CHAR(10);
				SET @SQLTEST += CHAR(9) + CHAR(9) + 'FROM ' + @DWHTableName + CHAR(10);
				SET @SQLTEST += CHAR(9) + CHAR(9) + 'WHERE (' + @MetadataColumn + ' = @Batch_ID' + CHAR(10);
				SET @SQLTEST += CHAR(9) + CHAR(9) + CHAR(9) + ' AND REPLACE(RTRIM(LTRIM(' + @DWHTableColumnData + ')), CHAR(32), '''') NOT IN' + CHAR(10);
				SET @SQLTEST += CHAR(9) + CHAR(9) + CHAR(9) + CHAR(9) + ' (SELECT ' + @LkpDBTableColumn + ' FROM ' 
					+ @LkpDBTable + '));' + CHAR(10);
				SET @SQLTEST += CHAR(9) + 'END TRY' + CHAR(10);
				SET @SQLTEST += CHAR(9) + 'BEGIN CATCH' + CHAR(10);
				SET @SQLTEST += CHAR(9) + CHAR(9) + 'INSERT INTO [MeDriAnchor].[EventAlerts]' + CHAR(10);
				SET @SQLTEST += CHAR(9) + CHAR(9) + '(' + CHAR(10);
				SET @SQLTEST += CHAR(9) + CHAR(9) + '[Batch_ID],[SeverityID],[AlertMessage],[AlertDate],[DBTableColumnID],[PKDBTableColumnValue]' + CHAR(10);
				SET @SQLTEST += CHAR(9) + CHAR(9) + ')' + CHAR(10);
				SET @SQLTEST += CHAR(9) + CHAR(9) + 'VALUES(@Batch_ID, @SeverityWarning, ''Unable to run ' + @TestType + ' test for ' + @DBTableName + '.' + @DBTableColumnName + ': Is a valid lookup in ' 
					+ @LkpDBTable + '(' + @LkpDBTableColumn + '). Error - '' + ERROR_MESSAGE(), GETDATE(), NULL, NULL);' + CHAR(10);
				SET @SQLTEST += CHAR(9) + 'END CATCH' + CHAR(10);

			END

			IF (@TestType = '> (LENGTH STRING)')
			BEGIN

				SET @SQLTEST += CHAR(9) + '-- Column ' + @DBTableName + '.' + @DBTableColumnName + ' test: String length > ' + CONVERT(VARCHAR(50), @TestValue1) + CHAR(10);
				SET @SQLTEST += CHAR(9) + 'BEGIN TRY' + CHAR(10);
				SET @SQLTEST += CHAR(9) + CHAR(9) + 'INSERT INTO [MeDriAnchor].[EventAlerts]' + CHAR(10);
				SET @SQLTEST += CHAR(9) + CHAR(9) + '(' + CHAR(10);
				SET @SQLTEST += CHAR(9) + CHAR(9) + '[Batch_ID],[SeverityID],[AlertMessage],[AlertDate],[DBTableColumnID],[PKDBTableColumnValue]' + CHAR(10);
				SET @SQLTEST += CHAR(9) + CHAR(9) + ')' + CHAR(10);
				SET @SQLTEST += CHAR(9) + CHAR(9) + 'SELECT @Batch_ID, @SeverityValidation, ''The value '' + CONVERT(NVARCHAR(100), ' + @DWHTableColumnData + ') +' + ''' for this Attribute has failed testing: String length > ' + CONVERT(VARCHAR(50), @TestValue1) + ''', GETDATE(), ' + CONVERT(VARCHAR(10), @DBTableColumnID) + ', ' + @AnchorIDColumn + CHAR(10);
				SET @SQLTEST += CHAR(9) + CHAR(9) + 'FROM ' + @DWHTableName + CHAR(10);
				SET @SQLTEST += CHAR(9) + CHAR(9) + 'WHERE (' + @MetadataColumn + ' = @Batch_ID' + CHAR(10);
				SET @SQLTEST += CHAR(9) + CHAR(9) + CHAR(9) + ' AND LEN(' + @DWHTableColumnData + ') < ' + CONVERT(VARCHAR(50), @TestValue1) + ');' + CHAR(10);
				SET @SQLTEST += CHAR(9) + 'END TRY' + CHAR(10);
				SET @SQLTEST += CHAR(9) + 'BEGIN CATCH' + CHAR(10);
				SET @SQLTEST += CHAR(9) + CHAR(9) + 'INSERT INTO [MeDriAnchor].[EventAlerts]' + CHAR(10);
				SET @SQLTEST += CHAR(9) + CHAR(9) + '(' + CHAR(10);
				SET @SQLTEST += CHAR(9) + CHAR(9) + '[Batch_ID],[SeverityID],[AlertMessage],[AlertDate],[DBTableColumnID],[PKDBTableColumnValue]' + CHAR(10);
				SET @SQLTEST += CHAR(9) + CHAR(9) + ')' + CHAR(10);
				SET @SQLTEST += CHAR(9) + CHAR(9) + 'VALUES(@Batch_ID, @SeverityWarning, ''Unable to run ' + @TestType + ' test for ' + @DBTableName + '.' + @DBTableColumnName + ': String length > ' + CONVERT(VARCHAR(50), @TestValue1) + '. Error - '' + ERROR_MESSAGE(), GETDATE(), NULL, NULL);' + CHAR(10);
				SET @SQLTEST += CHAR(9) + 'END CATCH' + CHAR(10);

			END

			IF (@SQLTEST <> '')
				SET @SQL += @SQLTEST + CHAR(13);

		END
		FETCH NEXT FROM TESTSTORUN INTO @DBTableName, @DBTableColumnName, @DBTableColumnID, @DWHTableName, 
			@DWHTableColumnData, @TestType, @TestValue1, @TestValue2, @AnchorIDColumn, @MetadataColumn,
			@LkpDBTable, @LkpDBTableColumn, @AnchorID, @AnchorTable;
	END

	CLOSE TESTSTORUN;
	DEALLOCATE TESTSTORUN;

	--SET @SQL += '	COMMIT TRANSACTION;' + CHAR(13) + CHAR(13);
	SET @SQL += '	RETURN 0;' + CHAR(13) + CHAR(13);
	SET @SQL += 'END TRY' + CHAR(13) + CHAR(13);
	
	-- catch block
	SET @SQL += 'BEGIN CATCH' + CHAR(13) + CHAR(13);
	SET @SQL += '	DECLARE @ErrorMessage NVARCHAR(4000);' + CHAR(13);
	SET @SQL += '	DECLARE @ErrorSeverity INT;' + CHAR(13);
	SET @SQL += '	DECLARE @ErrorState INT;' + CHAR(13) + CHAR(13);
	SET @SQL += CHAR(9) + 'SELECT @ErrorMessage = ERROR_PROCEDURE() + '': '' + ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();' + CHAR(13) + CHAR(13);
	SET @SQL += '	RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);' + CHAR(13) + CHAR(13);
	--SET @SQL += '	ROLLBACK TRANSACTION;' + CHAR(13) + CHAR(13); 
	-- log an error record
	SET @SQL += '	INSERT INTO [MeDriAnchor].[EventAlerts]([Batch_ID],[SeverityID],[AlertMessage])' + CHAR(13);
	SET @SQL += '	VALUES(@Batch_ID, 4, ''Error with DWH Testing procedure. Error: '' + @ErrorMessage + '''');' + CHAR(13) + CHAR(13);
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
GO
