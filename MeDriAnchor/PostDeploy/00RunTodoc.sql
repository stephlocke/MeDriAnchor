
PRINT 'Start: Running Todoc...';

SET NOCOUNT ON;

/*
--------------------------------------------------------------------------------------
RUN ALL MEDRIANCHOR-ENABLED TABLES THROUGH THE ADMINISTER ROUTINE

YOU MAY ALTER THIS CODE AS YOU WISH. KNOCK YOURSELF OUT BUT...THIS CODE AND 
INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED 
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY 
AND/OR FITNESS FOR A PARTICULAR PURPOSE.
--------------------------------------------------------------------------------------
*/

DECLARE @TableSchema SYSNAME;
DECLARE @TableName SYSNAME;

EXECUTE AS USER = 'MeDriAnchorUser';

DECLARE TodocTables CURSOR
READ_ONLY FORWARD_ONLY LOCAL STATIC
FOR
SELECT	nht.TableSchema, 
		nht.TableName
FROM [MeDriAnchor].[svNonHeapTables] nht
INNER JOIN [MeDriAnchor].[svActiveTables] at
	ON nht.[schema_id] = at.[schema_id]
	AND nht.[object_id] = at.[object_id]
WHERE nht.TableSchema = 'MeDriAnchor'
	AND nht.TableName NOT IN('EventAlerts', 'Metadata', 'ETLRun', 'ETLRunOrder')
ORDER BY nht.TableSchema, nht.TableName;

OPEN TodocTables

PRINT 'Administering MeDriAnchor objects for:'

FETCH NEXT FROM TodocTables INTO @TableSchema, @TableName
WHILE (@@fetch_status <> -1)
BEGIN
	IF (@@fetch_status <> -2)
	BEGIN

		PRINT @TableSchema + '.' + @TableName;

		-- run whatever MeDriAnchor is required for this table
		BEGIN TRY
			EXEC [MeDriAnchor].[sspAdministerObjects] 
				@TableSchema = @TableSchema, 
				@TableName = @TableName;
		END TRY
		BEGIN CATCH
			SELECT ERROR_MESSAGE();
			ROLLBACK TRAN;
		END CATCH

	END
	FETCH NEXT FROM TodocTables INTO @TableSchema, @TableName
END

CLOSE TodocTables
DEALLOCATE TodocTables;

REVERT;
GO

PRINT 'END: Running Todoc...';
GO