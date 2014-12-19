
-- DROP DELETE
CREATE PROCEDURE [MeDriAnchor].[sspDropDeleteSP]
(
	@TableSchema SYSNAME,
	@TableName SYSNAME,
	@Debug BIT = 0
)
AS
/*
DROPS A DELETE STORED PROCEDURE
*/
DECLARE @SQL NVARCHAR(MAX) = '';
DECLARE @DeletedProcNamePrefix NVARCHAR(20) = 'asp';
DECLARE @DeletedProcNamePostfix NVARCHAR(20) = '_Delete';

BEGIN TRY

	SELECT	@DeletedProcNamePrefix = [DeleteProcNamePrefix],
			@DeletedProcNamePostfix = [DeleteProcNamePostfix]
	FROM [MeDriAnchor].[svExtProps];

	-- generate the drop
	SET @SQL += 'IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N''[' + @TableSchema + '].[' + @DeletedProcNamePrefix + @TableName + @DeletedProcNamePostfix + ']'') AND type in (N''P'', N''PC''))' + CHAR(13);
	SET @SQL += 'DROP PROCEDURE [' + @TableSchema + '].[' + @DeletedProcNamePrefix + @TableName + @DeletedProcNamePostfix + '];' + CHAR(13)+ CHAR(13);
  
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
