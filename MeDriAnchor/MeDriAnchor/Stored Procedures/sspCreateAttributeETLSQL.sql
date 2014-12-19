CREATE PROCEDURE [MeDriAnchor].[sspCreateAttributeETLSQL]
(
	@AttributeName SYSNAME,
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
DECLARE @annexSuffix NVARCHAR(100);
DECLARE @positSuffix NVARCHAR(100);
DECLARE @encapsulation NVARCHAR(100);
DECLARE @positingSuffix NVARCHAR(100);
DECLARE @positorSuffix NVARCHAR(100);
DECLARE @reliabilitySuffix NVARCHAR(100);
DECLARE @temporalization NVARCHAR(100);
DECLARE @identity_type NVARCHAR(100);
DECLARE @identitySuffix NVARCHAR(100);
DECLARE @changingSuffix NVARCHAR(100);
DECLARE @metadataPrefix NVARCHAR(100);
DECLARE @METAColumn SYSNAME;
DECLARE @DateRestrictionColumn SYSNAME;
DECLARE @DWHTableName SYSNAME;
DECLARE @DBTableName SYSNAME;
DECLARE @IsHistorised BIT;
DECLARE @IsTextColumn BIT;
DECLARE @IsMaterialisedColumn BIT;
DECLARE @MaterialisedColumnFunction SYSNAME;
DECLARE @ChangedAtColumn SYSNAME;
DECLARE @AttributeMnemonic NVARCHAR(100);
DECLARE @AnchorMnemonic NVARCHAR(100);
DECLARE @GenerateID BIT;
DECLARE @AnchorDWHTableName SYSNAME;
DECLARE @AnchorDWHTableColumn SYSNAME;
DECLARE @AnchorDBTableColumn SYSNAME;

DECLARE @Attribute TABLE 
	(
	[ATMM_ID] BIGINT NOT NULL,
	[DBTableSchema] SYSNAME NOT NULL,
	[DBTableName] SYSNAME NOT NULL,
	[DBTableColumnName] SYSNAME NOT NULL,
	[DWHTableName] SYSNAME NOT NULL,
	[DWHTableColumnData] SYSNAME NOT NULL,
	[JoinOrder] SMALLINT NULL,
	[JoinColumn] SYSNAME NOT NULL,
	[JoinAlias] NVARCHAR(7) NULL,
	[DWHType] NVARCHAR(20) NULL,
	[DWHName] SYSNAME NOT NULL,
	[AttributeMnemonic] NVARCHAR(100) NULL,
	[AnchorMnemonic] NVARCHAR(100) NULL,
	[KnotRange] NVARCHAR(7) NULL,
	[PKColumn] BIT NULL,
	[DateRestrictionColumn] SYSNAME NOT NULL,
	[IsTextColumn] BIT NULL,
	[IsMaterialisedColumn] BIT NULL,
	[MaterialisedColumnFunction] SYSNAME NOT NULL,
	[IsHistorised] BIT,
	[GenerateID] BIT
	);

DECLARE @Anchor TABLE 
	(
	[ATMM_ID] BIGINT NOT NULL,
	[DBTableSchema] SYSNAME NOT NULL,
	[DBTableName] SYSNAME NOT NULL,
	[DBTableColumnName] SYSNAME NOT NULL,
	[DWHTableName] SYSNAME NOT NULL,
	[DWHTableColumnData] SYSNAME NOT NULL,
	[JoinOrder] SMALLINT NULL,
	[JoinColumn] SYSNAME NOT NULL,
	[JoinAlias] NVARCHAR(7) NULL,
	[DWHType] NVARCHAR(20) NULL,
	[DWHName] SYSNAME NOT NULL,
	[AnchorMnemonic] NVARCHAR(7) NULL,
	[KnotRange] NVARCHAR(7) NULL,
	[PKColumn] BIT NULL,
	[DateRestrictionColumn] SYSNAME NOT NULL,
	[IsTextColumn] BIT NULL,
	[IsMaterialisedColumn] BIT NULL,
	[MaterialisedColumnFunction] SYSNAME NOT NULL,
	[GenerateID] BIT
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
			@encapsulation = MAX(CASE WHEN s.[SettingKey] = 'encapsulation' THEN COALESCE(se.[SettingValue], s.[SettingValue]) ELSE '' END),
			@changingSuffix = MAX(CASE WHEN s.[SettingKey] = 'changingSuffix' THEN COALESCE(se.[SettingValue], s.[SettingValue]) ELSE '' END),
			@metadataPrefix = MAX(CASE WHEN s.[SettingKey] = 'metadataPrefix' THEN COALESCE(se.[SettingValue], s.[SettingValue]) ELSE '' END)
	FROM [MeDriAnchor].[Settings] s
	LEFT OUTER JOIN [MeDriAnchor].[SettingsEnvironment] se
		ON s.[SettingKey] = se.[SettingKey]
		AND se.Environment_ID = @Environment_ID
	WHERE s.[SettingKey] IN('positingSuffix', 'positorSuffix', 'reliabilitySuffix', 'temporalization', 
		'identity', 'identitySuffix', 'annexSuffix', 'positSuffix', 'encapsulation', 'changingSuffix', 'metadataPrefix');

	INSERT INTO @Attribute
		(
		[ATMM_ID],
		[DBTableSchema],
		[DBTableName],
		[DBTableColumnName],
		[DWHTableName],
		[DWHTableColumnData],
		[JoinOrder],
		[JoinColumn],
		[JoinAlias],
		[DWHType],
		[DWHName],
		[AttributeMnemonic],
		[AnchorMnemonic],
		[KnotRange],
		[PKColumn],
		[DateRestrictionColumn],
		[IsTextColumn],
		[IsMaterialisedColumn],
		[MaterialisedColumnFunction],
		[IsHistorised],
		[GenerateID]
		)
	SELECT	[ATMM_ID],
			[DBTableSchema],
			[DBTableName],
			[DBTableColumnName],
			[DWHTableName],
			[DWHTableColumnData],
			[JoinOrder],
			[JoinColumn],
			[JoinAlias],
			[DWHType],
			[DWHName],
			[AttributeMnemonic],
			[AnchorMnemonic],
			[KnotRange],
			[PKColumn],
			[DateRestrictionColumn],
			[IsTextColumn],
			[IsMaterialisedColumn],
			[MaterialisedColumnFunction],
			[IsHistorised],
			[GenerateID]
	FROM [MeDriAnchor].[_AnchorToMetadataMap]
	WHERE [Metadata_ID] = @Metadata_ID
		AND [Environment_ID] = @Environment_ID
		AND [DWHType] = 'Attribute'
		AND [DWHName] = @AttributeName;

	-- get the working variables we need
	SELECT	@METAColumn = MAX(QUOTENAME(@metadataPrefix + '_' + [AnchorMnemonic] + '_' + [AttributeMnemonic])),
			@DWHTableName = MAX([DWHTableName]),
			@DBTableName = MAX([DBTableName]),
			@DateRestrictionColumn = MAX([DateRestrictionColumn]),
			@IsHistorised = MAX(CONVERT(TINYINT, [IsHistorised])),
			@IsTextColumn = MAX(CONVERT(TINYINT, [IsTextColumn])),
			@IsMaterialisedColumn = MAX(CONVERT(TINYINT, [IsMaterialisedColumn])),
			@MaterialisedColumnFunction = MAX([MaterialisedColumnFunction]),
			@ChangedAtColumn = MAX(QUOTENAME([AnchorMnemonic] + '_' + [AttributeMnemonic] + '_' + @changingSuffix)),
			@AttributeMnemonic = MAX([AttributeMnemonic]),
			@AnchorMnemonic = MAX([AnchorMnemonic]),
			@GenerateID = MAX(CONVERT(TINYINT, [GenerateID]))
	FROM @Attribute;

	INSERT INTO @Anchor
		(
		[ATMM_ID],
		[DBTableSchema],
		[DBTableName],
		[DBTableColumnName],
		[DWHTableName],
		[DWHTableColumnData],
		[JoinOrder],
		[JoinColumn],
		[JoinAlias],
		[DWHType],
		[DWHName],
		[AnchorMnemonic],
		[KnotRange],
		[PKColumn],
		[DateRestrictionColumn],
		[IsTextColumn],
		[IsMaterialisedColumn],
		[MaterialisedColumnFunction]
		)
	SELECT	[ATMM_ID],
			[DBTableSchema],
			[DBTableName],
			[DBTableColumnName],
			[DWHTableName],
			[DWHTableColumnData],
			[JoinOrder],
			[JoinColumn],
			[JoinAlias],
			[DWHType],
			[DWHName],
			[AnchorMnemonic],
			[KnotRange],
			[PKColumn],
			[DateRestrictionColumn],
			[IsTextColumn],
			[IsMaterialisedColumn],
			[MaterialisedColumnFunction]
	FROM [MeDriAnchor].[_AnchorToMetadataMap]
	WHERE [Metadata_ID] = @Metadata_ID
		AND [Environment_ID] = @Environment_ID
		AND [DWHType] = 'Anchor'
		AND [AnchorMnemonic] = @AnchorMnemonic;

	-- get the anchor details for the pk existence check
	SELECT	@AnchorDWHTableName = [DWHTableName],
			@AnchorDWHTableColumn = [DWHTableColumnData],
			@AnchorDBTableColumn = [DBTableColumnName]
	FROM @Anchor;

	SET @ProcName = '[' + @encapsulation + '].[' + @ProcNamePrefix + @AttributeName + @ProcNamePostfix + ']';

	-- generate the run procedure
	IF NOT EXISTS(SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_SCHEMA = @encapsulation
		AND ROUTINE_NAME = @ProcNamePrefix + @AttributeName + @ProcNamePostfix)
	BEGIN
		SET @SQL += 'CREATE PROC [' + @encapsulation + '].[' + @ProcNamePrefix + @AttributeName + @ProcNamePostfix + ']' + CHAR(13);
	END
	ELSE
	BEGIN
		SET @SQL += 'ALTER PROC [' + @encapsulation + '].[' + @ProcNamePrefix + @AttributeName + @ProcNamePostfix + ']' + CHAR(13);
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
	SET @SQL += '				ETL for attribute ' + @AttributeName + CHAR(13);
	SET @SQL += ' - code:	EXEC [' + @encapsulation + '].[' + @ProcNamePrefix + @AttributeName + @ProcNamePostfix + ']' + CHAR(13);
	SET @SQL += '	parameters: @Batch_ID BIGINT, @BatchDate DATETIME, @PreviousBatchDate DATETIME, and @Environment_ID SMALLINT' + CHAR(13);
	SET @SQL += '	returns: 0 if success, otherwise -1' + CHAR(13);
	SET @SQL += '	generated using Metadata_ID: ' + CONVERT(NVARCHAR(10), @Metadata_ID) 
		+ ' - Batch_ID: ' + CONVERT(NVARCHAR(10), @Batch_ID) + ' - Environment_ID: ' 
		+ CONVERT(NVARCHAR(10), @Environment_ID) + CHAR(13);
	SET @SQL += '**/' + CHAR(13) + CHAR(13);

	-- local variable declarations
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

		-- non staged insert (one part)
		SET @SQL += CHAR(9) + 'INSERT INTO ' + @DWHTableName + CHAR(13);
		SET @SQL += CHAR(9) + CHAR(9) +  '(' + CHAR(13);
		SET @SQL += CHAR(9) + CHAR(9) +  QUOTENAME(@AnchorMnemonic + '_' + @AttributeMnemonic + '_' + @AnchorMnemonic + '_' + @identitySuffix) + ',';
		SET @SQL += STUFF((SELECT ',' + [DWHTableColumnData]
					FROM @Attribute
					FOR XML PATH('')), 1, 1, '');
		IF (@IsHistorised = 1)
		BEGIN
			SET @SQL += ',' + @ChangedAtColumn;
		END
		IF (@temporalization <> 'crt')
		BEGIN
			SET @SQL += ',' + @METAColumn + CHAR(13);
		END
		SET @SQL += CHAR(9) + CHAR(9) + ')' + CHAR(13);
		SET @SQL += CHAR(9) + 'SELECT' + CHAR(13);
		SET @SQL += CHAR(9) + CHAR(9) + STUFF((SELECT ',' + [DBTableColumnName]
					FROM @Anchor
					FOR XML PATH('')), 1, 1, '') + ',';
		SET @SQL += STUFF((SELECT ',' + (CASE WHEN [IsMaterialisedColumn] = 0 THEN [DBTableColumnName] ELSE [MaterialisedColumnFunction] END)
					FROM @Attribute
					FOR XML PATH('')), 1, 1, '');
		IF (@IsHistorised = 1)
		BEGIN
			SET @SQL += ',@BatchDate';
		END
		IF (@temporalization <> 'crt')
		BEGIN
			SET @SQL += ',@Batch_ID';
		END
		SET @SQL += CHAR(13) + CHAR(9) + 'FROM ' + @DBTableName + ' s' + CHAR(13);
		SET @SQL += CHAR(9) + 'INNER JOIN ' + @AnchorDWHTableName + ' pk' + CHAR(13);
		SET @SQL += CHAR(9) + CHAR(9) + 'ON pk.' + @AnchorDWHTableColumn + ' = s.' + @AnchorDBTableColumn + CHAR(13);
		SET @SQL += CHAR(9) + 'WHERE' + CHAR(13);
		SET @SQL += CHAR(9) + CHAR(9) + STUFF((SELECT 'AND ' + [DBTableColumnName] + ' IS NOT NULL AND '
					FROM @Attribute
					FOR XML PATH('')), 1, 4, '') + CHAR(13);

		--- add the date restriction if we have one and a previous batch date
		IF (@DateRestrictionColumn <> '')
		BEGIN
			-- a date comparison, so add this into the where (where we have a date to compare against)
			SET @SQL += CHAR(9) + CHAR(9) + '(@Rowcount = 0 OR @PreviousBatchDate IS NULL OR ' + @DateRestrictionColumn + ' > @PreviousBatchDate) AND ' + CHAR(13)
		END
		SET @SQL += CHAR(9) + CHAR(9) + 'NOT EXISTS ' + CHAR(13)
		SET @SQL += CHAR(9) + CHAR(9) + '(' + CHAR(13)
		SET @SQL += CHAR(9) + CHAR(9) + 'SELECT * FROM ' + @DWHTableName + CHAR(13)
		SET @SQL += CHAR(9) + CHAR(9) + 'WHERE' + STUFF((SELECT ' AND ' + QUOTENAME(@AnchorMnemonic + '_' + @AttributeMnemonic + '_' + @AnchorMnemonic + '_' + @identitySuffix) + ' = s.' + [DBTableColumnName]
														+ (CASE WHEN [IsTextColumn] = 1 THEN ' COLLATE DATABASE_DEFAULT ' ELSE '' END)
														FROM @Anchor
														FOR XML PATH('')), 1, 4, '') + CHAR(13);
		SET @SQL += CHAR(9) + CHAR(9) + CHAR(9) + 'AND ' + STUFF((SELECT ' AND ' + [DWHTableColumnData] + (CASE WHEN [IsMaterialisedColumn] = 0 THEN ' = s.' + [DBTableColumnName] ELSE ' = ' + [MaterialisedColumnFunction] END)
														+ (CASE WHEN [IsTextColumn] = 1 THEN ' COLLATE DATABASE_DEFAULT ' ELSE '' END)
														FROM @Attribute
														FOR XML PATH('')), 1, 4, '') + CHAR(13);
		SET @SQL += CHAR(9) + CHAR(9) + ') OPTION(RECOMPILE);' + CHAR(13) + CHAR(13);

		-- record the number of rows inserted
		SET @SQL += CHAR(9) + 'SET @RecordsInserted = @@ROWCOUNT;' + CHAR(13) + CHAR(13);

	END
	ELSE
	BEGIN

		-- staged insert (two parts)

		-- first into a hash table
		SET @SQL += CHAR(9) + 'SELECT' + CHAR(13);
		SET @SQL += CHAR(9) + CHAR(9) + STUFF((SELECT ',' + [DBTableColumnName]
					FROM @Anchor
					FOR XML PATH('')), 1, 1, '') + ',';
		SET @SQL += STUFF((SELECT ',' + (CASE WHEN [IsMaterialisedColumn] = 0 THEN [DBTableColumnName] ELSE [MaterialisedColumnFunction] END)
					FROM @Attribute
					FOR XML PATH('')), 1, 1, '');
		IF (@IsHistorised = 1)
		BEGIN
			SET @SQL += ',@BatchDate AS ' + @ChangedAtColumn;
		END
		IF (@temporalization <> 'crt')
		BEGIN
			SET @SQL += ',@Batch_ID AS ' + @METAColumn;
		END
		SET @SQL += CHAR(13) + CHAR(9) + 'INTO #' + REPLACE(REPLACE(@DWHTableName, '[', ''), ']', '') + CHAR(13);
		SET @SQL += CHAR(9) + 'FROM ' + @DBTableName + ' s' + CHAR(13);
		SET @SQL += CHAR(9) + 'INNER JOIN ' + @AnchorDWHTableName + ' pk' + CHAR(13);
		SET @SQL += CHAR(9) + CHAR(9) + 'ON pk.' + @AnchorDWHTableColumn + ' = s.' + @AnchorDBTableColumn + CHAR(13);
		SET @SQL += CHAR(9) + 'WHERE' + CHAR(13);
		SET @SQL += CHAR(9) + CHAR(9) + STUFF((SELECT 'AND ' + [DBTableColumnName] + ' IS NOT NULL'
					FROM @Attribute
					FOR XML PATH('')), 1, 4, '');

		--- add the date restriction if we have one and a previous batch date
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
		SET @SQL += CHAR(9) + CHAR(9) +  '(' + CHAR(13);
		SET @SQL += CHAR(9) + CHAR(9) +  QUOTENAME(@AnchorMnemonic + '_' + @AttributeMnemonic + '_' + @AnchorMnemonic + '_' + @identitySuffix) + ',';
		SET @SQL += STUFF((SELECT ',' + [DWHTableColumnData]
					FROM @Attribute
					FOR XML PATH('')), 1, 1, '');
		IF (@IsHistorised = 1)
		BEGIN
			SET @SQL += ',' + @ChangedAtColumn;
		END
		IF (@temporalization <> 'crt')
		BEGIN
			SET @SQL += ',' + @METAColumn + CHAR(13);
		END
		SET @SQL += CHAR(9) + CHAR(9) + ')' + CHAR(13);
		SET @SQL += CHAR(9) + 'SELECT' + CHAR(13);
		SET @SQL += CHAR(9) + CHAR(9) + STUFF((SELECT ',' + [DBTableColumnName]
					FROM @Anchor
					FOR XML PATH('')), 1, 1, '') + ',';
		SET @SQL += STUFF((SELECT ',' + (CASE WHEN [IsMaterialisedColumn] = 0 THEN [DBTableColumnName] ELSE [MaterialisedColumnFunction] END)
					FROM @Attribute
					FOR XML PATH('')), 1, 1, '');
		IF (@IsHistorised = 1)
		BEGIN
			SET @SQL += ',' +@ChangedAtColumn;
		END
		IF (@temporalization <> 'crt')
		BEGIN
			SET @SQL += ',' + @METAColumn;
		END
		SET @SQL += CHAR(13) + CHAR(9) + 'FROM #' + REPLACE(REPLACE(@DWHTableName, '[', ''), ']', '') + ' s' + CHAR(13);
		SET @SQL += CHAR(9) + 'WHERE NOT EXISTS ' + CHAR(13)
		SET @SQL += CHAR(9) + CHAR(9) + '(' + CHAR(13)
		SET @SQL += CHAR(9) + CHAR(9) + 'SELECT * FROM ' + @DWHTableName + CHAR(13);
		SET @SQL += CHAR(9) + CHAR(9) + 'WHERE' + STUFF((SELECT ' AND ' + QUOTENAME(@AnchorMnemonic + '_' + @AttributeMnemonic + '_' + @AnchorMnemonic + '_' + @identitySuffix) + ' = s.' + [DBTableColumnName]
														+ (CASE WHEN [IsTextColumn] = 1 THEN ' COLLATE DATABASE_DEFAULT ' ELSE '' END)
														FROM @Anchor
														FOR XML PATH('')), 1, 4, '') + CHAR(13);
		SET @SQL += CHAR(9) + CHAR(9) + CHAR(9) + 'AND ' + STUFF((SELECT ' AND ' + [DWHTableColumnData] + (CASE WHEN [IsMaterialisedColumn] = 0 THEN ' = s.' + [DBTableColumnName] ELSE ' = ' + [MaterialisedColumnFunction] END)
														+ (CASE WHEN [IsTextColumn] = 1 THEN ' COLLATE DATABASE_DEFAULT ' ELSE '' END)
														FROM @Attribute
														FOR XML PATH('')), 1, 4, '') + CHAR(13);
		SET @SQL += CHAR(9) + CHAR(9) + ') OPTION (RECOMPILE);' + CHAR(13) + CHAR(13);

		-- record the number of rows inserted
		SET @SQL += CHAR(9) + 'SET @RecordsInserted = @@ROWCOUNT;' + CHAR(13) + CHAR(13);

		SET @SQL += CHAR(9) + 'DROP TABLE #' + REPLACE(REPLACE(@DWHTableName, '[', ''), ']', '') + ';' + CHAR(13) + CHAR(13);

	END

	-- log an audit record
	SET @SQL += CHAR(9) + 'INSERT INTO [MeDriAnchor].[EventAlerts]([Batch_ID],[SeverityID],[AlertMessage],[RecordsInserted])' + CHAR(13);
	SET @SQL += CHAR(9) + 'VALUES(@Batch_ID, 1, ''Completed ETL for Attribute ' + @AttributeName + ''', @RecordsInserted);' + CHAR(13) + CHAR(13);

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