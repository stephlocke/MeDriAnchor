CREATE PROCEDURE [MeDriAnchor].[sspSynchLocalLookups]
AS
SET NOCOUNT ON;

DECLARE @SQL NVARCHAR(MAX) = '';

BEGIN TRAN;

BEGIN TRY

	SELECT @SQL += 'EXEC ' + QUOTENAME([DBName]) + '.[MeDriAnchor].[sspSynchLocalLookups];' + CHAR(10)
	FROM [MeDriAnchor].[DB]
	WHERE [DBIsSource] = 1
		AND [DBIsLocal] = 1;

	EXEC sys.sp_executesql @SQL;

	COMMIT TRANSACTION;

	RETURN 0;

END TRY

BEGIN CATCH

	DECLARE @ErrorMessage NVARCHAR(4000);
	DECLARE @ErrorSeverity INT;
	DECLARE @ErrorState INT;

	RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);

	ROLLBACK TRANSACTION;

	RETURN -1;

END CATCH;