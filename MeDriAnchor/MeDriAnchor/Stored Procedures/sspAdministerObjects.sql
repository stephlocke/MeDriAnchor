
-- ADMINISTER OBJECTS
CREATE PROCEDURE [MeDriAnchor].[sspAdministerObjects]
(
@TableSchema SYSNAME,
@TableName SYSNAME
)
AS
/*
GENERATES/REGENERATES ALL THE MeDriAnchor OBJECTS FOR A GIVEN TABLE
*/
SET NOCOUNT ON;

DECLARE @HasView NVARCHAR(5) = 'False';
DECLARE @UsingShadowTable NVARCHAR(5) = 'True';
DECLARE @HasDeleteProc NVARCHAR(5) = 'False';
DECLARE @HasInsertProc NVARCHAR(5) = 'False';
DECLARE @HasUpdateProc NVARCHAR(5) = 'False';
DECLARE @HasSaveProc NVARCHAR(5) = 'False';
DECLARE @HasDeleteTrigger NVARCHAR(5) = 'True';
DECLARE @HasInsertTrigger NVARCHAR(5) = 'True';
DECLARE @HasUpdateTrigger NVARCHAR(5) = 'True';
DECLARE @UsingShadow BIT = 1;
DECLARE @ErrorSection NVARCHAR(20) = '';
DECLARE @TableColumns [MeDriAnchor].[TableColumns];

BEGIN TRANSACTION;

BEGIN TRY

	SELECT	@HasView = [HasView],
			@UsingShadowTable = [HasShadowTable],
			@HasDeleteProc = [HasDeleteProc],
			@HasInsertProc = [HasInsertProc],
			@HasUpdateProc = [HasUpdateProc],
			@HasSaveProc = [HasSaveProc],
			@HasDeleteTrigger = [HasDeleteTrigger],
			@HasInsertTrigger = [HasInsertTrigger],
			@HasUpdateTrigger = [HasUpdateTrigger]
	FROM [MeDriAnchor].[svExtProps];

	INSERT INTO @TableColumns
	SELECT *
	FROM [MeDriAnchor].[svTableColumns]
	WHERE TableSchema = @TableSchema
		AND TableName = @TableName;

	SET @ErrorSection = 'View';

	IF (@HasView = 'True')
	BEGIN

		-- DROP
		EXEC [MeDriAnchor].[sspDropView]
			@TableSchema = @TableSchema, 
			@TableName = @TableName,
			@Debug = 0;

		-- CREATE
		EXEC [MeDriAnchor].[sspCreateView]
			@TableSchema = @TableSchema, 
			@TableName = @TableName,
			@TableColumnsCV = @TableColumns,
			@Debug = 0;

	END

	SET @ErrorSection = 'Shadow Table';

	IF (@UsingShadowTable = 'True')
	BEGIN

		-- DROP
		EXEC [MeDriAnchor].[sspDropShadowTable]
			@TableSchema = @TableSchema, 
			@TableName = @TableName,
			@Debug = 0;

		-- CREATE
		EXEC [MeDriAnchor].[sspCreateShadowTable]
			@TableSchema = @TableSchema, 
			@TableName = @TableName,
			@TableColumnsCST = @TableColumns,
			@Debug = 0;

	END

	SET @ErrorSection = 'Delete SP';

	IF (@HasDeleteProc = 'True')
	BEGIN

		-- DROP
		EXEC [MeDriAnchor].[sspDropDeleteSP]
			@TableSchema = @TableSchema, 
			@TableName = @TableName,
			@Debug = 0;
		
		IF (@UsingShadowTable = 'True' AND @HasDeleteTrigger = 'True')
		BEGIN
			-- has trigger so do not audit in the stored procedure
			SET @UsingShadow = 0;
		END
		ELSE
		BEGIN
			SET @UsingShadow = (CASE WHEN @UsingShadowTable = 'True' THEN 1 ELSE 0 END);
		END

		-- CREATE
		EXEC [MeDriAnchor].[sspCreateDeleteSP]
			@TableSchema = @TableSchema,
			@TableName = @TableName,
			@TableColumnsCDSP = @TableColumns,
			@UsingShadow = @UsingShadow,
			@Debug = 0;
	END

	SET @ErrorSection = 'Insert SP';

	IF (@HasInsertProc = 'True')
	BEGIN
		
		-- DROP
		EXEC [MeDriAnchor].[sspDropInsertSP]
			@TableSchema = @TableSchema, 
			@TableName = @TableName,
			@Debug = 0;

		IF (@UsingShadowTable = 'True' AND @HasInsertTrigger = 'True')
		BEGIN
			-- has trigger so do not audit in the stored procedure
			SET @UsingShadow = 0;
		END
		ELSE
		BEGIN
			SET @UsingShadow = (CASE WHEN @UsingShadowTable = 'True' THEN 1 ELSE 0 END);
		END
		
		-- CREATE
		EXEC [MeDriAnchor].[sspCreateInsertSP]
			@TableSchema = @TableSchema,
			@TableName = @TableName,
			@TableColumnsCISP = @TableColumns,
			@UsingShadow = @UsingShadow,
			@Debug = 0;

	END

	SET @ErrorSection = 'Update SP';

	IF (@HasUpdateProc = 'True')
	BEGIN
		
		-- DROP
		EXEC [MeDriAnchor].[sspDropUpdateSP]
			@TableSchema = @TableSchema, 
			@TableName = @TableName,
			@Debug = 0;

		IF (@UsingShadowTable = 'True' AND @HasUpdateTrigger = 'True')
		BEGIN
			-- has trigger so do not audit in the stored procedure
			SET @UsingShadow = 0;
		END
		ELSE
		BEGIN
			SET @UsingShadow = (CASE WHEN @UsingShadowTable = 'True' THEN 1 ELSE 0 END);
		END 
		
		-- CREATE
		EXEC [MeDriAnchor].[sspCreateUpdateSP]
			@TableSchema = @TableSchema,
			@TableName = @TableName,
			@TableColumnsCUSP = @TableColumns,
			@UsingShadow = @UsingShadow,
			@Debug = 0;

	END

	SET @ErrorSection = 'Save SP';

	IF (@HasSaveProc = 'True')
	BEGIN
		
		-- DROP
		EXEC [MeDriAnchor].[sspDropSaveSP]
			@TableSchema = @TableSchema, 
			@TableName = @TableName,
			@Debug = 0;

		IF (@UsingShadowTable = 'True' AND @HasInsertTrigger = 'True' AND @HasUpdateTrigger = 'True')
		BEGIN
			-- has triggers so do not audit in the stored procedure
			SET @UsingShadow = 0;
		END
		ELSE
		BEGIN
			SET @UsingShadow = (CASE WHEN @UsingShadowTable = 'True' THEN 1 ELSE 0 END);
		END
		
		-- CREATE
		EXEC [MeDriAnchor].[sspCreateSaveSP]
			@TableSchema = @TableSchema,
			@TableName = @TableName,
			@TableColumnsCSSP = @TableColumns,
			@UsingShadow = @UsingShadow,
			@Debug = 0;

	END

	SET @ErrorSection = 'Delete Trigger';

	IF (@HasDeleteTrigger = 'True')
	BEGIN

		-- DROP
		EXEC [MeDriAnchor].[sspDropDeleteTrigger]
			@TableSchema = @TableSchema, 
			@TableName = @TableName,
			@Debug = 0;

		-- CREATE
		EXEC [MeDriAnchor].[sspCreateDeleteTrigger]
			@TableSchema = @TableSchema,
			@TableName = @TableName,
			@TableColumnsCDT = @TableColumns,
			@UsingShadow = @UsingShadow,
			@Debug = 0;

	END

	SET @ErrorSection = 'Update Trigger';

	IF (@HasUpdateTrigger = 'True')
	BEGIN

		-- DROP
		EXEC [MeDriAnchor].[sspDropUpdateTrigger]
			@TableSchema = @TableSchema, 
			@TableName = @TableName,
			@Debug = 0;
		
		-- CREATE
		EXEC [MeDriAnchor].[sspCreateUpdateTrigger]
			@TableSchema = @TableSchema,
			@TableName = @TableName,
			@TableColumnsCUT = @TableColumns,
			@UsingShadow = @UsingShadow,
			@Debug = 0;

	END

	SET @ErrorSection = 'Insert Trigger';

	IF (@HasInsertTrigger = 'True')
	BEGIN

		-- DROP
		EXEC [MeDriAnchor].[sspDropInsertTrigger]
			@TableSchema = @TableSchema, 
			@TableName = @TableName,
			@Debug = 0;
		
		-- CREATE
		EXEC [MeDriAnchor].[sspCreateInsertTrigger]
			@TableSchema = @TableSchema,
			@TableName = @TableName,
			@TableColumnsCIT = @TableColumns,
			@UsingShadow = @UsingShadow,
			@Debug = 0;

	END

	COMMIT TRANSACTION;

	RETURN 0;

END TRY

BEGIN CATCH

	DECLARE @ErrorMessage NVARCHAR(4000);
	DECLARE @ErrorSeverity INT;
	DECLARE @ErrorState INT;

	SELECT @ErrorMessage = @ErrorSection + '_' + @TableSchema + '_' + @TableName + ': ' + ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();

	RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);

	ROLLBACK TRANSACTION;

	RETURN -1;

END CATCH;
