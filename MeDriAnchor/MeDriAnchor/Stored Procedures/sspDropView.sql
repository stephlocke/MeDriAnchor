
-- DROP VIEW
CREATE PROCEDURE [MeDriAnchor].[sspDropView]
(
	@TableSchema SYSNAME,
	@TableName SYSNAME,
	@Debug BIT = 0
)
AS
/*
GENERATES THE SQL FOR THE DROP OF A VIEW
*/
DECLARE @SQL NVARCHAR(MAX) = '';
DECLARE @ViewNamePrefix NVARCHAR(20) = 'av';
DECLARE @ViewNamePostfix NVARCHAR(20) = '';

BEGIN TRY

	SELECT	@ViewNamePrefix = [ViewNamePrefix],
			@ViewNamePostfix = [ViewNamePostfix]
	FROM [MeDriAnchor].[svExtProps];
	
	-- generate the drop
	SET @SQL += 'IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N''[' + @TableSchema + '].[' + @ViewNamePrefix + @TableName + @ViewNamePostfix + ']'') AND type = N''V'')' + CHAR(13)
	SET @SQL += 'DROP VIEW [' + @TableSchema + '].[' + @ViewNamePrefix + @TableName + @ViewNamePostfix + '];' + CHAR(13) + CHAR(13);

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
