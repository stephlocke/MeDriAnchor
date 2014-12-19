
/*
DECLARE @Environment_ID SMALLINT = (SELECT [Environment_ID] FROM [MeDriAnchor].[Environment]
	WHERE [EnvironmentName] = 'DEVELOPMENT');
EXEC [MeDriAnchor].[sspDropDWHObjectView] @Environment_ID = @Environment_ID, @Debug = 0;
EXEC [MeDriAnchor].[sspCreateDWHObjectView] @Environment_ID = @Environment_ID, @Debug = 0;
*/

CREATE PROCEDURE [MeDriAnchor].[sspCreateDWHObjectView]
(
	@Environment_ID SMALLINT,
	@Debug BIT = 0
)
AS
SET NUMERIC_ROUNDABORT OFF;

/*
GENERATES THE SQL FOR THE CREATION OF A VIEW
*/
DECLARE @SQL NVARCHAR(MAX) = '';
DECLARE @encapsulation NVARCHAR(100);
DECLARE @DestinationDB SYSNAME;

BEGIN TRY

	SELECT @encapsulation = MAX(CASE WHEN s.[SettingKey] = 'encapsulation' THEN COALESCE(se.[SettingValue], s.[SettingValue]) ELSE '' END)
	FROM [MeDriAnchor].[Settings] s
	LEFT OUTER JOIN [MeDriAnchor].[SettingsEnvironment] se
		ON s.[SettingKey] = se.[SettingKey]
		AND se.Environment_ID = @Environment_ID
	WHERE s.[SettingKey] IN('encapsulation');

	-- get the destination db to use
	SELECT @DestinationDB = QUOTENAME(s.[ServerName]) + '.' + QUOTENAME(db.[DBName])
	FROM [MeDriAnchor].[DB] db
	INNER JOIN [MeDriAnchor].[DBServer] s
		ON db.[DBServerID] = s.[DBServerID]
	WHERE db.[DBIsDestination] = 1
		AND (db.[Environment_ID] IS NULL OR db.[Environment_ID] = @Environment_ID);
	
	SET @SQL += 'CREATE VIEW ' + QUOTENAME(@encapsulation) + '.[_AnchorObjects]' + CHAR(13);
	SET @SQL += 'AS' + CHAR(13);

	-- YAML metadata here
	SET @SQL += '/**' + CHAR(13);
	SET @SQL += 'revisions:' + CHAR(13);
	SET @SQL += ' - author: MeDriAnchor' + CHAR(13);
	SET @SQL += '	date: ' + CONVERT(VARCHAR(11), GETDATE(), 106) + CHAR(13);
	SET @SQL += 'summary:	>' + CHAR(13);
	SET @SQL += '				Retrieves Anchor object names (Knots, Anchors, Attributes, and Ties)' + CHAR(13);
	SET @SQL += ' - code:	SELECT * FROM [' + QUOTENAME(@encapsulation) + '.[_AnchorObjects]' + CHAR(13);
	SET @SQL += '	parameters: n/a' + CHAR(13);
	SET @SQL += 'returns: Anchor object type and name' + CHAR(13);
	SET @SQL += '**/' + CHAR(13);

	SET @SQL += 'SELECT ''KN'' AS [Type], [name], [mnemonic] AS [KnotMnemonic], '''' AS [AnchorMnemonic], '''' AS [AttributeMnemonic], '''' AS [TieMnemonic], '''' AS [KnotRange] FROM ' + @DestinationDB + '.' +  QUOTENAME(@encapsulation) + '.[_Knot] WHERE [name] IS NOT NULL UNION ALL' + CHAR(13);
	SET @SQL += 'SELECT ''AN'' AS [Type], [name], '''' AS [KnotMnemonic], [mnemonic] AS [AnchorMnemonic], '''' AS [AttributeMnemonic], '''' AS [TieMnemonic], '''' AS [KnotRange] FROM ' + @DestinationDB + '.' +  QUOTENAME(@encapsulation) + '.[_Anchor] WHERE [name] IS NOT NULL UNION ALL' + CHAR(13);
	SET @SQL += 'SELECT ''AT'' AS [Type], [name], '''' AS [KnotMnemonic], [anchorMnemonic] AS [AnchorMnemonic], [mnemonic] AS [AttributeMnemonic], '''' AS [TieMnemonic], ISNULL([knotRange], '''') AS [KnotRange] FROM ' + @DestinationDB + '.' +  QUOTENAME(@encapsulation) + '.[_Attribute] WHERE [name] IS NOT NULL UNION ALL' + CHAR(13);
	SET @SQL += 'SELECT ''TI'' AS [Type], [name], '''' AS [KnotMnemonic], [anchors] AS [AnchorMnemonic], '''' AS [AttributeMnemonic], '''' AS [TieMnemonic], [knots] AS [KnotRange] FROM ' + @DestinationDB + '.' +  QUOTENAME(@encapsulation) + '.[_Tie] WHERE [name] IS NOT NULL;' + CHAR(13);

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