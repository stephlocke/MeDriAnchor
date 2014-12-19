CREATE PROC [MeDriAnchor].[sspGenerateDWHSynonyms](@Debug BIT = 0, @Environment_ID SMALLINT = 3)
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

	SELECT	@DestinationServer = s.[ServerName],
			@DestinationDB = db.[DBName]
	FROM [MeDriAnchor].[DB] db
	INNER JOIN [MeDriAnchor].[DBServer] s
		ON db.[DBServerID] = s.[DBServerID]
	WHERE db.[DBIsDestination] = 1
		AND (db.[Environment_ID] IS NULL OR db.[Environment_ID] = @Environment_ID);

	SELECT	@encapsulation = MAX(CASE WHEN s.[SettingKey] = 'encapsulation' THEN COALESCE(se.[SettingValue], s.[SettingValue]) ELSE '' END),
			@temporalization = MAX(CASE WHEN s.[SettingKey] = 'temporalization' THEN COALESCE(se.[SettingValue], s.[SettingValue]) ELSE '' END),
			@positSuffix = MAX(CASE WHEN s.[SettingKey] = 'positSuffix' THEN COALESCE(se.[SettingValue], s.[SettingValue]) ELSE '' END),
			@annexSuffix = MAX(CASE WHEN s.[SettingKey] = 'annexSuffix' THEN COALESCE(se.[SettingValue], s.[SettingValue]) ELSE '' END)
	FROM [MeDriAnchor].[Settings] s
	LEFT OUTER JOIN [MeDriAnchor].[SettingsEnvironment] se
		ON s.[SettingKey] = se.[SettingKey]
		AND se.Environment_ID = @Environment_ID
	WHERE s.[SettingKey] IN('encapsulation', 'temporalization', 'positSuffix', 'annexSuffix');

	SELECT	@SQL += 'IF NOT EXISTS(SELECT * FROM sys.Synonyms WHERE [name] = N''' + @DestinationDB + '_' + @encapsulation + '_' + [name] + ''')' + CHAR(10) +
		+ 'BEGIN CREATE SYNONYM [' + @DestinationDB + '_' + @encapsulation + '_' + [name] + '] FOR '
		+ '[' + @DestinationServer + '].[' + @DestinationDB + '].[' + @encapsulation + '].[' + [name] + '] END;' + CHAR(10)
	FROM [MeDriAnchor].[Dwh].[_AnchorObjects]
	WHERE [Type] NOT IN('AT', 'TI');

	IF (@temporalization = 'crt')
	BEGIN
		SELECT	@SQL += 'IF NOT EXISTS(SELECT * FROM sys.Synonyms WHERE [name] = N''' + @DestinationDB + '_' + @encapsulation + '_' + [name] + '_' + @positSuffix + ''')' + CHAR(10) +
			+ 'BEGIN CREATE SYNONYM [' + @DestinationDB + '_' + @encapsulation + '_' + [name] + '_' + @positSuffix + '] FOR '
			+ '[' + @DestinationServer + '].[' + @DestinationDB + '].[' + @encapsulation + '].[' + [name] + '_' + @positSuffix + '] END;' + CHAR(10)
		FROM [MeDriAnchor].[Dwh].[_AnchorObjects]
		WHERE [Type] IN('AT', 'TI');
		SELECT	@SQL += 'IF NOT EXISTS(SELECT * FROM sys.Synonyms WHERE [name] = N''' + @DestinationDB + '_' + @encapsulation + '_' + [name] + '_' + @annexSuffix + ''')' + CHAR(10) +
			+ 'BEGIN CREATE SYNONYM [' + @DestinationDB + '_' + @encapsulation + '_' + [name]  + '_' + @annexSuffix + '] FOR '
			+ '[' + @DestinationServer + '].[' + @DestinationDB + '].[' + @encapsulation + '].[' + [name] + '_' + @annexSuffix + '] END;' + CHAR(10)
		FROM [MeDriAnchor].[Dwh].[_AnchorObjects]
		WHERE [Type] IN('AT', 'TI');
	END
	ELSE
	BEGIN
		SELECT	@SQL += 'IF NOT EXISTS(SELECT * FROM sys.Synonyms WHERE [name] = N''' + @DestinationDB + '_' + @encapsulation + '_' + [name] + ''')' + CHAR(10) +
			+ 'BEGIN CREATE SYNONYM [' + @DestinationDB + '_' + @encapsulation + '_' + [name] + '] FOR '
			+ '[' + @DestinationServer + '].[' + @DestinationDB + '].[' + @encapsulation + '].[' + [name] + '] END;' + CHAR(10)
		FROM [MeDriAnchor].[Dwh].[_AnchorObjects]
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
