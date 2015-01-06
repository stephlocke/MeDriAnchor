CREATE FUNCTION [MeDriAnchor].[fnGetKnotETLMetadata]
(
@KnotName SYSNAME,
@Environment_ID SMALLINT
)
RETURNS @Knot TABLE 
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
	[CreateNCIndexInDWH] BIT,
	[GenerateID] BIT
)
AS
BEGIN

	DECLARE @metadataPrefix NVARCHAR(100);
	DECLARE @encapsulation NVARCHAR(100);
	DECLARE @identitySuffix NVARCHAR(100);
	DECLARE @DestinationDB SYSNAME;

	SELECT @DestinationDB = [DBName]
	FROM [MeDriAnchor].[DB]
	WHERE [DBIsDestination] = 1
		AND ([Environment_ID] = @Environment_ID OR [Environment_ID] IS NULL);

	SELECT	@metadataPrefix = MAX(CASE WHEN s.[SettingKey] = 'metadataPrefix' THEN COALESCE(se.[SettingValue], s.[SettingValue]) ELSE '' END),
			@encapsulation = MAX(CASE WHEN s.[SettingKey] = 'encapsulation' THEN COALESCE(se.[SettingValue], s.[SettingValue]) ELSE '' END),
			@identitySuffix = MAX(CASE WHEN s.[SettingKey] = 'identitySuffix' THEN COALESCE(se.[SettingValue], s.[SettingValue]) ELSE '' END)
	FROM [MeDriAnchor].[Settings] s
	LEFT OUTER JOIN [MeDriAnchor].[SettingsEnvironment] se
		ON s.[SettingKey] = se.[SettingKey]
		AND se.Environment_ID = @Environment_ID
	WHERE s.[SettingKey] IN('metadataPrefix', 'encapsulation', 'identitySuffix');

	INSERT INTO @Knot
	SELECT	db.[DBName],
			tc.[DBTableColumnID], 
			t.[DBTableSchema], 
			QUOTENAME(db.[DBName] + '_' + t.[DBTableSchema] + '_' + t.[DBTableName]), 
			tc.[DBTableColumnName],
			QUOTENAME(@DestinationDB + '_' + @encapsulation + '_' + @KnotName) AS [DWHTableName],
			tc.[KnotMnemonic] + '_' + COALESCE(NULLIF(tc.[DBTableColumnAlias], ''), tc.[DBTableColumnName]) AS [DWHTableColumnData],
			@metadataPrefix + '_' + tc.[KnotMnemonic] AS [DWHTableColumnMeta],
			tc.[PKColumn],
			tc.[PKColOrdinal],
			'' AS [DateRestrictionColumn],
			tc.[KnotJoinColumn],
			tc.[CreateNCIndexInDWH],
			tc.[GenerateID]
	FROM [MeDriAnchor].[DBTableColumn] tc
	INNER JOIN [MeDriAnchor].[DBTable] t
		ON tc.[DBTableID] = t.[DBTableID]
	INNER JOIN [MeDriAnchor].[DB] db
		ON t.[DBID] = db.[DBID]
	WHERE tc.[IsKnot] = 1
		AND [IdentityColumn] = 0
		AND tc.[KnotMnemonic] + '_' + COALESCE(NULLIF(tc.[DBTableColumnAlias], ''), tc.[DBTableColumnName])  = @KnotName
		AND tc.[Environment_ID] >= @Environment_ID
	UNION ALL
	SELECT	db.[DBName],
			tc.[DBTableColumnID], 
			t.[DBTableSchema], 
			QUOTENAME(db.[DBName] + '_' + t.[DBTableSchema] + '_' + t.[DBTableName]), 
			tc.[DBTableColumnName],
			QUOTENAME(@DestinationDB + '_' + @encapsulation + '_' + @KnotName) AS [DWHTableName],
			tc.[KnotMnemonic] + '_' + @identitySuffix AS [DWHTableColumnData],
			@metadataPrefix + '_' + tc.[KnotMnemonic] AS [DWHTableColumnMeta],
			tc.[PKColumn],
			tc.[PKColOrdinal],
			ISNULL((SELECT TOP 1 [DBTableColumnName] FROM [MeDriAnchor].[DBTableColumn]
			WHERE [DBTableID] = tc.[DBTableID] AND [IsDatetimeComparison] = 1), '') AS [DateRestrictionColumn],
			tc.[KnotJoinColumn],
			tc.[CreateNCIndexInDWH],
			tc.[GenerateID]
	FROM [MeDriAnchor].[DBTableColumn] tc
	INNER JOIN [MeDriAnchor].[DBTable] t
		ON tc.[DBTableID] = t.[DBTableID]
	INNER JOIN [MeDriAnchor].[DBTableColumn] kmtc
		ON tc.[KnotMnemonic] = kmtc.[KnotMnemonic]
		AND kmtc.[IsKnot] = 1
		AND kmtc.[IdentityColumn] = 0
	INNER JOIN [MeDriAnchor].[DB] db
		ON t.[DBID] = db.[DBID]
	WHERE tc.[IsKnot] = 1
		AND tc.[IdentityColumn] = 1
		AND tc.[KnotMnemonic] + '_' + COALESCE(NULLIF(kmtc.[DBTableColumnAlias], ''), kmtc.[DBTableColumnName]) = @KnotName
		AND tc.[Environment_ID] >= @Environment_ID
	ORDER BY 9 DESC, 10, 5;
	
	RETURN;

END
