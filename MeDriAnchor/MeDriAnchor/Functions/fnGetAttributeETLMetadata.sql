CREATE FUNCTION [MeDriAnchor].[fnGetAttributeETLMetadata]
(
@AttributeName SYSNAME,
@Environment_ID SMALLINT
)
RETURNS @Attribute TABLE 
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
	[IsTextColumn] BIT DEFAULT(0),
	[IsMaterialisedColumn] BIT DEFAULT(0),
	[MaterialisedColumnFunction] SYSNAME,
	[AttributeMnemonic] NVARCHAR(7),
	[AnchorMnemonic] NVARCHAR(7),
	[CreateNCIndexInDWH] BIT,
	[GenerateID] BIT
)
AS
BEGIN

	DECLARE @metadataPrefix NVARCHAR(100);
	DECLARE @encapsulation NVARCHAR(100);
	DECLARE @identitySuffix NVARCHAR(100);
	DECLARE @changingSuffix NVARCHAR(100);
	DECLARE @positSuffix NVARCHAR(100);
	DECLARE @temporalization NVARCHAR(100);
	DECLARE @DestinationDB SYSNAME;

	SELECT @DestinationDB = [DBName]
	FROM [MeDriAnchor].[DB]
	WHERE [DBIsDestination] = 1
		AND ([Environment_ID] = @Environment_ID OR [Environment_ID] IS NULL);

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

	IF (@temporalization = 'crt')
	BEGIN
		INSERT INTO @Attribute
		SELECT	db.[DBName],
				att.[DBTableColumnID], 
				t.[DBTableSchema], 
				QUOTENAME(db.[DBName] + '_' + t.[DBTableSchema] + '_' + t.[DBTableName]), 
				att.[IsHistorised],
				QUOTENAME(@DestinationDB + '_' + @encapsulation + '_' + @AttributeName + '_' + @positSuffix) AS [DWHTableName],
				att.[AnchorMnemonicRef] + '_' + att.[AttributeMnemonic] + '_' + att.[AnchorMnemonicRef] + '_' + @identitySuffix AS [DWHTableColumnDataID],
				att.[AnchorMnemonicRef] + '_' + att.[AttributeMnemonic] + '_' + COALESCE(NULLIF(anch.[DBTableColumnAlias], ''), anch.[DBTableColumnName]) + '_' + att.[DBTableColumnName] AS [DWHTableColumnData],
				att.[DBTableColumnName] AS [DBTableColumnName],
				(CASE WHEN att.[IsHistorised] = 1 THEN att.[AnchorMnemonicRef] + '_' + att.[AttributeMnemonic] + '_' + @changingSuffix ELSE '' END) AS [DWHTableColumnChangedAt],
				@metadataPrefix + '_' + att.[AnchorMnemonicRef] + '_' + att.[AttributeMnemonic] AS [DWHTableColumnMeta],
				ISNULL(anch.[PKColumn], 0),
				ISNULL(anch.[PKColOrdinal], 0),
				ISNULL(anch.[DBTableColumnName], '') AS [PKDBTableColumnName],
				ISNULL((SELECT TOP 1 [DBTableColumnName] FROM [MeDriAnchor].[DBTableColumn]
				WHERE [DBTableID] = att.[DBTableID] AND [IsDatetimeComparison] = 1), '') AS [DateRestrictionColumn],
				att.[AnchorMnemonicRef] + '_' + att.[AttributeMnemonic] + '_' AS [TableAttributePrefix],
				(CASE 
					WHEN att.[DataType] LIKE 'nchar%' THEN 1
					WHEN att.[DataType] LIKE 'char%' THEN 1
					WHEN att.[DataType] LIKE 'nvarchar%' THEN 1
					WHEN att.[DataType] LIKE 'varchar%' THEN 1
					ELSE 0
				END) As [IsTextColumn],
				att.[IsMaterialisedColumn],
				att.[MaterialisedColumnFunction],
				att.[AttributeMnemonic],
				att.[AnchorMnemonicRef],
				att.[CreateNCIndexInDWH],
				att.[GenerateID]
		FROM [MeDriAnchor].[DBTableColumn] att
		INNER JOIN [MeDriAnchor].[DBTableColumn] anch
			ON att.[AnchorMnemonicRef] = anch.[AnchorMnemonic]
			AND anch.[IsAnchor] = 1
		INNER JOIN [MeDriAnchor].[DBTable] t
			ON att.[DBTableID] = t.[DBTableID]
		INNER JOIN [MeDriAnchor].[DB] db
			ON t.[DBID] = db.[DBID]
		LEFT OUTER JOIN [MeDriAnchor].[DBTableColumn] pk
			ON t.[DBTableID] = pk.[DBTableID]
			AND pk.[PKColumn] = 1
			AND pk.[PKColOrdinal] = 1
			AND att.[PKColumn] = 0
		WHERE att.[IsAttribute] = 1
			AND (att.[AnchorMnemonicRef] + '_' + att.[AttributeMnemonic] + '_' + COALESCE(NULLIF(anch.[DBTableColumnAlias], ''), anch.[DBTableColumnName]) + '_' + att.[DBTableColumnName]) = @AttributeName
			AND att.[Environment_ID] >= @Environment_ID;
	END
	ELSE
	BEGIN
		INSERT INTO @Attribute
		SELECT	db.[DBName],
				att.[DBTableColumnID], 
				t.[DBTableSchema], 
				db.[DBName] + '_' + t.[DBTableSchema] + '_' + t.[DBTableName], 
				att.[IsHistorised],
				QUOTENAME(@DestinationDB + '_' + @encapsulation + '_' + @AttributeName) AS [DWHTableName],
				att.[AnchorMnemonicRef] + '_' + att.[AttributeMnemonic] + '_' + att.[AnchorMnemonicRef] + '_' + @identitySuffix AS [DWHTableColumnDataID],
				att.[AnchorMnemonicRef] + '_' + att.[AttributeMnemonic] + '_' + COALESCE(NULLIF(anch.[DBTableColumnAlias], ''), anch.[DBTableColumnName]) + '_' + att.[DBTableColumnName] AS [DWHTableColumnData],
				att.[DBTableColumnName] AS [DBTableColumnName],
				(CASE WHEN att.[IsHistorised] = 1 THEN att.[AnchorMnemonicRef] + '_' + att.[AttributeMnemonic] + '_' + @changingSuffix ELSE '' END) AS [DWHTableColumnChangedAt],
				@metadataPrefix + '_' + att.[AnchorMnemonicRef] + '_' + att.[AttributeMnemonic] AS [DWHTableColumnMeta],
				ISNULL(anch.[PKColumn], 0),
				ISNULL(anch.[PKColOrdinal], 0),
				ISNULL(anch.[DBTableColumnName], '') AS [PKDBTableColumnName],
				ISNULL((SELECT TOP 1 [DBTableColumnName] FROM [MeDriAnchor].[DBTableColumn]
				WHERE [DBTableID] = att.[DBTableID] AND [IsDatetimeComparison] = 1), '') AS [DateRestrictionColumn],
				att.[AnchorMnemonicRef] + '_' + att.[AttributeMnemonic] + '_' AS [TableAttributePrefix],
				(CASE 
					WHEN att.[DataType] LIKE 'nchar%' THEN 1
					WHEN att.[DataType] LIKE 'char%' THEN 1
					WHEN att.[DataType] LIKE 'nvarchar%' THEN 1
					WHEN att.[DataType] LIKE 'varchar%' THEN 1
					ELSE 0
				END) As [IsTextColumn],
				att.[IsMaterialisedColumn],
				att.[MaterialisedColumnFunction],
				att.[AttributeMnemonic],
				att.[AnchorMnemonicRef],
				att.[CreateNCIndexInDWH],
				att.[GenerateID]
		FROM [MeDriAnchor].[DBTableColumn] att
		INNER JOIN [MeDriAnchor].[DBTableColumn] anch
			ON att.[AnchorMnemonicRef] = anch.[AnchorMnemonic]
			AND anch.[IsAnchor] = 1
		INNER JOIN [MeDriAnchor].[DBTable] t
			ON att.[DBTableID] = t.[DBTableID]
		INNER JOIN [MeDriAnchor].[DB] db
			ON t.[DBID] = db.[DBID]
		WHERE att.[IsAttribute] = 1
			AND (att.[AnchorMnemonicRef] + '_' + att.[AttributeMnemonic] + '_' + COALESCE(NULLIF(anch.[DBTableColumnAlias], ''), anch.[DBTableColumnName]) + '_' + att.[DBTableColumnName]) = @AttributeName
			AND att.[Environment_ID] >= @Environment_ID;
	END

	RETURN;

END
