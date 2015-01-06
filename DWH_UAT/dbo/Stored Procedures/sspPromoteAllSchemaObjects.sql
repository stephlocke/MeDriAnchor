CREATE PROCEDURE [dbo].[sspPromoteAllSchemaObjects]
(
	@MoveFromSchema SYSNAME,
	@MoveToSchema SYSNAME,
	@Debug BIT = 0
)
AS

SET NOCOUNT ON;

DECLARE @AnchorObjectName SYSNAME;

-- Promotion can ONLy be done in a combined DWH database - i.e one that has a 
-- _Schema table for each schema
IF NOT EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES
	WHERE (([TABLE_SCHEMA] = 'DwhDev' AND [TABLE_NAME] = '_Schema')
		AND ([TABLE_SCHEMA] = 'DwhUat' AND [TABLE_NAME] = '_Schema')
		AND ([TABLE_SCHEMA] = 'Dwh' AND [TABLE_NAME] = '_Schema')))
		THROW 51000, 'Schema promotion can only be done when only one DWH database is being used', 1;

BEGIN TRY

	BEGIN TRAN;

	DECLARE PROMOTION CURSOR
	READ_ONLY
	FOR
	SELECT QUOTENAME(t.[TABLE_SCHEMA]) + '.' + QUOTENAME(t.[TABLE_NAME])
	FROM INFORMATION_SCHEMA.TABLES t
	WHERE t.[TABLE_SCHEMA] = @MoveFromSchema
		AND t.[TABLE_TYPE] = 'BASE TABLE'
		AND t.[TABLE_NAME] NOT IN('_Schema');

	OPEN PROMOTION

	FETCH NEXT FROM PROMOTION INTO @AnchorObjectName;
	WHILE (@@fetch_status <> -1)
	BEGIN
		IF (@@fetch_status <> -2)
		BEGIN
			EXEC [dbo].[sspPromoteAnchorTable]
				@AnchorObjectName = @AnchorObjectName,
				@MoveToSchema = @MoveToSchema,
				@Debug = @Debug;
		END
		FETCH NEXT FROM PROMOTION INTO @AnchorObjectName;
	END

	CLOSE PROMOTION;
	DEALLOCATE PROMOTION;

	COMMIT TRAN;

END TRY

BEGIN CATCH

	DECLARE @ErrorMessage NVARCHAR(4000);
	DECLARE @ErrorSeverity INT;
	DECLARE @ErrorState INT;

	SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();

	ROLLBACK TRAN;

	RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);

	RETURN -1;

END CATCH;