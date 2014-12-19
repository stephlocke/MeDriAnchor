CREATE PROCEDURE [MeDriAnchor].[sspCreateAttributeKnotETLSQL]
(
	@AttributeName SYSNAME,
	@KnotName SYSNAME,
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
GENERATES THE SQL FOR THE CREATE OF AN ATTRIBUTE ETL SQL PROCEDURE
*/
DECLARE @SQL NVARCHAR(MAX) = '';
DECLARE @ProcNamePrefix NVARCHAR(20) = 'amsp_Attribute_';
DECLARE @ProcNamePostfix NVARCHAR(20) = '_ETLSQL_Run';
DECLARE @DestinationDB SYSNAME;
DECLARE @SourceDB SYSNAME;
DECLARE @AttributeFromSource NVARCHAR(MAX) = '';
DECLARE @PkColumns NVARCHAR(MAX) = '';
DECLARE @PkColumnsDest NVARCHAR(MAX) = '';
DECLARE @METAColumn SYSNAME;
DECLARE @IsHistorised BIT;
DECLARE @DateRestrictionColumn SYSNAME;
DECLARE @positingSuffix NVARCHAR(100);
DECLARE @positorSuffix NVARCHAR(100);
DECLARE @reliabilitySuffix NVARCHAR(100);
DECLARE @TableAttributePrefix NVARCHAR(50);
DECLARE @temporalization NVARCHAR(100);
DECLARE @DWHTableColumnDataID SYSNAME;
DECLARE @DWHTableColumnData SYSNAME;
DECLARE @DWHTableColumnChangedAt SYSNAME;
DECLARE @identity_type NVARCHAR(100);
DECLARE @identitySuffix NVARCHAR(100);
DECLARE @DWHTableName SYSNAME;
DECLARE @annexSuffix NVARCHAR(100);
DECLARE @positSuffix NVARCHAR(100);
DECLARE @encapsulation NVARCHAR(100);
DECLARE @DBTableSchema SYSNAME;
DECLARE @DBTableName SYSNAME;
DECLARE @DBTableColumnName SYSNAME;
DECLARE @PKDBTableColumnName SYSNAME;
DECLARE @IsTextColumn BIT;
DECLARE @IsMaterialisedColumn BIT;
DECLARE @MaterialisedColumnFunction SYSNAME;
DECLARE @KnotPrefix SYSNAME;
DECLARE @KnotPKDBTableColumnNameDest SYSNAME;
DECLARE @KnotPKDBTableColumnNameSource SYSNAME;
DECLARE @KnotDBTableColumnNameDest SYSNAME;
DECLARE @KnotDBTableColumnNameSource SYSNAME;
DECLARE @KnotPKDBTableName SYSNAME;
DECLARE @KnotDBTableSchema SYSNAME;
DECLARE @KnotDBTableName SYSNAME;
DECLARE @KnotDBTableColumn SYSNAME;
DECLARE @FromSQL NVARCHAR(MAX) = '';
DECLARE @KnotJoinColumn SYSNAME;
DECLARE @GenerateID BIT;
DECLARE @AnchorMnemonic NVARCHAR(7);
DECLARE @AnchorDWHTableName SYSNAME;
DECLARE @AnchorDWHTableColumn SYSNAME;
DECLARE @AnchorDBTableColumn SYSNAME;

DECLARE @Attribute TABLE 
(
	[DBName] SYSNAME,
	[DBTableColumnID] BIGINT, 
	[DBTableSchema] SYSNAME,
	[DBTableName] SYSNAME, 
	[IsHistorised] BIT,
	[DWHTableName] SYSNAME,
	[DWHTableColumnDataID] SYSNAME,
	[DWHTableColumnData] SYSNAME,
	[DBTableColumnName] SYSNAME,
	[DWHTableColumnChangedAt] SYSNAME,
	[DWHTableColumnMeta] SYSNAME,
	[PKColumn] BIT,
	[PKColOrdinal] TINYINT,
	[PKDBTableColumnName] SYSNAME,
	[DateRestrictionColumn] SYSNAME,
	[TableAttributePrefix] NVARCHAR(50),
	[IsTextColumn] BIT,
	[IsMaterialisedColumn] BIT,
	[MaterialisedColumnFunction] SYSNAME,
	[AnchorMnemonic] NVARCHAR(7)
);

DECLARE @Knot TABLE 
(
	[DBName] SYSNAME,
	[DBTableColumnID] BIGINT, 
	[DBTableSchema] SYSNAME,
	[DBTableName] SYSNAME, 
	[DBTableColumnName] SYSNAME,
	[DWHTableName] SYSNAME,
	[DWHTableColumnData] SYSNAME,
	[DWHTableColumnMeta] SYSNAME,
	[PKColumn] BIT,
	[PKColOrdinal] TINYINT,
	[DateRestrictionColumn] SYSNAME,
	[KnotJoinColumn] SYSNAME,
	[GenerateID] BIT
);

DECLARE @Anchor TABLE 
	(
	[DWHTableName] SYSNAME NOT NULL,
	[DWHTableColumnData] SYSNAME NOT NULL,
	[DBTableColumnName] SYSNAME NOT NULL
	);

BEGIN TRY

	-- get the naming info we need
	SELECT	@ProcNamePrefix = [AttributeETLProcNamePrefix],
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
	SELECT @DestinationDB = [DBName]
	FROM [MeDriAnchor].[DB]
	WHERE [DBIsDestination] = 1;

	INSERT INTO @Attribute
		(
		[DBName],
		[DBTableColumnID],
		[DBTableSchema],
		[DBTableName],
		[IsHistorised],
		[DWHTableName],
		[DWHTableColumnDataID],
		[DWHTableColumnData],
		[DBTableColumnName],
		[DWHTableColumnChangedAt],
		[DWHTableColumnMeta],
		[PKColumn],
		[PKColOrdinal],
		[PKDBTableColumnName],
		[DateRestrictionColumn],
		[TableAttributePrefix],
		[IsTextColumn],
		[IsMaterialisedColumn],
		[MaterialisedColumnFunction],
		[AnchorMnemonic]
		)
	SELECT	[DBName],
			[DBTableColumnID],
			[DBTableSchema],
			[DBTableName],
			[IsHistorised],
			[DWHTableName],
			[DWHTableColumnDataID],
			[DWHTableColumnData],
			[DBTableColumnName],
			[DWHTableColumnChangedAt],
			[DWHTableColumnMeta],
			[PKColumn],
			[PKColOrdinal],
			[PKDBTableColumnName],
			[DateRestrictionColumn],
			[TableAttributePrefix],
			[IsTextColumn],
			[IsMaterialisedColumn],
			[MaterialisedColumnFunction],
			[AnchorMnemonic]
	FROM [MeDriAnchor].[fnGetAttributeETLMetadata](@AttributeName, @Environment_ID);

	INSERT INTO @Knot
		(
		[DBName],
		[DBTableColumnID],
		[DBTableSchema],
		[DBTableName],
		[DBTableColumnName],
		[DWHTableName],
		[DWHTableColumnData],
		[DWHTableColumnMeta],
		[PKColumn],
		[PKColOrdinal],
		[DateRestrictionColumn],
		[KnotJoinColumn],
		[GenerateID]
		)
	SELECT	[DBName],
			[DBTableColumnID],
			[DBTableSchema],
			[DBTableName],
			[DBTableColumnName],
			[DWHTableName],
			[DWHTableColumnData],
			[DWHTableColumnMeta],
			[PKColumn],
			[PKColOrdinal],
			[DateRestrictionColumn],
			[KnotJoinColumn],
			[GenerateID]
	FROM [MeDriAnchor].[fnGetKnotETLMetadata](@KnotName, @Environment_ID);

	-- get the metadata (batch) column, whether it's a historised atribute, its attribute prefix, the two column names needed (fk and attribute)
	SELECT TOP 1
			@METAColumn = QUOTENAME([DWHTableColumnMeta]),
			@IsHistorised = [IsHistorised],
			@TableAttributePrefix = [TableAttributePrefix],
			@DWHTableColumnDataID = [DWHTableColumnDataID],
			@DWHTableColumnData = [DWHTableColumnData],
			@DWHTableColumnChangedAt = [DWHTableColumnChangedAt],
			@DWHTableName = [DWHTableName],
			@SourceDB = QUOTENAME([DBName]),
			@DBTableSchema = QUOTENAME([DBTableSchema]),
			@DBTableName = [DBTableName],
			@DBTableColumnName = QUOTENAME(DBTableColumnName),
			@PKDBTableColumnName = QUOTENAME(PKDBTableColumnName),
			@IsTextColumn = [IsTextColumn],
			@IsMaterialisedColumn = [IsMaterialisedColumn],
			@MaterialisedColumnFunction = [MaterialisedColumnFunction],
			@AnchorMnemonic = [AnchorMnemonic]
	FROM @Attribute;

	SELECT	@KnotPKDBTableColumnNameDest = [DWHTableColumnData],
			@KnotPKDBTableColumnNameSource = [DBTableColumnName],
			@KnotPKDBTableName = [DWHTableName],
			@KnotDBTableSchema  = [DBTableSchema],
			@KnotDBTableName = [DBTableName],
			@KnotDBTableColumn = [DBTableColumnName],
			@KnotJoinColumn = [KnotJoinColumn],
			@GenerateID = [GenerateID]
	FROM @Knot
	WHERE [PKColumn] = 1;

	SELECT	@KnotDBTableColumnNameDest = [DWHTableColumnData],
			@KnotDBTableColumnNameSource = [DBTableColumnName]
	FROM @Knot
	WHERE [PKColumn] = 0;

	-- do we have a date restriction column?
	SELECT TOP 1
			@DateRestrictionColumn = [DateRestrictionColumn]
	FROM @Attribute;

	-- get the anchor details for the pk check
	INSERT INTO @Anchor
		(
		[DWHTableName],
		[DWHTableColumnData],
		[DBTableColumnName]
		)
	SELECT	[DWHTableName],
			[DWHTableColumnData],
			[DBTableColumnName]
	FROM [MeDriAnchor].[_AnchorToMetadataMap]
	WHERE [Metadata_ID] = @Metadata_ID
		AND [Environment_ID] = @Environment_ID
		AND [DWHType] = 'Anchor'
		AND [AnchorMnemonic] = @AnchorMnemonic;

	SELECT	@AnchorDWHTableName = [DWHTableName],
			@AnchorDWHTableColumn = [DWHTableColumnData],
			@AnchorDBTableColumn = [DBTableColumnName]
	FROM @Anchor;

	-- get the primary key comparison for existence check

	-- for the not exists where
	SELECT @PkColumns += QUOTENAME(@DWHTableColumnDataID) + ' = sa.' + @PKDBTableColumnName
		+ (CASE WHEN @IsTextColumn = 1 THEN ' COLLATE DATABASE_DEFAULT' ELSE '' END) + ' AND '
	FROM @Attribute
	WHERE [PKColumn] = 1
	ORDER BY [PKColOrdinal];
	SELECT @PkColumns += QUOTENAME(@TableAttributePrefix + @KnotPKDBTableColumnNameDest) + ' = sk.' + QUOTENAME(@KnotPKDBTableColumnNameSource)  
		+ (CASE WHEN @IsTextColumn = 1 THEN ' COLLATE DATABASE_DEFAULT' ELSE '' END)
	FROM @Knot
	WHERE [PKColumn] = 1
	ORDER BY [PKColOrdinal];

	SET @ProcName = '[' + @encapsulation + '].[' + @ProcNamePrefix + @AttributeName + @ProcNamePostfix + ']';

	-- generate the from clause
	SET @FromSQL += CHAR(9) + 'FROM ' + QUOTENAME(@DBTableName) + ' sa' + CHAR(13);
	SET @FromSQL += CHAR(9) + 'INNER JOIN ' + @AnchorDWHTableName + ' pk' + CHAR(13);
	SET @FromSQL += CHAR(9) + CHAR(9) + 'ON pk.' + @AnchorDWHTableColumn + ' = sa.' + @AnchorDBTableColumn + CHAR(13);
	SET @FromSQL += CHAR(9) + 'INNER JOIN ' + @KnotDBTableName + ' sk' + CHAR(13);
	SET @FromSQL += CHAR(9) + CHAR(9) + 'ON sa.' + QUOTENAME(COALESCE(NULLIF(@KnotJoinColumn, ''), @KnotPKDBTableColumnNameSource)) + ' = sk.' + QUOTENAME(@KnotPKDBTableColumnNameSource) + CHAR(13);

	-- generate the run procedure
	IF NOT EXISTS(SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_SCHEMA = @encapsulation
		AND ROUTINE_NAME = @ProcNamePrefix + @AttributeName + @ProcNamePostfix)
	BEGIN
		SET @SQL += 'CREATE PROC [' + @encapsulation + '].[' + @ProcNamePrefix + @AttributeName + @ProcNamePostfix + ']' + CHAR(13);
	END
	ELSE
	BEGIN
		SET @SQL += 'ALTER PROC [' + @encapsulation + '].[' + @ProcNamePrefix + @AttributeName + @ProcNamePostfix + ']' + CHAR(13)
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
	SET @SQL += ' - author: MeDriAnchor' + CHAR(13);
	SET @SQL += '	date: ' + CONVERT(VARCHAR(11), GETDATE(), 106) + CHAR(13);
	SET @SQL += 'summary:	>' + CHAR(13);
	SET @SQL += '				ETL for Attribute ' + @AttributeName + CHAR(13);
	SET @SQL += ' - code:	EXEC [' + @encapsulation + '].[' + @ProcNamePrefix + @AttributeName + @ProcNamePostfix + ']' + CHAR(13);
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
	
	IF (@DateRestrictionColumn <> '')
	BEGIN
		-- a date comparison, so check if we have records in the table (as if not we need to not do the restriction - e.e. on the first run
		SET @SQL += CHAR(9) + 'SET @Rowcount = (SELECT COUNT(*) FROM ' + @DWHTableName + ');' + CHAR(13) + CHAR(13);
	END

	-- code the insert
	
	IF (@StageData = 0)
	BEGIN

		-- insert only for now
		SET @SQL += CHAR(9) + 'INSERT INTO ' + @DWHTableName + CHAR(13);
		SET @SQL += CHAR(9) + CHAR(9) + '(' + CHAR(13);
		SET @SQL += CHAR(9) + CHAR(9) + QUOTENAME(@DWHTableColumnDataID) + ',' + CHAR(13);
		SET @SQL += CHAR(9) + CHAR(9) + QUOTENAME(@TableAttributePrefix + @KnotPKDBTableColumnNameDest) + ',' + CHAR(13);
		IF (@IsHistorised = 1)
		BEGIN
			SET @SQL += CHAR(9) + CHAR(9) + QUOTENAME(@DWHTableColumnChangedAt) + ',' + CHAR(13);
		END
		SET @SQL += CHAR(9) + CHAR(9) + @METAColumn + CHAR(13);
		SET @SQL += CHAR(9) + CHAR(9) + ')' + CHAR(13);
		SET @SQL += CHAR(9) + '	SELECT' + CHAR(13);
		SET @SQL += CHAR(9) + CHAR(9) + 'sa.' + @PKDBTableColumnName + ',' + CHAR(13);
		SET @SQL += CHAR(9) + CHAR(9) + 'sk.' + QUOTENAME(@KnotPKDBTableColumnNameSource) + ',' + CHAR(13);
		IF (@IsHistorised = 1)
		BEGIN
			SET @SQL += CHAR(9) + CHAR(9) + '@BatchDate,' + CHAR(13);
		END
		SET @SQL += CHAR(9) + CHAR(9) + '@Batch_ID' + CHAR(13);
		SET @SQL += @FromSQL;

		-- add the date restriction if we have one and a previous batch date
		IF (@DateRestrictionColumn <> '')
		BEGIN
			-- a date comparison, so add this into the where (where we have a date to compare against)
			SET @SQL += CHAR(9) + 'WHERE (@Rowcount = 0 OR @PreviousBatchDate IS NULL OR sa.' + QUOTENAME(@DateRestrictionColumn) + ' > @PreviousBatchDate)' + CHAR(13)
			SET @SQL += CHAR(9) + CHAR(9) + 'AND NOT EXISTS ' + CHAR(13)
			SET @SQL += CHAR(9) + CHAR(9) + '(' + CHAR(13)
			SET @SQL += CHAR(9) + CHAR(9) + 'SELECT * FROM ' + @DWHTableName + CHAR(13)
			SET @SQL += CHAR(9) + CHAR(9) + 'WHERE ' + @PkColumns + CHAR(13)
			SET @SQL += CHAR(9) + CHAR(9) + ') OPTION (RECOMPILE);' + CHAR(13) + CHAR(13);
		END
		ELSE
		BEGIN
			-- no date comparison, so do a standard not exists
			SET @SQL += CHAR(9) + 'WHERE sk.' + QUOTENAME(@KnotPKDBTableColumnNameSource) + ' IS NOT NULL AND NOT EXISTS ' + CHAR(13)
			SET @SQL += CHAR(9) + '(' + CHAR(13)
			SET @SQL += CHAR(9) + 'SELECT * FROM ' + @DWHTableName + CHAR(13)
			SET @SQL += CHAR(9) + 'WHERE ' + @PkColumns + CHAR(13)
			SET @SQL += CHAR(9) + ');' + CHAR(13) + CHAR(13);
		END

		-- record the number of rows inserted
		SET @SQL += CHAR(9) + 'SET @RecordsInserted = @@ROWCOUNT;' + CHAR(13) + CHAR(13);

	END
	ELSE
	BEGIN

		-- staged insert (two parts)

		-- first into a hash table
		SET @SQL += CHAR(9) + 'SELECT' + CHAR(13);
		SET @SQL += CHAR(9) + CHAR(9) + 'sa.' + @PKDBTableColumnName + ',';
		SET @SQL += 'sk.' + QUOTENAME(@KnotPKDBTableColumnNameSource);
		IF (@IsHistorised = 1)
		BEGIN
			SET @SQL += ',@BatchDate AS ' + QUOTENAME(@DWHTableColumnChangedAt) + ',';
		END
		SET @SQL += '@Batch_ID' + @METAColumn + CHAR(13);
		SET @SQL += CHAR(9) + 'INTO #' + REPLACE(REPLACE(@DWHTableName, '[', ''), ']', '');
		SET @SQL += @FromSQL;

		-- add the date restriction if we have one and a previous batch date
		IF (@DateRestrictionColumn <> '')
		BEGIN
			-- a date comparison, so add this into the where (where we have a date to compare against)
			SET @SQL += CHAR(9) + 'WHERE (@Rowcount = 0 OR @PreviousBatchDate IS NULL OR sa.' + QUOTENAME(@DateRestrictionColumn) + ' > @PreviousBatchDate) OPTION (RECOMPILE);' + CHAR(13) + CHAR(13);
		END
		ELSE
		BEGIN
			SET @SQL += ' OPTION (RECOMPILE);' + CHAR(13) + CHAR(13);
		END

		-- TODO: TESTING HERE

		-- then into the DWH
		SET @SQL += CHAR(9) + 'INSERT INTO ' + @DWHTableName + CHAR(13);
		SET @SQL += CHAR(9) + CHAR(9) + '(' + CHAR(13);
		SET @SQL += CHAR(9) + CHAR(9) + QUOTENAME(@DWHTableColumnDataID) + ',' + CHAR(13);
		SET @SQL += CHAR(9) + CHAR(9) + QUOTENAME(@TableAttributePrefix + @KnotPKDBTableColumnNameDest) + ',' + CHAR(13);
		IF (@IsHistorised = 1)
		BEGIN
			SET @SQL += CHAR(9) + CHAR(9) + QUOTENAME(@DWHTableColumnChangedAt) + ',' + CHAR(13);
		END
		SET @SQL += CHAR(9) + CHAR(9) + @METAColumn + CHAR(13);
		SET @SQL += CHAR(9) + CHAR(9) + ')' + CHAR(13);
		SET @SQL += CHAR(9) + 'SELECT' + CHAR(13);
		SET @SQL += CHAR(9) + CHAR(9) + 'sa.' + @PKDBTableColumnName + ',';
		SET @SQL += 'sk.' + QUOTENAME(@KnotPKDBTableColumnNameSource);
		IF (@IsHistorised = 1)
		BEGIN
			SET @SQL += ',' + QUOTENAME(@DWHTableColumnChangedAt) + ',';
		END
		SET @SQL += @METAColumn + CHAR(13);
		SET @SQL += CHAR(9) + 'FROM #' + REPLACE(REPLACE(@DWHTableName, '[', ''), ']', '') + ' s' + CHAR(13);
		SET @SQL += CHAR(9) + 'WHERE NOT EXISTS ' + CHAR(13)
		SET @SQL += CHAR(9) + CHAR(9) + '(' + CHAR(13)
		SET @SQL += CHAR(9) + CHAR(9) + 'SELECT * FROM ' + @DWHTableName + CHAR(13)
		SET @SQL += CHAR(9) + CHAR(9) + 'WHERE ' + REPLACE(REPLACE(@PkColumns, 'sa.', 's.'), 'sk.', 's.') + CHAR(13)
		SET @SQL += CHAR(9) + CHAR(9) + ') OPTION (RECOMPILE);' + CHAR(13) + CHAR(13);

		-- record the number of rows inserted
		SET @SQL += CHAR(9) + 'SET @RecordsInserted = @@ROWCOUNT;' + CHAR(13) + CHAR(13);

		SET @SQL += CHAR(9) + 'DROP TABLE #' + REPLACE(REPLACE(@DWHTableName, '[', ''), ']', '') + ';' + CHAR(13) + CHAR(13);

	END

	-- log an audit record
	SET @SQL += CHAR(9) + 'INSERT INTO [MeDriAnchor].[EventAlerts]([Batch_ID],[SeverityID],[AlertMessage],[RecordsInserted])' + CHAR(13);
	SET @SQL += CHAR(9) + 'VALUES(@Batch_ID, 1, ''Completed ETL for Attribute (Knotted) ' + @AttributeName + ''', @RecordsInserted);' + CHAR(13) + CHAR(13);

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
	SET @SQL += CHAR(9) + 'VALUES(@Batch_ID, 4, ''Error with ETL for Attribute ' + @AttributeName + '. Error: '' + @ErrorMessage + '''');' + CHAR(13) + CHAR(13);
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
