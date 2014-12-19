
CREATE FUNCTION [MeDriAnchor].[fnGetAnchorETLMetadata]
(
@AnchorName SYSNAME,
@Environment_ID SMALLINT
)
RETURNS @Anchor TABLE 
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
	WHERE [DBIsDestination] = 1;

	SELECT	@metadataPrefix = MAX(CASE WHEN s.[SettingKey] = 'metadataPrefix' THEN COALESCE(se.[SettingValue], s.[SettingValue]) ELSE '' END),
			@encapsulation = MAX(CASE WHEN s.[SettingKey] = 'encapsulation' THEN COALESCE(se.[SettingValue], s.[SettingValue]) ELSE '' END),
			@identitySuffix = MAX(CASE WHEN s.[SettingKey] = 'identitySuffix' THEN COALESCE(se.[SettingValue], s.[SettingValue]) ELSE '' END)
	FROM [MeDriAnchor].[Settings] s
	LEFT OUTER JOIN [MeDriAnchor].[SettingsEnvironment] se
		ON s.[SettingKey] = se.[SettingKey]
		AND se.Environment_ID = @Environment_ID
	WHERE s.[SettingKey] IN('metadataPrefix', 'encapsulation', 'identitySuffix');

	INSERT INTO @Anchor
	SELECT	db.[DBName],
			tc.[DBTableColumnID], 
			t.[DBTableSchema], 
			QUOTENAME(db.[DBName] + '_' + t.[DBTableSchema] + '_' + t.[DBTableName]), 
			tc.[DBTableColumnName],
			QUOTENAME(@DestinationDB + '_' + @encapsulation + '_' + @AnchorName) AS [DWHTableName],
			tc.[AnchorMnemonic] + '_' + @identitySuffix AS [DWHTableColumnData],
			@metadataPrefix + '_' + tc.[AnchorMnemonic] AS [DWHTableColumnMeta],
			tc.[PKColumn],
			tc.[PKColOrdinal],
			ISNULL((SELECT TOP 1 [DBTableColumnName] FROM [MeDriAnchor].[DBTableColumn]
			WHERE [DBTableID] = tc.[DBTableID] AND [IsDatetimeComparison] = 1), '') AS [DateRestrictionColumn],
			tc.[CreateNCIndexInDWH],
			tc.[GenerateID]
	FROM [MeDriAnchor].[DBTableColumn] tc
	INNER JOIN [MeDriAnchor].[DBTable] t
		ON tc.[DBTableID] = t.[DBTableID]
	INNER JOIN [MeDriAnchor].[DB] db
		ON t.[DBID] = db.[DBID]
	WHERE tc.[IsAnchor] = 1
		AND tc.[AnchorMnemonic] + '_' + COALESCE(NULLIF(tc.[DBTableColumnAlias], ''), tc.[DBTableColumnName]) = @AnchorName
		AND tc.[Environment_ID] = @Environment_ID;
	
	RETURN;

END
