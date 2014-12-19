
-- DROP DELETE TRIGGER
CREATE PROCEDURE [MeDriAnchor].[sspDropDeleteTrigger]
(
	@TableSchema SYSNAME,
	@TableName SYSNAME,
	@Debug BIT = 0
)
AS
/*
GENERATES THE SQL FOR THE DROP OF A DELETE TRIGGER
*/
DECLARE @SQL NVARCHAR(MAX) = '';
DECLARE @TriggerNamePrefix NVARCHAR(20) = 'atr';
DECLARE @TriggerNamePostfix NVARCHAR(20) = '_Delete';

BEGIN TRY

	SELECT	@TriggerNamePrefix = [DeleteTriggerNamePrefix],
			@TriggerNamePostfix = [DeleteTriggerNamePostfix]
	FROM [MeDriAnchor].[svExtProps];

	-- generate the drop
	SET @SQL += 'IF  EXISTS (SELECT * FROM sys.Triggers WHERE object_id = OBJECT_ID(N''[' + @TableSchema + '].[' + @TriggerNamePrefix + @TableName + @TriggerNamePostfix + ']'') AND type = N''TR'')' + CHAR(13);
	SET @SQL += 'DROP TRIGGER [' + @TableSchema + '].[' + @TriggerNamePrefix + @TableName + @TriggerNamePostfix + '];' + CHAR(13)+ CHAR(13);
  
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
