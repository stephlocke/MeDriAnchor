
CREATE PROC [MeDriAnchor].[sspGenerateSourceSynonyms](@Debug BIT = 0)
AS

DECLARE @SQL NVARCHAR(MAX) = '';

BEGIN TRY

	BEGIN TRAN;

	SELECT	@SQL += 'IF NOT EXISTS(SELECT * FROM sys.Synonyms WHERE [name] = ''' + db.[DBName] + '_' + t.[DBTableSchema] + '_' + t.[DBTableName] + ''')' + CHAR(10) +
		+ 'BEGIN CREATE SYNONYM [' + db.[DBName] + '_' + t.[DBTableSchema] + '_' + t.[DBTableName] + '] FOR '
		+ '[' + s.[ServerName] + '].[' + db.[DBName] + '].[' + t.[DBTableSchema] + '].[' + t.[DBTableName] + '] END;' + CHAR(10)
	FROM [MeDriAnchor].[svTableColumnsWithMetadata] cmd
	INNER JOIN [MeDriAnchor].[DBTable] t
		ON cmd.[DBTableID] = t.[DBTableID]
	INNER JOIN [MeDriAnchor].[DB] db
		ON t.[DBID] = db.[DBID]
	INNER JOIN [MeDriAnchor].[DBServer] s
		ON db.[DBServerID] = s.[DBServerID]
	GROUP BY	s.[ServerName],
				db.[DBName],
				t.[DBTableSchema],
				t.[DBTableName],
				t.[DBTableType];

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

	RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);

	RETURN -1;

END CATCH;
