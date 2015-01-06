CREATE PROCEDURE [dbo].[sspStatisticsMaintenance]
AS
SET NOCOUNT ON;

DECLARE @sql nvarchar(MAX);

BEGIN TRY

	PRINT N'Started statistics maintenance.';

	-- update statistics
	SELECT @sql = (SELECT 'UPDATE STATISTICS ' +
						  quotename(s.name) + '.' + quotename(o.name) +
						  ' WITH FULLSCAN; ' AS [text()]
				   FROM   sys.objects o
				   JOIN   sys.schemas s ON o.schema_id = s.schema_id
				   WHERE  o.type = 'U'
				   FOR XML PATH(''), TYPE).value('.', 'nvarchar(MAX)');

	EXEC (@sql);

	PRINT N'Completed statistics maintenance.';

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