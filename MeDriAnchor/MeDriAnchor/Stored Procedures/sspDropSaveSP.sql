
-- DROP SAVE
CREATE PROCEDURE [MeDriAnchor].[sspDropSaveSP]
(
	@TableSchema SYSNAME,
	@TableName SYSNAME,
	@Debug BIT = 0
)
AS
/*
GENERATES THE SQL FOR THE DROP OF A SAVE (COMBINED INSERT/UPDATE) STORED 
PROCEDURE
*/
DECLARE @SQL NVARCHAR(MAX) = '';
DECLARE @SaveProcNamePrefix NVARCHAR(20) = 'asp';
DECLARE @SaveProcNamePostfix NVARCHAR(20) = '_Save';

BEGIN TRY

	SELECT	@SaveProcNamePrefix = [SaveProcNamePrefix],
			@SaveProcNamePostfix = [SaveProcNamePostfix]
	FROM [MeDriAnchor].[svExtProps];

	-- generate the drop
	SET @SQL += 'IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N''[' + @TableSchema + '].[' + @SaveProcNamePrefix + @TableName + @SaveProcNamePostfix + ']'') AND type in (N''P'', N''PC''))' + char(13)
	SET @SQL += 'DROP PROCEDURE [' + @TableSchema + '].[' + @SaveProcNamePrefix + @TableName + @SaveProcNamePostfix + '];' + CHAR(13) + CHAR(13);
	
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
