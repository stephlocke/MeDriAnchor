
CREATE PROCEDURE [dbo].[sspDropAllTriggers]
AS

DECLARE @SQL NVARCHAR(MAX) = '';

BEGIN TRY

	BEGIN TRAN;

	SELECT @SQL += 'DROP TRIGGER [' + ISNULL(tbl.name, vue.name) + '].[' + trg.name + '];' + CHAR(13)
	FROM sys.triggers trg
	LEFT OUTER JOIN (SELECT tparent.object_id, ts.name 
					 FROM sys.tables tparent 
					 INNER JOIN sys.schemas ts ON TS.schema_id = tparent.SCHEMA_ID) 
					 AS tbl ON tbl.OBJECT_ID = trg.parent_id
	LEFT OUTER JOIN (SELECT vparent.object_id, vs.name 
					 FROM sys.views vparent 
					 INNER JOIN sys.schemas vs ON vs.schema_id = vparent.SCHEMA_ID) 
					 AS vue ON vue.OBJECT_ID = trg.parent_id;

	EXEC sp_executesql @SQL;

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