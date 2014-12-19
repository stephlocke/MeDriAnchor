CREATE PROCEDURE [MeDriAnchor].[sspFlagBatchStatus]
(
@Batch_ID BIGINT
)
AS
SET NOCOUNT ON;

DECLARE @Body NVARCHAR(MAX) = '';
DECLARE @StartTime DATETIME;
DECLARE @EndTime DATETIME;
DECLARE @ValidationFailures BIGINT;
DECLARE @RecordCount BIGINT;
DECLARE @ErrorCount BIGINT;
DECLARE @MetadataChange BIT = 0;

BEGIN TRAN;

BEGIN TRY

	SELECT 
		@StartTime = MIN([AlertDate]),
		@EndTime = MAX([AlertDate]),
		@ValidationFailures = SUM(CASE WHEN [SeverityID] = 2 THEN 1 ELSE 0 END),
		@RecordCount = SUM(ISNULL([RecordsInserted], 0)),
		@ErrorCount = SUM(CASE WHEN [SeverityID] > 3 THEN 1 ELSE 0 END)
	FROM [MeDriAnchor].[EventAlerts]
	WHERE [Batch_ID] = @Batch_ID;

	IF EXISTS(SELECT * FROM [MeDriAnchor].[EventAlerts] WHERE [Batch_ID] = @Batch_ID
		AND [AlertMessage] = 'Metadata change identified')
		SET @MetadataChange = 1;

	SET @Body += 'Batch ID: ' + CONVERT(NVARCHAR(10), @Batch_ID) + ' Completed.' + CHAR(10);
	SET @Body += 'Start Time: ' + CONVERT(NVARCHAR(20), @StartTime, 113) + CHAR(10);
	SET @Body += 'End Time: ' + CONVERT(NVARCHAR(20), @EndTime, 113) + CHAR(10);
	SET @Body += 'Metadata change: ' + (CASE WHEN @MetadataChange = 1 THEN 'Yes' ELSE 'No' END) + CHAR(10);
	SET @Body += 'Validation failures: ' + CONVERT(NVARCHAR(10), @ValidationFailures) + CHAR(10);
	SET @Body += 'Record Count: ' + CONVERT(NVARCHAR(10), @RecordCount) + CHAR(10);
	SET @Body += 'Error Count: ' + CONVERT(NVARCHAR(10), @ErrorCount) + CHAR(10);

	IF EXISTS(SELECT * FROM [MeDriAnchor].[EventAlerts] WHERE [Batch_ID] = @Batch_ID AND [SeverityID] > 3)
	BEGIN
		-- issues (non-info and validation messages present)
		UPDATE [MeDriAnchor].[Batch] SET [BatchSuccessful] = 0, [InProgress] = 0 WHERE [Batch_ID] = @Batch_ID;

		EXEC msdb.dbo.sp_send_dbmail 
			@profile_name = 'CROW Mail', 
			@recipients = 'james.skipwith@OPTIMUMCREDIT.co.uk;stephanie.locke@optimumcredit.co.uk', 
			@subject = 'CROW ETL Batch: Failure', 
			@body = @Body, 
			@body_format = 'text';

	END
	ELSE
	BEGIN
		-- success (all info and validation messages)
		UPDATE [MeDriAnchor].[Batch] SET [BatchSuccessful] = 1, [InProgress] = 0 WHERE [Batch_ID] = @Batch_ID;

		EXEC msdb.dbo.sp_send_dbmail 
			@profile_name = 'CROW Mail', 
			@recipients = 'james.skipwith@OPTIMUMCREDIT.co.uk;stephanie.locke@optimumcredit.co.uk', 
			@subject = 'CROW ETL Batch: Success', 
			@body = @Body, 
			@body_format = 'text';

	END

	COMMIT TRANSACTION;

	RETURN 0;

END TRY

BEGIN CATCH

	DECLARE @ErrorMessage NVARCHAR(4000);
	DECLARE @ErrorSeverity INT;
	DECLARE @ErrorState INT;

	RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);

	ROLLBACK TRANSACTION;

	RETURN -1;

END CATCH;