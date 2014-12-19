
-- DELETE OBJECTS FOR A GIVEN TABLE
CREATE PROCEDURE [MeDriAnchor].[sspDeleteObjectsForTable]
(
@TableSchema SYSNAME,
@TableName SYSNAME
)
AS
/*
DELETES ALL MeDriAnchor OBJECTS FOR A GIVEN TABLE
*/
SET NOCOUNT ON;

DECLARE @HasView NVARCHAR(5) = 'True';
DECLARE @HasShadowTable NVARCHAR(5) = 'True';
DECLARE @HasDeleteProc NVARCHAR(5) = 'True';
DECLARE @HasInsertProc NVARCHAR(5) = 'True';
DECLARE @HasUpdateProc NVARCHAR(5) = 'True';
DECLARE @HasSaveProc NVARCHAR(5) = 'False';

BEGIN TRANSACTION;

BEGIN TRY

	SELECT	@HasView = [HasView],
			@HasShadowTable = [HasShadowTable],
			@HasDeleteProc = [HasDeleteProc],
			@HasInsertProc = [HasInsertProc],
			@HasUpdateProc = [HasUpdateProc],
			@HasSaveProc = [HasSaveProc]
	FROM [MeDriAnchor].[svExtProps];

	-- call the relevant delete functions
	IF (@HasView = 'True')
	BEGIN
		EXEC [MeDriAnchor].[sspDropView] 
			@TableSchema = @TableSchema, 
			@TableName = @TableName,
			@Debug = 0;
	END

	IF (@HasShadowTable = 'True')
	BEGIN
		EXEC [MeDriAnchor].[sspDropShadowTable] 
			@TableSchema = @TableSchema, 
			@TableName = @TableName,
			@Debug = 0;
	END

	IF (@HasDeleteProc = 'True')
	BEGIN
		EXEC [MeDriAnchor].[sspDropDeleteSP] 
			@TableSchema = @TableSchema, 
			@TableName = @TableName,
			@Debug = 0;
	END

	IF (@HasInsertProc = 'True')
	BEGIN
		EXEC [MeDriAnchor].[sspDropInsertSP] 
			@TableSchema = @TableSchema, 
			@TableName = @TableName,
			@Debug = 0;
	END

	IF (@HasUpdateProc = 'True')
	BEGIN
		EXEC [MeDriAnchor].[sspDropUpdateSP] 
			@TableSchema = @TableSchema, 
			@TableName = @TableName,
			@Debug = 0;
	END

	IF (@HasSaveProc = 'True')
	BEGIN
		EXEC [MeDriAnchor].[sspDropSaveSP] 
			@TableSchema = @TableSchema, 
			@TableName = @TableName,
			@Debug = 0;
	END

	COMMIT TRANSACTION;

	RETURN 0;

END TRY

BEGIN CATCH

	DECLARE @ErrorMessage NVARCHAR(4000);
	DECLARE @ErrorSeverity INT;
	DECLARE @ErrorState INT;

	SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();

	RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);

	ROLLBACK TRANSACTION;

	RETURN -1;

END CATCH;
