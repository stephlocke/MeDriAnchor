CREATE PROCEDURE [MeDriAnchor].[sspCreateTieETLSQL]
(
	@TieName SYSNAME,
	@Batch_ID BIGINT,
	@Metadata_ID BIGINT,
	@Environment_ID SMALLINT,
	@Debug BIT = 0,
	@StageData BIT = 1,
	@ProcName SYSNAME = '' OUTPUT
)
AS
SET NOCOUNT ON;
/*
GENERATES THE SQL FOR THE CREATE OF AN Tie ETL SQL PROCEDURE
*/
DECLARE @SQL NVARCHAR(MAX) = '';
DECLARE @ProcNamePrefix NVARCHAR(20) = 'amsp_Tie_';
DECLARE @ProcNamePostfix NVARCHAR(20) = '_ETLSQL_Run';
DECLARE @DestinationDB SYSNAME;
DECLARE @SourceDB SYSNAME;
DECLARE @DBName SYSNAME;
DECLARE @PkColumns NVARCHAR(MAX) = '';
DECLARE @PkColumnsNullCheck NVARCHAR(MAX) = '';
DECLARE @PkColumnsAnnex NVARCHAR(MAX) = '';
DECLARE @PkColumnsDest NVARCHAR(MAX) = '';
DECLARE @METAColumn SYSNAME;
DECLARE @IsHistorised BIT;
DECLARE @DateRestrictionColumn SYSNAME;
DECLARE @DateRestrictionColumn2 SYSNAME;
DECLARE @positingSuffix NVARCHAR(100);
DECLARE @positorSuffix NVARCHAR(100);
DECLARE @reliabilitySuffix NVARCHAR(100);
DECLARE @TableTieSchema SYSNAME;
DECLARE @TableTiePrefix SYSNAME;
DECLARE @temporalization NVARCHAR(100);
DECLARE @DWHTableColumnChangedAt SYSNAME;
DECLARE @identity_type NVARCHAR(100);
DECLARE @identitySuffix NVARCHAR(100);
DECLARE @DWHTableName NVARCHAR(1000);
DECLARE @annexSuffix NVARCHAR(100);
DECLARE @positSuffix NVARCHAR(100);
DECLARE @DWHColumns NVARCHAR(MAX) = '';
DECLARE @SourceColumns NVARCHAR(MAX) = '';
DECLARE @FromClause NVARCHAR(MAX) = '';
DECLARE @FromClausePK NVARCHAR(MAX) = '';
DECLARE @encapsulation NVARCHAR(100) = '';

DECLARE @Tie TABLE 
(
	[DBName] SYSNAME,
	[DBTableSchema] SYSNAME,
	[DBTableName] SYSNAME, 
	[DWHDBTableSchema] SYSNAME,
	[DWHDBTableName] NVARCHAR(1000),
	[DWHDBTableNameBase] NVARCHAR(1000),
	[TableAlias] NVARCHAR(3),
	[TieDBColumnName] SYSNAME,
	[SourceDBColumnName] SYSNAME,
	[SourcePKColumnName] SYSNAME,
	[TieJoinOrder] SMALLINT,
	[TieJoinColumn] SYSNAME,
	[IsHistorised] BIT,
	[DateRestrictionColumn] SYSNAME,
	[DWHTableColumnMeta] SYSNAME,
	[DWHTableColumnChangedAt] SYSNAME,
	[IsTextColumn] BIT
);

BEGIN TRY

	-- get the naming info we need
	SELECT	@ProcNamePrefix = [TieETLProcNamePrefix],
			@ProcNamePostfix = [ETLProcNamePostfix]
	FROM [MeDriAnchor].[svExtProps];

	SELECT	@positingSuffix = MAX(CASE WHEN s.[SettingKey] = 'positingSuffix' THEN COALESCE(se.[SettingValue], s.[SettingValue]) ELSE '' END),
			@positorSuffix = MAX(CASE WHEN s.[SettingKey] = 'positorSuffix' THEN COALESCE(se.[SettingValue], s.[SettingValue]) ELSE '' END),
			@reliabilitySuffix = MAX(CASE WHEN s.[SettingKey] = 'reliabilitySuffix' THEN COALESCE(se.[SettingValue], s.[SettingValue]) ELSE '' END),
			@temporalization = MAX(CASE WHEN s.[SettingKey] = 'temporalization' THEN COALESCE(se.[SettingValue], s.[SettingValue]) ELSE '' END),
			@identity_type = MAX(CASE WHEN s.[SettingKey] = 'identity' THEN COALESCE(se.[SettingValue], s.[SettingValue]) ELSE '' END),
			@identitySuffix = MAX(CASE WHEN s.[SettingKey] = 'identitySuffix' THEN COALESCE(se.[SettingValue], s.[SettingValue]) ELSE '' END),
			@annexSuffix = MAX(CASE WHEN s.[SettingKey] = 'annexSuffix' THEN COALESCE(se.[SettingValue], s.[SettingValue]) ELSE '' END),
			@positSuffix = MAX(CASE WHEN s.[SettingKey] = 'positSuffix' THEN COALESCE(se.[SettingValue], s.[SettingValue]) ELSE '' END),
			@encapsulation = MAX(CASE WHEN s.[SettingKey] = 'encapsulation' THEN COALESCE(se.[SettingValue], s.[SettingValue]) ELSE '' END)
	FROM [MeDriAnchor].[Settings] s
	LEFT OUTER JOIN [MeDriAnchor].[SettingsEnvironment] se
		ON s.[SettingKey] = se.[SettingKey]
		AND se.Environment_ID = @Environment_ID
	WHERE s.[SettingKey] IN('positingSuffix', 'positorSuffix', 'reliabilitySuffix', 'temporalization', 
		'identity', 'identitySuffix', 'annexSuffix', 'positSuffix', 'encapsulation');

	-- get the destination db to use
	SELECT @DestinationDB = QUOTENAME([DBName])
	FROM [MeDriAnchor].[DB]
	WHERE [DBIsDestination] = 1;

	INSERT INTO @Tie
		(
		[DBName],
		[DBTableSchema],
		[DBTableName],
		[DWHDBTableSchema],
		[DWHDBTableName],
		[DWHDBTableNameBase],
		[TableAlias],
		[TieDBColumnName],
		[SourceDBColumnName],
		[SourcePKColumnName],
		[TieJoinOrder],
		[TieJoinColumn],
		[IsHistorised],
		[DateRestrictionColumn],
		[DWHTableColumnMeta],
		[DWHTableColumnChangedAt],
		[IsTextColumn]
		)
	SELECT	[DBName],
			[DBTableSchema],
			[DBTableName],
			[DWHDBTableSchema],
			[DWHDBTableName],
			[DWHDBTableNameBase],
			[TableAlias],
			[TieDBColumnName],
			[SourceDBColumnName],
			[SourcePKColumnName],
			[TieJoinOrder],
			[TieJoinColumn],
			[IsHistorised],
			[DateRestrictionColumn],
			[DWHTableColumnMeta],
			[DWHTableColumnChangedAt],
			[IsTextColumn]
	FROM [MeDriAnchor].[fnGetTieETLMetadata](@TieName, @Environment_ID)
	ORDER BY [TieJoinOrder] DESC, [TableAlias];

	-- get the metadata (batch) column, whether it's a historised atribute, and its Tie prefix
	SELECT TOP 1
			@METAColumn = QUOTENAME([DWHTableColumnMeta]),
			@IsHistorised = [IsHistorised],
			@TableTieSchema = QUOTENAME([DWHDBTableSchema]),
			@TableTiePrefix = [DWHDBTableNameBase],
			@DWHTableColumnChangedAt = [DWHTableColumnChangedAt],
			@DateRestrictionColumn = (CASE WHEN [DateRestrictionColumn] = '' THEN '' ELSE [TableAlias] + '.' + QUOTENAME([DateRestrictionColumn]) END),
			@DBName = QUOTENAME([DBName]),
			@DWHTableName = [DWHDBTableName]
	FROM @Tie
	WHERE [TieJoinOrder] = 1;

	SELECT TOP 1
			@DateRestrictionColumn2 = (CASE WHEN [DateRestrictionColumn] = '' THEN '' ELSE [TableAlias] + '.' + QUOTENAME([DateRestrictionColumn]) END)
	FROM @Tie
	WHERE [TieJoinOrder] = 2;

	-- if a self-join tie, append a two to the second table alias
	IF EXISTS (SELECT * FROM @Tie t1 WHERE t1.[TieJoinOrder] = 1 AND t1.[TableAlias] = 
		(SELECT t2.[TableAlias] FROM @Tie t2 WHERE t2.[TieJoinOrder] = 2 AND t2.[TableAlias] = t1.[TableAlias]))
	BEGIN
		UPDATE @Tie SET [TableAlias] = 't12'
		WHERE [TieJoinOrder] = 2;
	END

	-- get the destination column list
	SELECT @DWHColumns += '		' + QUOTENAME([TieDBColumnName])  + ',' + CHAR(10)
	FROM @Tie
	SET @DWHColumns = SUBSTRING(@DWHColumns, 1, LEN(@DWHColumns) - 2);

	-- get the source columns list
	SELECT @SourceColumns += '		' + [TableAlias] + '.' + QUOTENAME([SourcePKColumnName])  + ',' + CHAR(10)
	FROM @Tie
	SET @SourceColumns = SUBSTRING(@SourceColumns, 1, LEN(@SourceColumns) - 2);

	-- build the from clause (main join)
	SELECT @FromClause += 
		(CASE 
			WHEN t1.[TieJoinOrder] = 1 
			THEN '	FROM ' + t1.[DBTableName]  + ' ' + t1.[TableAlias] + CHAR(10)
			ELSE '	INNER JOIN ' + t1.[DBTableName]  + ' ' + t1.[TableAlias] + CHAR(10)
				+ '		ON ' +  t2.[TableAlias] + '.' + QUOTENAME(COALESCE(NULLIF(t2.[TieJoinColumn], ''), t2.[SourceDBColumnName]))
					+ ' = ' + t1.[TableAlias] + '.' + QUOTENAME(COALESCE(NULLIF(t1.[TieJoinColumn], ''), NULLIF(t2.[TieJoinColumn], ''), t2.[SourceDBColumnName])) 
					+ (CASE WHEN t1.[IsTextColumn] = 1 THEN ' COLLATE DATABASE_DEFAULT ' ELSE '' END) + CHAR(10)
		END)
	FROM @Tie t1
	LEFT OUTER JOIN @Tie t2
		ON t2.[TieJoinOrder] = t1.[TieJoinOrder] - 1
	WHERE t1.[TieJoinOrder] > 0
	ORDER BY t1.[TieJoinOrder];
	SET @FromClause = SUBSTRING(@FromClause, 1, LEN(@FromClause) - 1);
	SET @FromClause += CHAR(13);

	-- build the from clause (pk check)
	SELECT @FromClausePK +=
		CHAR(9) + 'INNER JOIN '+ [DWHTableName] + ' ' + t.[TableAlias] + '_PK' + CHAR(13)
		+ CHAR(9) + CHAR(9) + 'ON ' + [TableAlias] + '_PK.' + [DWHTableColumnData] + ' = ' + t.[TableAlias] + '.' + t.[SourcePKColumnName] + CHAR(13)
	FROM @Tie t
	INNER JOIN [MeDriAnchor].[_AnchorToMetadataMap] md
		ON t.[TableAlias] = md.AnchorMnemonic
	WHERE t.[TieJoinOrder] > 0
		AND [Metadata_ID] = @Metadata_ID
		AND [Environment_ID] = @Environment_ID
		AND [DWHType] = 'Anchor'
	ORDER BY t.[TieJoinOrder];
	SET @FromClausePK = SUBSTRING(@FromClausePK, 1, LEN(@FromClausePK) - 1);

	-- amalgamate the from clauses
	SET @FromClause = @FromClause + @FromClausePK;

	-- get the primary key comparison for existence check
	SELECT @PkColumns += QUOTENAME([TieDBColumnName]) + ' = ' + [TableAlias] + '.' + QUOTENAME([SourcePKColumnName])  + ' AND '
	FROM @Tie
	SET @PkColumns = SUBSTRING(@PkColumns, 1, LEN(@PkColumns) - 4);

	SELECT @PkColumnsNullCheck += [TableAlias] + '.' + QUOTENAME([SourcePKColumnName])  + ' IS NOT NULL AND '
	FROM @Tie
	SET @PkColumnsNullCheck = SUBSTRING(@PkColumnsNullCheck, 1, LEN(@PkColumnsNullCheck) - 4);

	SELECT @PkColumnsAnnex += QUOTENAME([TieDBColumnName]) + ' = s.' + QUOTENAME([SourcePKColumnName])  + ' AND '
	FROM @Tie
	SET @PkColumnsAnnex = SUBSTRING(@PkColumnsAnnex, 1, LEN(@PkColumnsAnnex) - 4);

	SET @ProcName = '[' + @encapsulation + '].[' + @ProcNamePrefix + @TableTiePrefix + @ProcNamePostfix + ']';

	-- generate the run procedure
	IF NOT EXISTS(SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_SCHEMA = @encapsulation
		AND ROUTINE_NAME = @ProcNamePrefix + @TableTiePrefix + @ProcNamePostfix)
	BEGIN
		SET @SQL += 'CREATE PROC [' + @encapsulation + '].[' + @ProcNamePrefix + @TableTiePrefix + @ProcNamePostfix + ']' + CHAR(13);
	END
	ELSE
	BEGIN
		SET @SQL += 'ALTER PROC [' + @encapsulation + '].[' + @ProcNamePrefix + @TableTiePrefix + @ProcNamePostfix + ']' + CHAR(13);
	END
	SET @SQL += '(' + CHAR(13);
	SET @SQL += '@Batch_ID BIGINT,' + CHAR(13);
	SET @SQL += '@BatchDate DATETIME,' + CHAR(13);
	SET @SQL += '@PreviousBatchDate DATETIME,' + CHAR(13);
	SET @SQL += '@Environment_ID SMALLINT,' + CHAR(13);
	SET @SQL += '@Metadata_ID BIGINT' + CHAR(13);
	SET @SQL += ')' + CHAR(13);
	SET @SQL += 'AS' + CHAR(13);
	SET @SQL += '' + CHAR(13);
	SET @SQL += 'SET XACT_ABORT ON;' + CHAR(13);
	SET @SQL += 'SET NOCOUNT ON;' + CHAR(13);
	SET @SQL += '' + CHAR(13);
	
	-- YAML metadata here
	SET @SQL += '/**' + CHAR(13);
	SET @SQL += 'revisions:' + CHAR(13);
	SET @SQL += ' - author: anchwiz' + CHAR(13);
	SET @SQL += '	date: ' + CONVERT(VARCHAR(11), GETDATE(), 106) + CHAR(13);
	SET @SQL += 'summary:	>' + CHAR(13);
	SET @SQL += '				ETL for Tie ' + @TableTiePrefix + CHAR(13);
	SET @SQL += ' - code:	EXEC [' + @encapsulation + '].[' + @ProcNamePrefix + @TableTiePrefix + @ProcNamePostfix + ']' + CHAR(13);
	SET @SQL += '	parameters: @Batch_ID BIGINT, @BatchDate DATETIME, @PreviousBatchDate DATETIME, and @Environment_ID SMALLINT' + CHAR(13);
	SET @SQL += '	returns: 0 if success, otherwise -1' + CHAR(13);
	SET @SQL += '	generated using Metadata_ID: ' + CONVERT(NVARCHAR(10), @Metadata_ID) 
		+ ' - Batch_ID: ' + CONVERT(NVARCHAR(10), @Batch_ID) + ' - Environment_ID: ' 
		+ CONVERT(NVARCHAR(10), @Environment_ID) + CHAR(13);
	SET @SQL += '**/' + CHAR(13) + CHAR(13);

	-- locl variable declarations
	SET @SQL += 'DECLARE @RecordsInserted BIGINT;' + CHAR(13);
	SET @SQL += 'DECLARE @Rowcount BIGINT;' + CHAR(13) + CHAR(13);

	-- body
	--SET @SQL += 'BEGIN TRANSACTION;' + CHAR(13) + CHAR(13);
	SET @SQL += 'BEGIN TRY' + CHAR(13) + CHAR(13);

	-- code the insert

	IF (@DateRestrictionColumn <> '')
	BEGIN
		-- a date comparison, so check if we have records in the table (as if not we need to not do the restriction - e.e. on the first run
		SET @SQL += CHAR(9) + 'SET @Rowcount = (SELECT COUNT(*) FROM ' + @DWHTableName + ');' + CHAR(13) + CHAR(13);
	END

	IF (@StageData = 0)
	BEGIN

		-- non staged insert (one part)
		SET @SQL += CHAR(9) + 'INSERT INTO ' + @DWHTableName + CHAR(13);
		SET @SQL += CHAR(9) + CHAR(9) + '(' + CHAR(13);
		SET @SQL += @DWHColumns
		IF (@IsHistorised = 1)
		BEGIN
			SET @SQL += ',' + CHAR(13) + CHAR(9) + CHAR(9) + QUOTENAME(@DWHTableColumnChangedAt) + ',' + CHAR(13);
		END
		ELSE
		BEGIN
			SET @SQL += ',' + CHAR(13)
		END
		SET @SQL += CHAR(9) + CHAR(9) + @METAColumn + CHAR(13);
		SET @SQL += CHAR(9) + CHAR(9) + ')' + CHAR(13);
		SET @SQL += CHAR(9) + 'SELECT' + CHAR(13);
		SET @SQL += @SourceColumns
		IF (@IsHistorised = 1)
		BEGIN
			SET @SQL += ',' + CHAR(13) + CHAR(9) + CHAR(9) + '@BatchDate,' + CHAR(13);
		END
		ELSE
		BEGIN
			SET @SQL += ',' + CHAR(13);
		END
		SET @SQL += CHAR(9) + CHAR(9) + '@Batch_ID' + CHAR(13);
		SET @SQL += @FromClause + CHAR(13);

		SET @SQL += CHAR(9) + 'WHERE (' + @PkColumnsNullCheck + ')' + CHAR(13)
	
		-- add the date restriction if we have one and a previous batch date
		IF (@DateRestrictionColumn <> '' AND @DateRestrictionColumn2 <> '')
		BEGIN
			-- a date comparison, so add this into the where (where we have a date to compare against)
			SET @SQL += CHAR(9) + CHAR(9) + 'AND (@Rowcount = 0 OR @PreviousBatchDate IS NULL OR (' + @DateRestrictionColumn + ' > @PreviousBatchDate ';
			SET @SQL += CHAR(9) + CHAR(9) + ' OR ' + @DateRestrictionColumn2 + ' > @PreviousBatchDate))' + CHAR(13)
			SET @SQL += CHAR(9) + CHAR(9) + 'AND NOT EXISTS ' + CHAR(13)
			SET @SQL += CHAR(9) + CHAR(9) + '(' + CHAR(13)
			SET @SQL += CHAR(9) + CHAR(9) + 'SELECT * FROM ' + @DWHTableName + CHAR(13)
			SET @SQL += CHAR(9) + CHAR(9) + 'WHERE ' + @PkColumns + CHAR(13)
			SET @SQL += CHAR(9) + CHAR(9) + ') OPTION (RECOMPILE);' + CHAR(13) + CHAR(13);
		END
		ELSE
		BEGIN
			-- no date comparison, so do a standard not exists
			SET @SQL += CHAR(9) + CHAR(9) + 'AND NOT EXISTS ' + CHAR(13)
			SET @SQL += CHAR(9) + CHAR(9) + '(' + CHAR(13)
			SET @SQL += CHAR(9) + CHAR(9) + 'SELECT * FROM ' + @DWHTableName + CHAR(13)
			SET @SQL += CHAR(9) + CHAR(9) + 'WHERE ' + @PkColumns + CHAR(13)
			SET @SQL += CHAR(9) + CHAR(9) + ') OPTION(RECOMPILE);' + CHAR(13) + CHAR(13);
		END

		-- record the number of rows inserted
		SET @SQL += CHAR(9) + 'SET @RecordsInserted = @@ROWCOUNT;' + CHAR(13) + CHAR(13);

	END
	ELSE
	BEGIN

		-- staged insert (two parts)

		-- first into a hash table
		SET @SQL += CHAR(9) + 'SELECT' + CHAR(13);
		SET @SQL += @SourceColumns
		IF (@IsHistorised = 1)
		BEGIN
			SET @SQL += ',' + CHAR(13) + CHAR(9) + CHAR(9) + '@BatchDate AS ' + QUOTENAME(@DWHTableColumnChangedAt) + ',' + CHAR(13);
		END
		ELSE
		BEGIN
			SET @SQL += ',' + CHAR(13);
		END
		SET @SQL += CHAR(9) + CHAR(9) + '@Batch_ID AS ' + @METAColumn + CHAR(13);
		SET @SQL += CHAR(9) + 'INTO #' + REPLACE(REPLACE(@DWHTableName, '[', ''), ']', '') + CHAR(13);
		SET @SQL += @FromClause + CHAR(13);

		SET @SQL += CHAR(9) + 'WHERE (' + @PkColumnsNullCheck + ')';
	
		-- add the date restriction if we have one and a previous batch date
		IF (@DateRestrictionColumn <> '')
		BEGIN
			-- a date comparison, so add this into the where (where we have a date to compare against)
			SET @SQL += CHAR(13) + CHAR(9) + CHAR(9) + 'AND (@Rowcount = 0 OR @PreviousBatchDate IS NULL OR ' + @DateRestrictionColumn + ' > @PreviousBatchDate) OPTION (RECOMPILE);' + CHAR(13) + CHAR(13);
		END
		ELSE
		BEGIN
			SET @SQL += ' OPTION (RECOMPILE);' + CHAR(13) + CHAR(13);
		END

		-- TODO: TESTING HERE

		-- then into the DWH
		SET @SQL += CHAR(9) + 'INSERT INTO ' + @DWHTableName + CHAR(13);
		SET @SQL += CHAR(9) + CHAR(9) + '(' + CHAR(13);
		SET @SQL += @DWHColumns
		IF (@IsHistorised = 1)
		BEGIN
			SET @SQL += ',' + CHAR(13) + CHAR(9) + CHAR(9) + QUOTENAME(@DWHTableColumnChangedAt) + ',' + CHAR(13);
		END
		ELSE
		BEGIN
			SET @SQL += ',' + CHAR(13)
		END
		SET @SQL += CHAR(9) + CHAR(9) + @METAColumn + CHAR(13);
		SET @SQL += CHAR(9) + CHAR(9) + ')' + CHAR(13);
		SET @SQL += CHAR(9) + 'SELECT' + CHAR(13);
		SET @SQL += @DWHColumns
		IF (@IsHistorised = 1)
		BEGIN
			SET @SQL += ',' + CHAR(13) + CHAR(9) + CHAR(9) + QUOTENAME(@DWHTableColumnChangedAt) + ',' + CHAR(13);
		END
		ELSE
		BEGIN
			SET @SQL += ',' + CHAR(13)
		END
		SET @SQL += CHAR(9) + CHAR(9) + @METAColumn + CHAR(13);
		SET @SQL += CHAR(9) + 'FROM #' + REPLACE(REPLACE(@DWHTableName, '[', ''), ']', '') + ' s' + CHAR(13);
		SET @SQL += CHAR(9) + 'WHERE NOT EXISTS ' + CHAR(13)
		SET @SQL += CHAR(9) + CHAR(9) + '(' + CHAR(13)
		SET @SQL += CHAR(9) + CHAR(9) + 'SELECT * FROM ' + @DWHTableName + CHAR(13)
		SET @SQL += CHAR(9) + CHAR(9) + 'WHERE ' + @PkColumns + CHAR(13)
		SET @SQL += CHAR(9) + CHAR(9) + ') OPTION (RECOMPILE);' + CHAR(13) + CHAR(13);

		-- record the number of rows inserted
		SET @SQL += CHAR(9) + 'SET @RecordsInserted = @@ROWCOUNT;' + CHAR(13) + CHAR(13);

		SET @SQL += CHAR(9) + 'DROP TABLE #' + REPLACE(REPLACE(@DWHTableName, '[', ''), ']', '') + ';' + CHAR(13) + CHAR(13);

	END

	-- log an audit record
	SET @SQL += CHAR(9) + 'INSERT INTO [MeDriAnchor].[EventAlerts]([Batch_ID],[SeverityID],[AlertMessage],[RecordsInserted])' + CHAR(13);
	SET @SQL += CHAR(9) + 'VALUES(@Batch_ID, 1, ''Completed ETL for Tie ' + @TieName + ''', @RecordsInserted);' + CHAR(13) + CHAR(13);

	--SET @SQL += CHAR(9) + 'COMMIT TRANSACTION;' + CHAR(13) + CHAR(13);
	SET @SQL += CHAR(9) + 'RETURN 0;' + CHAR(13) + CHAR(13);
	SET @SQL += 'END TRY' + CHAR(13) + CHAR(13);
	
	-- catch block
	SET @SQL += 'BEGIN CATCH' + CHAR(13) + CHAR(13);
	SET @SQL += CHAR(9) + 'DECLARE @ErrorMessage NVARCHAR(4000);' + CHAR(13);
	SET @SQL += CHAR(9) + 'DECLARE @ErrorSeverity INT;' + CHAR(13);
	SET @SQL += CHAR(9) + 'DECLARE @ErrorState INT;' + CHAR(13) + CHAR(13);
	SET @SQL += CHAR(9) + 'SELECT @ErrorMessage = ERROR_PROCEDURE() + '': '' + ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();' + CHAR(13) + CHAR(13);
	SET @SQL += CHAR(9) + 'RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);' + CHAR(13) + CHAR(13);
	--SET @SQL += CHAR(9) + 'ROLLBACK TRANSACTION;' + CHAR(13) + CHAR(13); 
	-- log an error record
	SET @SQL += CHAR(9) + 'INSERT INTO [MeDriAnchor].[EventAlerts]([Batch_ID],[SeverityID],[AlertMessage])' + CHAR(13);
	SET @SQL += CHAR(9) + 'VALUES(@Batch_ID, 4, ''Error with ETL for Tie ' + @TieName + '. Error: '' + @ErrorMessage + '''');' + CHAR(13) + CHAR(13);
	SET @SQL += CHAR(9) + 'RETURN -1;' + CHAR(13) + CHAR(13);
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