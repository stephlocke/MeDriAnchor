CREATE FUNCTION [MeDriAnchor].[fnGetAnchorXML](@Environment_ID SMALLINT) 
RETURNS XML
AS
BEGIN

	DECLARE @XML xml;
	DECLARE @encapsulation NVARCHAR(100);
	DECLARE @restatable NVARCHAR(100);
	DECLARE @idempotent NVARCHAR(100);
	DECLARE @identity NVARCHAR(100);
	DECLARE @changingRange NVARCHAR(100);

	SELECT	@encapsulation = MAX(CASE WHEN s.[SettingKey] = 'encapsulation' THEN COALESCE(se.[SettingValue], s.[SettingValue]) ELSE '' END),
			@restatable = MAX(CASE WHEN s.[SettingKey] = 'restatable' THEN COALESCE(se.[SettingValue], s.[SettingValue]) ELSE '' END),
			@idempotent = MAX(CASE WHEN s.[SettingKey] = 'idempotent' THEN COALESCE(se.[SettingValue], s.[SettingValue]) ELSE '' END),
			@identity = MAX(CASE WHEN s.[SettingKey] = 'identity' THEN COALESCE(se.[SettingValue], s.[SettingValue]) ELSE '' END),
			@changingRange = MAX(CASE WHEN s.[SettingKey] = 'changingRange' THEN COALESCE(se.[SettingValue], s.[SettingValue]) ELSE '' END)
	FROM [MeDriAnchor].[Settings] s
	LEFT OUTER JOIN [MeDriAnchor].[SettingsEnvironment] se
		ON s.[SettingKey] = se.[SettingKey]
		AND se.Environment_ID = @Environment_ID
	WHERE s.[SettingKey] IN('encapsulation', 'restatable', 'idempotent', 'identity', 'changingRange')

	SET @XML = 
	(
	SELECT	(SELECT COALESCE(se.[SettingValue], s.[SettingValue]) 
			FROM [MeDriAnchor].[Settings] s
			LEFT OUTER JOIN [MeDriAnchor].[SettingsEnvironment] se
				ON s.[SettingKey] = se.[SettingKey]
				AND se.Environment_ID = @Environment_ID
			WHERE s.[SettingKey] = 'format') AS "@format",
			CONVERT(VARCHAR(10), GETDATE(), 120) AS "@date",
			CONVERT(VARCHAR(8), GETDATE(), 108) AS "@time",
			(
			SELECT [MeDriAnchor].[fnGetSchemaMetadataElement](@Environment_ID)
			),
			-- knots
			(
			SELECT	t.[KnotMnemonic] AS "@mnemonic",
					COALESCE(NULLIF(t.[DBTableColumnAlias], ''), t.[DBTableColumnName]) AS "@descriptor",
					ISNULL((SELECT [DataType] FROM [MeDriAnchor].[DBTableColumn] WHERE [KnotMnemonic] = t.[KnotMnemonic] AND [IdentityColumn] = 1), 'int') AS "@identity",
					t.[DataType] AS "@dataRange",
					(
					SELECT	tsch.[Encapsulation] AS "@capsule",
							(CASE t.[GenerateID] WHEN 1 THEN 'true' ELSE 'false' END) AS "@generator"
					FOR XML PATH('metadata'), TYPE
					)
			FROM [MeDriAnchor].[DBTableColumn] t
			INNER JOIN [MeDriAnchor].[svEnvironmentSchemas] tsch
				ON t.[Environment_ID] = tsch.[Environment_ID]
			WHERE t.[IsKnot] = 1
				AND t.[IdentityColumn] = 0
			ORDER BY t.[DBTableID], t.[DBTableColumnName]
			FOR XML PATH('knot'), TYPE
			),
			-- anchors
			(
			SELECT	t.[AnchorMnemonic] AS "@mnemonic",
					COALESCE(NULLIF(t.[DBTableColumnAlias], ''), t.[DBTableColumnName]) AS "@descriptor",
					[DataType] AS "@identity",
					(
					SELECT	tsch.[Encapsulation] AS "@capsule",
							(CASE WHEN t.[GenerateID] = 0 THEN 'false' ELSE 'true' END) AS "@generator"
					FOR XML PATH('metadata'), TYPE
					),
					-- attributes
					(
					SELECT	att.[AttributeMnemonic] AS "@mnemonic",
							att.[DBTableColumnName] AS "@descriptor",
							(CASE WHEN att.[IsHistorised] = 0 THEN NULL ELSE att.[HistorisedTimeRange] END) AS "@timeRange",
							[DataType] AS "@dataRange",
							NULLIF(att.[KnotMnemonic], '') AS "@knotRange",
							(
							SELECT	tschatt.[Encapsulation] AS "@capsule",
									@restatable AS "@restatable", 
									@idempotent AS "@idempotent"
							FOR XML PATH('metadata'), TYPE
							)
					FROM [MeDriAnchor].[DBTableColumn] att
					INNER JOIN [MeDriAnchor].[svEnvironmentSchemas] tschatt
						ON att.[Environment_ID] = tschatt.[Environment_ID]
					WHERE att.[IsAttribute] = 1
						AND att.[AnchorMnemonicRef] = t.AnchorMnemonic
						AND att.[Environment_ID] >= @Environment_ID
					ORDER BY att.[AttributeMnemonic]
					FOR XML PATH('attribute'), TYPE
					)
			FROM [MeDriAnchor].[DBTableColumn] t
			INNER JOIN [MeDriAnchor].[svEnvironmentSchemas] tsch
				ON t.[Environment_ID] = tsch.[Environment_ID]
			WHERE t.[IsAnchor] = 1
				AND t.[Environment_ID] >= @Environment_ID
			ORDER BY t.[DBTableID], t.[DBTableColumnName]
			FOR XML PATH('anchor'), TYPE
			),
			-- ties
			(
			SELECT	@identity AS "@identity",
					(CASE WHEN CONVERT(TINYINT, tie.[IsHistorised]) = 1 THEN @changingRange ELSE NULL END) AS "@timeRange",
					(
					SELECT	tc.[AnchorMnemonicRef] AS "@type",
							tc.[RoleName] AS "@role",
							(CASE WHEN tc.[IsIdentity] = 0 THEN 'false' ELSE 'true' END) AS "@identifier"
					FROM [MeDriAnchor].[DBTableTieColumns] tc
					WHERE tc.[TieID] = tie.[TieID]
					ORDER BY tc.[TieJoinOrder]
					FOR XML PATH('anchorRole'), TYPE
					),
					(
					SELECT	[KnotMnemonic] AS "@type",
							tc.[RoleName] AS "@role",
							(CASE tie.[GenerateID] WHEN 1 THEN 'true' ELSE 'false' END) AS "@identifier"
					FROM [MeDriAnchor].[DBTableTieColumns] tc
					WHERE tc.[TieID] = tie.[TieID]
						AND tie.[KnotMnemonic] <> ''
					ORDER BY tc.[TieJoinOrder]
					FOR XML PATH('knotRole'), TYPE
					),
					(
					SELECT	tschtie.[Encapsulation] AS "@capsule"
					FOR XML PATH('metadata'), TYPE
					)
			FROM [MeDriAnchor].[DBTableTie] tie
			INNER JOIN [MeDriAnchor].[svEnvironmentSchemas] tschtie
						ON tschtie.[Environment_ID] = tie.[Environment_ID]
			WHERE tie.[Environment_ID] >= @Environment_ID
			FOR XML PATH('tie'), TYPE
			)
	FOR XML PATH('schema')
	);

	RETURN @xml;

END