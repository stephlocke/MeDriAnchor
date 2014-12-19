
-- DROP SHADOW/AUDIT
CREATE PROCEDURE [MeDriAnchor].[sspDropShadowTable]
(
	@TableSchema SYSNAME,
	@TableName SYSNAME,
	@Debug BIT = 0
)
AS
/*
GENERATES THE SQL FOR THE DROP OF A SHADOW/AUDIT TABLE
*/
DECLARE @SQL NVARCHAR(MAX) = '';
DECLARE @ShadowTableNamePrefix NVARCHAR(20) = '';
DECLARE @ShadowTableNamePostfix NVARCHAR(20) = '_Shadow';
DECLARE @MaintenanceMode NVARCHAR(5) = 'False';

BEGIN TRY

	SELECT	@ShadowTableNamePrefix = [ShadowTableNamePrefix],
			@ShadowTableNamePostfix = [ShadowTableNamePostfix],
			@MaintenanceMode = [MaintenanceMode]
	FROM [MeDriAnchor].[svExtProps];

	IF (@MaintenanceMode = 'True')
		RETURN 0;

	-- create the drop
	SET @SQL = 
	'IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N''' + QUOTENAME(@TableSchema) + '.' + QUOTENAME(@ShadowTableNamePrefix + @TableName + @ShadowTableNamePostfix) + ''') 
	AND TYPE IN (N''U'')) DROP TABLE ' + QUOTENAME(@TableSchema) + '.' + QUOTENAME(@ShadowTableNamePrefix + @TableName + @ShadowTableNamePostfix) + ';' + CHAR(13) + CHAR(13);

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
