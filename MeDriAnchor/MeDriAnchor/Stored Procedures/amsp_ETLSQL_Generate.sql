CREATE PROC [MeDriAnchor].[amsp_ETLSQL_Generate]
(
@Environment_ID SMALLINT,
@DBID BIGINT = NULL,
@Debug BIT = 0, -- if 0 then generates the procedures and runs, if 1 generates the procedures but doesn't run
@ETLRun_ID BIGINT OUTPUT,
@Metadata_ID BIGINT OUTPUT,
@Batch_ID BIGINT OUTPUT
)
AS
SET NUMERIC_ROUNDABORT OFF;
SET NOCOUNT ON;

DECLARE @InfoSeverity TINYINT = (SELECT [SeverityID] FROM [MeDriAnchor].[Severity] WHERE [ServerityName] = 'INFO');
DECLARE @WarningSeverity TINYINT = (SELECT [SeverityID] FROM [MeDriAnchor].[Severity] WHERE [ServerityName] = 'WARNING');
DECLARE @Type NVARCHAR(2);
DECLARE @Name NVARCHAR(MAX);
DECLARE @ProcedureName SYSNAME;
DECLARE @ToMake TABLE
	(
	[Type] NVARCHAR(2),
	[Name] NVARCHAR(MAX),
	[KnotRange] NVARCHAR(7),
	[RunOrder] INT PRIMARY KEY CLUSTERED
	);
DECLARE @RunOrder INT;
DECLARE @SQL NVARCHAR(MAX) = '';
DECLARE @encapsulation NVARCHAR(100);
DECLARE @KnotRange NVARCHAR(7);
DECLARE @KnotName SYSNAME;
DECLARE @KnotSQL NVARCHAR(MAX) = '';
DECLARE @knotParams NVARCHAR(1000) = N'@KnotName SYSNAME OUTPUT';
DECLARE @MetadataChanged BIT = 0;
DECLARE @GenerateErrorMessage NVARCHAR(4000) = '';
DECLARE @StageData BIT;

BEGIN TRY

	IF (@DBID IS NULL)
	BEGIN
		SELECT	@DBID = [DBID],
				@StageData = [StageData]
		FROM [MeDriAnchor].[DB] 
		WHERE ([Environment_ID] IS NULL 
			OR [Environment_ID] = @Environment_ID);
	END

	-- get the DWH schema to use
	SELECT @encapsulation = MAX(CASE WHEN s.[SettingKey] = 'encapsulation' THEN COALESCE(se.[SettingValue], s.[SettingValue]) ELSE '' END)
	FROM [MeDriAnchor].[Settings] s
	LEFT OUTER JOIN [MeDriAnchor].[SettingsEnvironment] se
		ON s.[SettingKey] = se.[SettingKey]
		AND se.Environment_ID = @Environment_ID
	WHERE s.[SettingKey] IN('encapsulation');

	-- loop through dropping and creating procs in the running table

	-- Get the Anchor objects to (re)create
	-- Knots -> Anchors -> Attributes -> Ties
	SET @SQL += 'SELECT  [Type], [Name], [KnotRange], ROW_NUMBER() OVER (ORDER BY (CASE [Type] WHEN ''KN'' THEN 1 WHEN ''AN'' THEN 2 WHEN ''AT'' THEN 3 WHEN ''TI'' THEN 4 END), [Name]) AS [RunOrder] FROM ' + QUOTENAME(@encapsulation) + '.[_AnchorObjects];' + CHAR(13)
	
	INSERT INTO @ToMake([Type], [Name], [KnotRange], [RunOrder])
	EXEC (@SQL);

	-- (re)create the knots
	DECLARE ProcCreate CURSOR
	READ_ONLY FORWARD_ONLY STATIC LOCAL
	FOR 
	SELECT	[Type],
			[Name],
			[KnotRange],
			[RunOrder]
	FROM @ToMake
	ORDER BY [RunOrder];

	OPEN ProcCreate;

	FETCH NEXT FROM ProcCreate INTO @Type, @Name, @KnotRange, @RunOrder;
	WHILE (@@fetch_status <> -1)
	BEGIN
		IF (@@fetch_status <> -2)
		BEGIN

			IF (@Type = 'KN')
			BEGIN

				BEGIN TRY

					SET @ProcedureName = '';

					-- Create
					EXEC [MeDriAnchor].[sspCreateKnotETLSQL] 
						@KnotName = @name, 
						@Batch_ID = @Batch_ID, 
						@Metadata_ID = @Metadata_ID, 
						@Environment_ID = @Environment_ID, 
						@Debug = 0,
						@StageData = @StageData,
						@ProcName = @ProcedureName OUTPUT;

					INSERT INTO [MeDriAnchor].[EventAlerts]
						(
						[Batch_ID],
						[SeverityID],
						[AlertMessage]
						)
					VALUES
						(
						@Batch_ID,
						@InfoSeverity,
						'Created ETL for knot ' + @name
						);
						
				END TRY
				BEGIN CATCH

					SET @GenerateErrorMessage = ('Error creating ETL procedure for Knot ' + @name 
						+ '. Error: ' + ERROR_MESSAGE());

					INSERT INTO [MeDriAnchor].[EventAlerts]
						(
						[Batch_ID],
						[SeverityID],
						[AlertMessage]
						)
					VALUES
						(
						@Batch_ID,
						@WarningSeverity,
						@GenerateErrorMessage
						);

				END CATCH

			END

			IF (@Type = 'AN')
			BEGIN

				BEGIN TRY

					SET @ProcedureName = '';

					-- Create (standard)
					EXEC [MeDriAnchor].[sspCreateAnchorETLSQL] 
						@AnchorName = @name, 
						@Batch_ID = @Batch_ID, 
						@Metadata_ID = @Metadata_ID, 
						@Environment_ID = @Environment_ID, 
						@Debug = 0,
						@StageData = @StageData,
						@ProcName = @ProcedureName OUTPUT;

					INSERT INTO [MeDriAnchor].[EventAlerts]
						(
						[Batch_ID],
						[SeverityID],
						[AlertMessage]
						)
					VALUES
						(
						@Batch_ID,
						@InfoSeverity,
						'Created ETL for Anchor ' + @name
						);

				END TRY
				BEGIN CATCH

					SET @GenerateErrorMessage = ('Error creating ETL procedure for Anchor ' + @name 
						+ '. Error: ' + ERROR_MESSAGE());

					INSERT INTO [MeDriAnchor].[EventAlerts]
						(
						[Batch_ID],
						[SeverityID],
						[AlertMessage]
						)
					VALUES
						(
						@Batch_ID,
						@WarningSeverity,
						@GenerateErrorMessage
						);

				END CATCH

			END

			IF (@Type = 'AT')
			BEGIN

				BEGIN TRY

					SET @ProcedureName = '';

					IF (@KnotRange = '')
					BEGIN

						-- Create
						EXEC [MeDriAnchor].[sspCreateAttributeETLSQL] 
							@AttributeName = @name, 
							@Batch_ID = @Batch_ID, 
							@Metadata_ID = @Metadata_ID, 
							@Environment_ID = @Environment_ID, 
							@Debug = 0,
							@StageData = @StageData,
							@ProcName = @ProcedureName OUTPUT;

						INSERT INTO [MeDriAnchor].[EventAlerts]
							(
							[Batch_ID],
							[SeverityID],
							[AlertMessage]
							)
						VALUES
							(
							@Batch_ID,
							@InfoSeverity,
							'Created ETL for Attribute ' + @name
							);

					END
					ELSE
					BEGIN

						-- look up knot name
						SET @KnotSQL += 'SELECT @KnotName = [name] FROM [' + @encapsulation + '].[_AnchorObjects] WHERE [Type] = ''KN'' and [KnotMnemonic] = ''' + @KnotRange + ''';'

						EXEC sys.sp_executesql @KnotSQL, @knotParams,
								@KnotName = @KnotName OUTPUT;

						-- Create (knotted)
						EXEC [MeDriAnchor].[sspCreateAttributeKnotETLSQL] 
							@AttributeName = @name, 
							@KnotName = @KnotName,
							@Batch_ID = @Batch_ID, 
							@Metadata_ID = @Metadata_ID, 
							@Environment_ID = @Environment_ID, 
							@Debug = 0,
							@StageData = @StageData,
							@ProcName = @ProcedureName OUTPUT;

						INSERT INTO [MeDriAnchor].[EventAlerts]
							(
							[Batch_ID],
							[SeverityID],
							[AlertMessage]
							)
						VALUES
							(
							@Batch_ID,
							@InfoSeverity,
							'Created ETL for Attribute (Knotted) ' + @name
							);

					END

				END TRY
				BEGIN CATCH

					SET @GenerateErrorMessage = ('Error creating ETL procedure for Attribute ' + @name 
						+ '. Error: ' + ERROR_MESSAGE());

					INSERT INTO [MeDriAnchor].[EventAlerts]
						(
						[Batch_ID],
						[SeverityID],
						[AlertMessage]
						)
					VALUES
						(
						@Batch_ID,
						@WarningSeverity,
						@GenerateErrorMessage
						);

				END CATCH

			END

			IF (@Type = 'TI')
			BEGIN

				BEGIN TRY

					SET @ProcedureName = '';

					-- Create
					EXEC [MeDriAnchor].[sspCreateTieETLSQL] 
						@TieName = @name, 
						@Batch_ID = @Batch_ID, 
						@Metadata_ID = @Metadata_ID, 
						@Environment_ID = @Environment_ID, 
						@Debug = 0,
						@StageData = @StageData,
						@ProcName = @ProcedureName OUTPUT;

					INSERT INTO [MeDriAnchor].[EventAlerts]
						(
						[Batch_ID],
						[SeverityID],
						[AlertMessage]
						)
					VALUES
						(
						@Batch_ID,
						@InfoSeverity,
						'Created ETL for Tie ' + @name
						);

				END TRY
				BEGIN CATCH

					SET @GenerateErrorMessage = ('Error creating ETL procedure for Tie ' + @name 
						+ '. Error: ' + ERROR_MESSAGE());

					INSERT INTO [MeDriAnchor].[EventAlerts]
						(
						[Batch_ID],
						[SeverityID],
						[AlertMessage]
						)
					VALUES
						(
						@Batch_ID,
						@WarningSeverity,
						@GenerateErrorMessage
						);

				END CATCH

			END

			-- log the row in the running order table for this ETL
			IF (@ProcedureName <> '')
			BEGIN

				INSERT INTO [MeDriAnchor].[ETLRunOrder]
					(
					[ETLRun_ID],
					[SPOrder],
					[SPName]
					)
				VALUES
					(
					@ETLRun_ID,
					@RunOrder,
					@ProcedureName
					);

			END

		END
		FETCH NEXT FROM ProcCreate INTO @Type, @Name, @KnotRange, @RunOrder;
	END

	CLOSE ProcCreate;
	DEALLOCATE ProcCreate;

	RETURN 0;

END TRY

BEGIN CATCH

	DECLARE @ErrorMessage NVARCHAR(4000);
	DECLARE @ErrorSeverity INT;
	DECLARE @ErrorState INT;

	SELECT @ErrorMessage = ERROR_PROCEDURE() + ': ' + ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();

	RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);

	RETURN -1;

END CATCH;