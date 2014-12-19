CREATE PROCEDURE [MeDriAnchor].[amsp_ETLSQL_InitiateBatch]
(
@BatchDate DATETIME,
@Environment_ID SMALLINT,
@Debug BIT = 0,
@MetadataChanged BIT OUTPUT,
@ETLRun_ID BIGINT OUTPUT,
@Metadata_ID BIGINT OUTPUT,
@Batch_ID BIGINT OUTPUT,
@BatchDate_Previous DATETIME OUTPUT,
@Batch_ID_Previous BIGINT OUTPUT
)
AS
SET NUMERIC_ROUNDABORT OFF;

DECLARE @BatchTypeID SMALLINT;
DECLARE @RunningBatchID BIGINT;
DECLARE @RunningBatchDate DATETIME;
DECLARE @batchkillafterhours TINYINT;

SET @Metadata_ID = (SELECT MAX([Metadata_ID]) FROM [MeDriAnchor].[Metadata]);

DECLARE @WarningSeverity TINYINT = (SELECT [SeverityID] FROM [MeDriAnchor].[Severity] WHERE [ServerityName] = 'WARNING');
DECLARE @EnvironmentName NVARCHAR(100) = (SELECT [EnvironmentName] FROM [MeDriAnchor].[Environment] 
	WHERE [Environment_ID] = @Environment_ID);
DECLARE @ETLRun_ID_Used BIGINT;

SET NOCOUNT ON;

BEGIN TRY

	-- First check if another batch is running, if so drop straight out
	SELECT	TOP 1
			@RunningBatchID = [Batch_ID],
			@RunningBatchDate = [BatchDate]
	FROM [MeDriAnchor].[Batch] WHERE [InProgress] = 1;

	-- get the batch kill after n hours value
	SELECT @batchkillafterhours = MAX(CASE WHEN s.[SettingKey] = 'batchkillafterhours' THEN COALESCE(se.[SettingValue], s.[SettingValue]) ELSE '' END)
	FROM [MeDriAnchor].[Settings] s
	LEFT OUTER JOIN [MeDriAnchor].[SettingsEnvironment] se
		ON s.[SettingKey] = se.[SettingKey]
		AND se.Environment_ID = @Environment_ID
	WHERE s.[SettingKey] IN('batchkillafterhours');

	SET @batchkillafterhours = ISNULL(@batchkillafterhours, 2);

	IF (@RunningBatchID IS NOT NULL AND DATEDIFF(HOUR, @RunningBatchDate, GETDATE()) < @batchkillafterhours)
	BEGIN
		RAISERROR('Another batch is already running. Stopped.', 16, 1)
	END

	IF (@RunningBatchID IS NOT NULL AND DATEDIFF(HOUR, @RunningBatchDate, GETDATE()) > @batchkillafterhours)
	BEGIN
		-- batch over two hours old so stop it
		UPDATE [MeDriAnchor].[Batch] SET 
			[InProgress] = 0 
		WHERE [Batch_ID] = @RunningBatchID;
	END

	BEGIN TRAN;

	SET @MetadataChanged = (SELECT [MeDriAnchor].[fnHasMetadataChanged]());

	IF (@MetadataChanged = 1)
	BEGIN

		-- No metadata id as yet or it exists in one or more shadow tables so something has changed
		-- Either way a new one is needed
		INSERT INTO [MeDriAnchor].[Metadata]([MetadataDate]) VALUES (@BatchDate);
		SET @Metadata_ID = SCOPE_IDENTITY();

		-- Now stamp the new one on all relevant tables
		UPDATE [MeDriAnchor].[DBServerType] SET [Metadata_ID] = @Metadata_ID WHERE ISNULL([Metadata_ID], 0) <> @Metadata_ID;
		UPDATE [MeDriAnchor].[DBServer] SET [Metadata_ID] = @Metadata_ID WHERE ISNULL([Metadata_ID], 0) <> @Metadata_ID;
		UPDATE [MeDriAnchor].[DB] SET [Metadata_ID] = @Metadata_ID WHERE ISNULL([Metadata_ID], 0) <> @Metadata_ID;
		UPDATE [MeDriAnchor].[DBTable] SET [Metadata_ID] = @Metadata_ID WHERE ISNULL([Metadata_ID], 0) <> @Metadata_ID;
		UPDATE [MeDriAnchor].[DBTableColumn] SET [Metadata_ID] = @Metadata_ID WHERE ISNULL([Metadata_ID], 0) <> @Metadata_ID;
		UPDATE [MeDriAnchor].[DBTableTie] SET [Metadata_ID] = @Metadata_ID WHERE ISNULL([Metadata_ID], 0) <> @Metadata_ID;
		UPDATE [MeDriAnchor].[DBTableTieColumns] SET [Metadata_ID] = @Metadata_ID WHERE ISNULL([Metadata_ID], 0) <> @Metadata_ID;
		UPDATE [MeDriAnchor].[Settings] SET [Metadata_ID] = @Metadata_ID WHERE ISNULL([Metadata_ID], 0) <> @Metadata_ID;
		UPDATE [MeDriAnchor].[SettingsEnvironment] SET [Metadata_ID] = @Metadata_ID WHERE ISNULL([Metadata_ID], 0) <> @Metadata_ID;

	END
	ELSE
	BEGIN
		SET @Metadata_ID = (SELECT MAX(Metadata_ID) FROM [MeDriAnchor].[Metadata]);
	END

	-- create a new batch
	SELECT @BatchTypeID = [BatchTypeID]
	FROM [MeDriAnchor].[BatchType]
	WHERE [BatchType] = 'ETL';

	INSERT INTO [MeDriAnchor].[Batch]
		(
		[BatchTypeID],
		[BatchDescription],
		[BatchDate]
		)
	VALUES
		(
		@BatchTypeID,
		'(' + @EnvironmentName + ') ETL Batch' + (CASE WHEN @Debug = 1 THEN ' (DEBUG)' ELSE '' END),
		@BatchDate
		);

	SET @Batch_ID = SCOPE_IDENTITY();

	-- get the previous (successfull) batch for this environment
	SELECT	TOP 1
			@BatchDate_Previous = b.[BatchDate],
			@Batch_ID_Previous = etlr.[Batch_ID]
	FROM [MeDriAnchor].[ETLRun] etlr
	INNER JOIN [MeDriAnchor].[Batch] b
		ON etlr.[Batch_ID] = b.[Batch_ID]
	WHERE etlr.[Environment_ID] = @Environment_ID
		AND etlr.[Batch_ID] < @Batch_ID
		AND b.[BatchSuccessful] = 1
		AND b.[InProgress] = 0
	ORDER BY etlr.[Batch_ID] DESC;

	IF (@Batch_ID_Previous IS NULL OR NOT EXISTS(SELECT * FROM [MeDriAnchor].[ETLRunOrder]))
	BEGIN
		SET @MetadataChanged = 1;
	END

	-- generate the matedata mapping we need to use to build the ETL stored procedures (no need to do this if no changes to the metadata)
	IF (@MetadataChanged = 1)
	BEGIN

		-- link together as an ETL run
		INSERT INTO [MeDriAnchor].[ETLRun]
			(
			[Batch_ID],
			[Metadata_ID],
			[Environment_ID]
			)
		VALUES
			(
			@Batch_ID,
			@Metadata_ID,
			@Environment_ID
			);

		SET @ETLRun_ID = SCOPE_IDENTITY();

	END
	ELSE
	BEGIN
		-- link together as an ETL run (using the run details from th elast previous successfull run for this environment and metadata id
		SET @ETLRun_ID_Used = 
			(
			SELECT MAX(er.[ETLRun_ID]) -- last run for this metadata and environment
			FROM [MeDriAnchor].[ETLRun] er
			WHERE er.[Metadata_ID] = @Metadata_ID
				AND er.[Environment_ID] = @Environment_ID
				AND EXISTS (SELECT * FROM [MeDriAnchor].[ETLRunOrder] WHERE [ETLRun_ID] = er.[ETLRun_ID])
			);

		INSERT INTO [MeDriAnchor].[ETLRun]
			(
			[Batch_ID],
			[Metadata_ID],
			[Environment_ID],
			[ETLRun_ID_Used]
			)
		VALUES
			(
			@Batch_ID,
			@Metadata_ID,
			@Environment_ID,
			@ETLRun_ID_Used
			);

		-- if there is no valid previous run to use then flag as a metadata change to create new procedures
		IF (@ETLRun_ID_Used IS NULL)
		BEGIN
			SET @ETLRun_ID = SCOPE_IDENTITY();
			SET @MetadataChanged = 1;
		END
		ELSE
		BEGIN
			SET @ETLRun_ID = @ETLRun_ID_Used;
		END

	END

	COMMIT TRAN;

	RETURN 0;

END TRY

BEGIN CATCH

	DECLARE @ErrorMessage NVARCHAR(4000);
	DECLARE @ErrorSeverity INT;
	DECLARE @ErrorState INT;

	SELECT @ErrorMessage = ERROR_PROCEDURE() + ': ' + ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();

	ROLLBACK TRAN;

	RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);

	RETURN -1;

END CATCH;