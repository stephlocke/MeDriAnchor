
-- DELETE ALL OBJECTS
CREATE PROCEDURE [MeDriAnchor].[sspDeleteAllObjectsOfType]
(
@ObjectType NVARCHAR(20)
)
AS
/*
DELETES ALL MeDriAnchor OBJECTS OF A GIVEN TYPE FROM THE DATABASE
*/
SET NOCOUNT ON;

-- reject calls to delete anything we don't know about
IF (@ObjectType NOT IN('DeleteSP', 'InsertSP', 'SaveSP', 'Shadow', 
	'UpdateSP', 'View', 'DeleteTrigger', 'UpdateTrigger', 'InsertTrigger'))
BEGIN
	PRINT 'The @ObjectType parameter must be one the following values: DeleteSP, InsertSP, SaveSP, Shadow, UpdateSP, View, DeleteTrigger, UpdateTrigger, or InsertTrigger';
	RETURN;
END

DECLARE @SQL_DROP NVARCHAR(MAX) = '';
DECLARE @TableSchema SYSNAME;
DECLARE @TableName SYSNAME;

BEGIN TRANSACTION;

BEGIN TRY

	DECLARE TodocTables CURSOR
	READ_ONLY FORWARD_ONLY LOCAL STATIC
	FOR
	SELECT	nht.TableSchema, 
			nht.TableName
	FROM [MeDriAnchor].[svNonHeapTables] nht
	INNER JOIN [MeDriAnchor].[svActiveTables] at
		ON nht.[schema_id] = at.[schema_id]
		AND nht.[object_id] = at.[object_id]
	ORDER BY nht.TableSchema, nht.TableName;

	OPEN TodocTables

	PRINT 'Deleting MeDriAnchor ' + @ObjectType + ' for:'

	FETCH NEXT FROM TodocTables INTO @TableSchema, @TableName
	WHILE (@@fetch_status <> -1)
	BEGIN
		IF (@@fetch_status <> -2)
		BEGIN

			PRINT @TableSchema + '.' + @TableName;

			-- call the relevant delete function based on @ObjectType and execute
			IF (@ObjectType = 'DeleteSP')
			BEGIN
				EXEC [MeDriAnchor].[sspDropDeleteSP] 
					@TableSchema, 
					@TableName,
					@Debug = 0
			END
			ELSE IF (@ObjectType = 'InsertSP')
			BEGIN
				EXEC [MeDriAnchor].[sspDropInsertSP] 
					@TableSchema, 
					@TableName,
					@Debug = 0
			END
			ELSE IF (@ObjectType = 'SaveSP')
			BEGIN
				EXEC [MeDriAnchor].[sspDropSaveSP] 
					@TableSchema, 
					@TableName,
					@Debug = 0
			END
			ELSE IF (@ObjectType = 'Shadow')
			BEGIN
				EXEC [MeDriAnchor].[sspDropShadowTable] 
					@TableSchema, 
					@TableName,
					@Debug = 0
			END
			ELSE IF (@ObjectType = 'UpdateSP')
			BEGIN
				EXEC [MeDriAnchor].[sspDropUpdateSP] 
					@TableSchema, 
					@TableName,
					@Debug = 0
			END
			ELSE IF (@ObjectType = 'View')
			BEGIN
				EXEC [MeDriAnchor].[sspDropView] 
					@TableSchema, 
					@TableName,
					@Debug = 0
			END
			ELSE IF (@ObjectType = 'DeleteTrigger')
			BEGIN
				EXEC [MeDriAnchor].[sspDropDeleteTrigger] 
					@TableSchema, 
					@TableName,
					@Debug = 0
			END
			ELSE IF (@ObjectType = 'UpdateTrigger')
			BEGIN
				EXEC [MeDriAnchor].[sspDropUpdateTrigger] 
					@TableSchema, 
					@TableName,
					@Debug = 0
			END
			ELSE IF (@ObjectType = 'InsertTrigger')
			BEGIN
				EXEC [MeDriAnchor].[sspDropInsertTrigger] 
					@TableSchema, 
					@TableName,
					@Debug = 0
			END

		END
		FETCH NEXT FROM TodocTables INTO @TableSchema, @TableName
	END

	CLOSE TodocTables
	DEALLOCATE TodocTables;

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
