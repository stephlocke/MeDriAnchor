CREATE PROCEDURE [dbo].[sspIndexMaintenance]
AS
SET NOCOUNT ON;

DECLARE @objectid int;
DECLARE @indexid int;
DECLARE @partitioncount bigint;
DECLARE @schemaname nvarchar(130); 
DECLARE @objectname nvarchar(130); 
DECLARE @indexname nvarchar(130); 
DECLARE @partitionnum bigint;
DECLARE @partitions bigint;
DECLARE @frag float;
DECLARE @command nvarchar(4000); 

BEGIN TRY

	PRINT N'Started index maintenance.';

	DECLARE @work_to_do TABLE
		(
		objectid INT,
		index_id INT,
		partition_number INT,
		avg_fragmentation_in_percent FLOAT
		);

	-- Conditionally select tables and indexes from the sys.dm_db_index_physical_stats function 
	-- and convert object and index IDs to names.
	INSERT INTO @work_to_do
	SELECT
		object_id AS objectid,
		index_id AS indexid,
		partition_number AS partitionnum,
		avg_fragmentation_in_percent AS frag
	FROM sys.dm_db_index_physical_stats (DB_ID(), NULL, NULL , NULL, 'LIMITED')
	WHERE avg_fragmentation_in_percent > 20.0 AND index_id > 0;

	-- Declare the cursor for the list of partitions to be processed.
	DECLARE partitions CURSOR FOR SELECT * FROM @work_to_do;

	-- Open the cursor.
	OPEN partitions;

	-- Loop through the partitions.
	WHILE (1=1)
		BEGIN;
			FETCH NEXT
			   FROM partitions
			   INTO @objectid, @indexid, @partitionnum, @frag;
			IF @@FETCH_STATUS < 0 BREAK;
			SELECT @objectname = QUOTENAME(o.name), @schemaname = QUOTENAME(s.name)
			FROM sys.objects AS o
			JOIN sys.schemas as s ON s.schema_id = o.schema_id
			WHERE o.object_id = @objectid;
			SELECT @indexname = QUOTENAME(name)
			FROM sys.indexes
			WHERE  object_id = @objectid AND index_id = @indexid;

	-- 30 is an arbitrary decision point at which to switch between reorganizing and rebuilding.
			--IF @frag < 30.0
			--	SET @command = N'ALTER INDEX ' + @indexname + N' ON ' + @schemaname + N'.' + @objectname + N' REORGANIZE';
			IF @frag >= 20.0
				SET @command = N'ALTER INDEX ' + @indexname + N' ON ' + @schemaname + N'.' + @objectname + N' REBUILD WITH (ONLINE=ON)';
			EXEC (@command);
			--PRINT N'Executed: ' + @command;
		END;

	-- Close and deallocate the cursor.
	CLOSE partitions;
	DEALLOCATE partitions;

	PRINT N'Completed index maintenance.';

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