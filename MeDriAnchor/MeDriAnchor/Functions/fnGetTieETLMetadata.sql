CREATE FUNCTION [MeDriAnchor].[fnGetTieETLMetadata]
(
@TieName SYSNAME,
@Environment_ID SMALLINT
)
RETURNS @Tie TABLE 
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
	[CreateNCIndexInDWH] BIT,
	[GenerateID] BIT,
	[IsTextColumn] BIT,
	[DBTableColumnID] BIGINT
)
AS
BEGIN

	DECLARE @metadataPrefix NVARCHAR(100);
	DECLARE @encapsulation NVARCHAR(100);
	DECLARE @identitySuffix NVARCHAR(100);
	DECLARE @changingSuffix NVARCHAR(100);
	DECLARE @positSuffix NVARCHAR(100);
	DECLARE @temporalization NVARCHAR(100);
	DECLARE @TieMnemonic NVARCHAR(20);
	DECLARE @DestinationDB SYSNAME;

	SELECT @DestinationDB = [DBName]
	FROM [MeDriAnchor].[DB]
	WHERE [DBIsDestination] = 1
		AND ([Environment_ID] = @Environment_ID OR [Environment_ID] IS NULL);

	-- Translate the tie name into our Mnemonic
	SELECT @TieMnemonic = [TieMnemonic]
	FROM [MeDriAnchor].[DBTableTie]
	WHERE [MeDriAnchor].[fnGetTieTableNameFromMnemonic]([TieMnemonic]) = @TieName
	GROUP BY [TieMnemonic];

	SELECT	@metadataPrefix = MAX(CASE WHEN s.[SettingKey] = 'metadataPrefix' THEN COALESCE(se.[SettingValue], s.[SettingValue]) ELSE '' END),
			@encapsulation = MAX(CASE WHEN s.[SettingKey] = 'encapsulation' THEN COALESCE(se.[SettingValue], s.[SettingValue]) ELSE '' END),
			@identitySuffix = MAX(CASE WHEN s.[SettingKey] = 'identitySuffix' THEN COALESCE(se.[SettingValue], s.[SettingValue]) ELSE '' END),
			@changingSuffix = MAX(CASE WHEN s.[SettingKey] = 'changingSuffix' THEN COALESCE(se.[SettingValue], s.[SettingValue]) ELSE '' END),
			@positSuffix = MAX(CASE WHEN s.[SettingKey] = 'positSuffix' THEN COALESCE(se.[SettingValue], s.[SettingValue]) ELSE '' END),
			@temporalization = MAX(CASE WHEN s.[SettingKey] = 'temporalization' THEN COALESCE(se.[SettingValue], s.[SettingValue]) ELSE '' END)
	FROM [MeDriAnchor].[Settings] s
	LEFT OUTER JOIN [MeDriAnchor].[SettingsEnvironment] se
		ON s.[SettingKey] = se.[SettingKey]
		AND se.Environment_ID = @Environment_ID
	WHERE s.[SettingKey] IN('metadataPrefix', 'encapsulation', 'identitySuffix', 'changingSuffix', 'positSuffix',  'temporalization');

	INSERT INTO @Tie
	SELECT	DISTINCT		
			db.[DBName],
			t.[DBTableSchema], 
			QUOTENAME(db.[DBName] + '_' + t.[DBTableSchema] + '_' + t.[DBTableName]), 
			@encapsulation AS [DWHDBTableSchema],
			QUOTENAME(@DestinationDB + '_' + @encapsulation + '_' + @TieName + (CASE WHEN @temporalization = 'crt' THEN '_' + @positSuffix ELSE '' END)) AS [DWHDBTableName],
			(CASE WHEN ttc.[TieJoinOrder] = 1 THEN @TieName ELSE '' END) AS [DWHDBTableNameBase],
			(CASE WHEN tt.[KnotMnemonic] <> '' THEN tie.[KnotMnemonic] ELSE ttc.[AnchorMnemonicRef] END) AS [TableAlias],
			(CASE WHEN tt.[KnotMnemonic] <> '' THEN tie.[KnotMnemonic] ELSE ttc.[AnchorMnemonicRef] END) 
				+ '_' + @identitySuffix + '_' + ttc.[RoleName] AS [TieDBColumnName],
			tie.[DBTableColumnName] AS [SourceDBColumnName],
			tie.[DBTableColumnName] AS [SourcePKColumnName],
			ttc.[TieJoinOrder],
			ttc.[TieJoinColumn],
			tt.[IsHistorised],
			(CASE WHEN ttc.[TieJoinOrder] = 1 THEN ISNULL((SELECT TOP 1 [DBTableColumnName] FROM [MeDriAnchor].[DBTableColumn]
			WHERE [DBTableID] = tie.[DBTableID] AND [IsDatetimeComparison] = 1), '') ELSE '' END) AS [DateRestrictionColumn],
			(CASE WHEN ttc.[TieJoinOrder] = 1 THEN (@metadataPrefix + '_' + @TieName) ELSE '' END) AS [DWHTableColumnMeta],
			(CASE WHEN ttc.[TieJoinOrder] = 1 THEN (@TieName + '_' + @changingSuffix) ELSE '' END) AS [DWHTableColumnChangedAt],
			tie.[CreateNCIndexInDWH],
			tie.[GenerateID],
			(CASE 
				WHEN COALESCE(tiejc.[DataType], tie.[DataType]) LIKE 'nchar%' THEN 1
				WHEN COALESCE(tiejc.[DataType], tie.[DataType]) LIKE 'char%' THEN 1
				WHEN COALESCE(tiejc.[DataType], tie.[DataType]) LIKE 'nvarchar%' THEN 1
				WHEN COALESCE(tiejc.[DataType], tie.[DataType]) LIKE 'varchar%' THEN 1
				ELSE 0
			END) As [IsTextColumn],
			ttc.[DBTableColumnID]
	FROM [MeDriAnchor].[DBTableTie] tt
	INNER JOIN [MeDriAnchor].[DBTableTieColumns] ttc
		ON ttc.[TieID] = tt.[TieID]
	INNER JOIN [MeDriAnchor].[DBTableColumn] tie
		ON ttc.[DBTableColumnID] = tie.[DBTableColumnID]
	LEFT OUTER JOIN [MeDriAnchor].[DBTableColumn] tiejc
		ON tiejc.[DBTableID] = tiejc.[DBTableID]
		AND ttc.[TieJoinColumn] = tiejc.[DBTableColumnName]
	INNER JOIN [MeDriAnchor].[DBTable] t
		ON tie.[DBTableID] = t.[DBTableID]
	INNER JOIN [MeDriAnchor].[DB] db
		ON t.[DBID] = db.[DBID]
	WHERE (tt.[TieMnemonic] = @TieMnemonic)
		AND (tt.[KnotMnemonic] = '' OR (tt.[KnotMnemonic] <> '' AND tie.[PKColumn] = 1))
		AND tie.[Environment_ID] >= @Environment_ID;

	RETURN;

END