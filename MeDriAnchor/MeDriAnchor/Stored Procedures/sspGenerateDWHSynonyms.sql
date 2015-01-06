CREATE PROC [MeDriAnchor].[sspGenerateDWHSynonyms](@Environment_ID SMALLINT, @Debug BIT = 0)
AS
SET NUMERIC_ROUNDABORT OFF;

DECLARE @SQL NVARCHAR(MAX) = '';

BEGIN TRY

	BEGIN TRAN;

	DECLARE @encapsulation NVARCHAR(100);
	DECLARE @temporalization NVARCHAR(100);
	DECLARE @positSuffix NVARCHAR(100);
	DECLARE @annexSuffix NVARCHAR(100);
	DECLARE @DestinationServer SYSNAME;
	DECLARE @DestinationDB SYSNAME;
	DECLARE @ViewSQL NVARCHAR(MAX) = '';

	-- Temp table to hold the appropriate environment view results
	CREATE TABLE #_AnchorObjects
		(
		[Type] VARCHAR(2) NOT NULL,
		[capsule] VARCHAR(MAX) NULL,
		[name] NVARCHAR(MAX) NULL,
		[KnotMnemonic] NVARCHAR(MAX) NULL,
		[AnchorMnemonic] NVARCHAR(MAX) NULL,
		[AttributeMnemonic] NVARCHAR(MAX) NULL,
		[TieMnemonic] NVARCHAR(MAX) NULL,
		[KnotRange] NVARCHAR(MAX) NULL,
		);

	SELECT	@DestinationServer = s.[ServerName],
			@DestinationDB = db.[DBName]
	FROM [MeDriAnchor].[DB] db
	INNER JOIN [MeDriAnchor].[DBServer] s
		ON db.[DBServerID] = s.[DBServerID]
	WHERE db.[DBIsDestination] = 1
		AND (db.[Environment_ID] = @Environment_ID OR db.[Environment_ID] IS NULL);

	SELECT	@encapsulation = MAX(CASE WHEN s.[SettingKey] = 'encapsulation' THEN COALESCE(se.[SettingValue], s.[SettingValue]) ELSE '' END),
			@temporalization = MAX(CASE WHEN s.[SettingKey] = 'temporalization' THEN COALESCE(se.[SettingValue], s.[SettingValue]) ELSE '' END),
			@positSuffix = MAX(CASE WHEN s.[SettingKey] = 'positSuffix' THEN COALESCE(se.[SettingValue], s.[SettingValue]) ELSE '' END),
			@annexSuffix = MAX(CASE WHEN s.[SettingKey] = 'annexSuffix' THEN COALESCE(se.[SettingValue], s.[SettingValue]) ELSE '' END)
	FROM [MeDriAnchor].[Settings] s
	LEFT OUTER JOIN [MeDriAnchor].[SettingsEnvironment] se
		ON s.[SettingKey] = se.[SettingKey]
		AND se.Environment_ID = @Environment_ID
	WHERE s.[SettingKey] IN('encapsulation', 'temporalization', 'positSuffix', 'annexSuffix');

	-- populate the view data (for the correct environment)
	SET @ViewSQL += 'SELECT [Type], [capsule], [name], [KnotMnemonic], [AnchorMnemonic], [AttributeMnemonic], [TieMnemonic],';
	SET @ViewSQL += '[KnotRange] FROM [' + @encapsulation + '].[_AnchorObjects];';

	INSERT INTO #_AnchorObjects
	EXEC (@ViewSQL);

	SELECT	@SQL += 'IF NOT EXISTS(SELECT * FROM sys.Synonyms WHERE [name] = N''' + @DestinationDB + '_' + @encapsulation + '_' + [name] + ''')' + CHAR(10) +
		+ 'BEGIN CREATE SYNONYM [' + @DestinationDB + '_' + @encapsulation + '_' + [name] + '] FOR '
		+ '[' + @DestinationServer + '].[' + @DestinationDB + '].[' + [capsule] + '].[' + [name] + '] END;' + CHAR(10)
	FROM #_AnchorObjects
	WHERE [Type] NOT IN('AT', 'TI');

	IF (@temporalization = 'crt')
	BEGIN
		SELECT	@SQL += 'IF NOT EXISTS(SELECT * FROM sys.Synonyms WHERE [name] = N''' + @DestinationDB + '_' + @encapsulation + '_' + [name] + '_' + @positSuffix + ''')' + CHAR(10) +
			+ 'BEGIN CREATE SYNONYM [' + @DestinationDB + '_' + @encapsulation + '_' + [name] + '_' + @positSuffix + '] FOR '
			+ '[' + @DestinationServer + '].[' + @DestinationDB + '].[' + [capsule] + '].[' + [name] + '_' + @positSuffix + '] END;' + CHAR(10)
		FROM #_AnchorObjects
		WHERE [Type] IN('AT', 'TI');
		SELECT	@SQL += 'IF NOT EXISTS(SELECT * FROM sys.Synonyms WHERE [name] = N''' + @DestinationDB + '_' + @encapsulation + '_' + [name] + '_' + @annexSuffix + ''')' + CHAR(10) +
			+ 'BEGIN CREATE SYNONYM [' + @DestinationDB + '_' + @encapsulation + '_' + [name]  + '_' + @annexSuffix + '] FOR '
			+ '[' + @DestinationServer + '].[' + @DestinationDB + '].[' + [capsule] + '].[' + [name] + '_' + @annexSuffix + '] END;' + CHAR(10)
		FROM #_AnchorObjects
		WHERE [Type] IN('AT', 'TI');
	END
	ELSE
	BEGIN
		SELECT	@SQL += 'IF NOT EXISTS(SELECT * FROM sys.Synonyms WHERE [name] = N''' + @DestinationDB + '_' + @encapsulation + '_' + [name] + ''')' + CHAR(10) +
			+ 'BEGIN CREATE SYNONYM [' + @DestinationDB + '_' + @encapsulation + '_' + [name] + '] FOR '
			+ '[' + @DestinationServer + '].[' + @DestinationDB + '].[' + [capsule] + '].[' + [name] + '] END;' + CHAR(10)
		FROM #_AnchorObjects
		WHERE [Type] IN('AT', 'TI');
	END

	IF (@Debug = 0)
	BEGIN
		EXEC sp_executesql @SQL;
	END
	ELSE
	BEGIN
		PRINT @SQL;
	END

	COMMIT TRAN;

END TRY

BEGIN CATCH

	DECLARE @ErrorMessage NVARCHAR(4000);
	DECLARE @ErrorSeverity INT;
	DECLARE @ErrorState INT;

	SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();

	ROLLBACK TRAN;

	RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);

	RETURN -1;

END CATCH;
