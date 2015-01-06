CREATE PROC [MeDriAnchor].[amsp_ETLSQL_GenerateMetadataMap]
(
@Batch_ID BIGINT,
@Metadata_ID BIGINT,
@Environment_ID SMALLINT,
@Debug BIT = 0
)
AS
SET NUMERIC_ROUNDABORT OFF;
SET NOCOUNT ON;

DECLARE @SQL NVARCHAR(MAX) = '';
DECLARE @encapsulation NVARCHAR(100);
DECLARE @Type NVARCHAR(2);
DECLARE @Name SYSNAME;
DECLARE @KnotMnemonic NVARCHAR(100);
DECLARE @AnchorMnemonic NVARCHAR(100);
DECLARE @AttributeMnemonic NVARCHAR(100);
DECLARE @TieMnemonic NVARCHAR(100);
DECLARE @KnotRange NVARCHAR(100);

DECLARE @AnchorToMetadata TABLE
	(
	[Type] NVARCHAR(2),
	[Name] NVARCHAR(MAX),
	[KnotMnemonic] NVARCHAR(100), 
	[AnchorMnemonic] NVARCHAR(100), 
	[AttributeMnemonic] NVARCHAR(100),
	[TieMnemonic] NVARCHAR(100), 
	[KnotRange] NVARCHAR(100),
	[ID] BIGINT PRIMARY KEY
	);

BEGIN TRY

	--BEGIN TRANSACTION;

	INSERT INTO [MeDriAnchor].[EventAlerts]([Batch_ID],[SeverityID],[AlertMessage])
	VALUES(@Batch_ID, 1, 'Started creating the metadata mapping');

	-- clear the old mappings
	DELETE FROM [MeDriAnchor].[_AnchorToMetadataMap] 
	WHERE [Metadata_ID] <= @Metadata_ID
		AND [Environment_ID] = @Environment_ID;

	SELECT @encapsulation = MAX(CASE WHEN s.[SettingKey] = 'encapsulation' THEN COALESCE(se.[SettingValue], s.[SettingValue]) ELSE '' END)
	FROM [MeDriAnchor].[Settings] s
	LEFT OUTER JOIN [MeDriAnchor].[SettingsEnvironment] se
		ON s.[SettingKey] = se.[SettingKey]
		AND se.Environment_ID = @Environment_ID
	WHERE s.[SettingKey] IN('encapsulation');

	SET @SQL += 'SELECT  [Type], [Name], [KnotMnemonic], [AnchorMnemonic], [AttributeMnemonic], [TieMnemonic], [KnotRange], ROW_NUMBER() OVER (ORDER BY (CASE [Type] WHEN ''KN'' THEN 1 WHEN ''AN'' THEN 2 WHEN ''AT'' THEN 3 WHEN ''TI'' THEN 4 END), [Name]) AS [RunOrder] FROM ' + QUOTENAME(@encapsulation) + '.[_AnchorObjects];' + CHAR(13)
	
	INSERT INTO @AnchorToMetadata([Type], [Name], [KnotMnemonic], [AnchorMnemonic], [AttributeMnemonic], [TieMnemonic], [KnotRange], [ID])
	EXEC (@SQL);

	DECLARE ProcCreate CURSOR
	READ_ONLY FORWARD_ONLY STATIC LOCAL
	FOR 
	SELECT	[Type],
			[Name],
			[KnotMnemonic],
			[AnchorMnemonic],
			[AttributeMnemonic],
			[TieMnemonic],
			[KnotRange]
	FROM @AnchorToMetadata
	ORDER BY [ID];

	OPEN ProcCreate;

	FETCH NEXT FROM ProcCreate INTO @Type, @Name, @KnotMnemonic, @AnchorMnemonic, @AttributeMnemonic, @TieMnemonic, @KnotRange;
	WHILE (@@fetch_status <> -1)
	BEGIN
		IF (@@fetch_status <> -2)
		BEGIN

			IF (@Type = 'KN')
			BEGIN

				INSERT INTO [MeDriAnchor].[_AnchorToMetadataMap]
					(
					[Metadata_ID],
					[Environment_ID],
					[DBTableSchema],
					[DBTableName],
					[DBTableColumnName],
					[DWHTableName],
					[DWHTableColumnData],
					[JoinOrder],
					[JoinColumn],
					[JoinAlias],
					[DWHType],
					[DWHName],
					[KnotMnemonic],
					[AnchorMnemonic],
					[AttributeMnemonic],
					[TieMnemonic],
					[KnotRange],
					[PKColumn],
					[DateRestrictionColumn],
					[IsTextColumn],
					[IsMaterialisedColumn],
					[MaterialisedColumnFunction],
					[CreateNCIndexInDWH],
					[IsHistorised],
					[GenerateID],
					[DBTableColumnID]
					)
				SELECT	@Metadata_ID,
						@Environment_ID,
						QUOTENAME([DBTableSchema]),
						[DBTableName],
						QUOTENAME([DBTableColumnName]),
						[DWHTableName],
						QUOTENAME([DWHTableColumnData]),
						'' AS [JoinOrder],
						(CASE WHEN [KnotJoinColumn] <> '' THEN QUOTENAME([KnotJoinColumn]) ELSE '' END),
						@KnotMnemonic AS [JoinAlias],
						'Knot',
						@Name,
						@KnotMnemonic, 
						@AnchorMnemonic,
						@AttributeMnemonic,
						@TieMnemonic,
						@KnotRange,
						[PKColumn],
						(CASE WHEN [DateRestrictionColumn] <> '' THEN QUOTENAME([DateRestrictionColumn]) ELSE '' END),
						0 AS [IsTextColumn],
						0 AS [IsMaterialisedColumn],
						'' AS [MaterialisedColumnFunction],
						[CreateNCIndexInDWH],
						0 AS [IsHistorised],
						[GenerateID],
						[DBTableColumnID]
				FROM [MeDriAnchor].[fnGetKnotETLMetadata](@Name, @Environment_ID);

			END

			IF (@Type = 'AN')
			BEGIN

				INSERT INTO [MeDriAnchor].[_AnchorToMetadataMap]
					(
					[Metadata_ID],
					[Environment_ID],
					[DBTableSchema],
					[DBTableName],
					[DBTableColumnName],
					[DWHTableName],
					[DWHTableColumnData],
					[JoinOrder],
					[JoinColumn],
					[JoinAlias],
					[DWHType],
					[DWHName],
					[KnotMnemonic],
					[AnchorMnemonic],
					[AttributeMnemonic],
					[TieMnemonic],
					[KnotRange],
					[PKColumn],
					[DateRestrictionColumn],
					[IsTextColumn],
					[IsMaterialisedColumn],
					[MaterialisedColumnFunction],
					[CreateNCIndexInDWH],
					[IsHistorised],
					[GenerateID],
					[DBTableColumnID]
					)
				SELECT	@Metadata_ID,
						@Environment_ID,
						QUOTENAME([DBTableSchema]),
						[DBTableName],
						QUOTENAME([DBTableColumnName]),
						[DWHTableName],
						QUOTENAME([DWHTableColumnData]),
						'' AS [JoinOrder],
						'' AS [JoinColumn],
						@AnchorMnemonic AS [JoinAlias],
						'Anchor',
						@Name,
						@KnotMnemonic, 
						@AnchorMnemonic,
						@AttributeMnemonic,
						@TieMnemonic,
						@KnotRange,
						[PKColumn],
						(CASE WHEN [DateRestrictionColumn] <> '' THEN QUOTENAME([DateRestrictionColumn]) ELSE '' END),
						0 AS [IsTextColumn],
						0 AS [IsMaterialisedColumn],
						'' AS [MaterialisedColumnFunction],
						[CreateNCIndexInDWH],
						0 AS [IsHistorised],
						[GenerateID],
						[DBTableColumnID]
				FROM [MeDriAnchor].[fnGetAnchorETLMetadata](@Name, @Environment_ID);

			END

			IF (@Type = 'AT')
			BEGIN

				INSERT INTO [MeDriAnchor].[_AnchorToMetadataMap]
					(
					[Metadata_ID],
					[Environment_ID],
					[DBTableSchema],
					[DBTableName],
					[DBTableColumnName],
					[DWHTableName],
					[DWHTableColumnData],
					[JoinOrder],
					[JoinColumn],
					[JoinAlias],
					[DWHType],
					[DWHName],
					[KnotMnemonic],
					[AnchorMnemonic],
					[AttributeMnemonic],
					[TieMnemonic],
					[KnotRange],
					[PKColumn],
					[DateRestrictionColumn],
					[IsTextColumn],
					[IsMaterialisedColumn],
					[MaterialisedColumnFunction],
					[CreateNCIndexInDWH],
					[IsHistorised],
					[GenerateID],
					[DBTableColumnID]
					)
				SELECT	@Metadata_ID,
						@Environment_ID,
						QUOTENAME([DBTableSchema]),
						QUOTENAME([DBTableName]),
						QUOTENAME([DBTableColumnName]),
						[DWHTableName],
						QUOTENAME([DWHTableColumnData]),
						'' AS [JoinOrder],
						'' AS [JoinColumn],
						[AttributeMnemonic] AS [JoinAlias],
						'Attribute',
						@Name,
						@KnotMnemonic, 
						@AnchorMnemonic,
						@AttributeMnemonic,
						@TieMnemonic,
						@KnotRange,
						[PKColumn],
						(CASE WHEN [DateRestrictionColumn] <> '' THEN QUOTENAME([DateRestrictionColumn]) ELSE '' END),
						[IsTextColumn],
						[IsMaterialisedColumn],
						[MaterialisedColumnFunction],
						[CreateNCIndexInDWH],
						[IsHistorised],
						[GenerateID],
						[DBTableColumnID]
				FROM [MeDriAnchor].[fnGetAttributeETLMetadata](@Name, @Environment_ID);

			END

			IF (@Type = 'TI')
			BEGIN

				INSERT INTO [MeDriAnchor].[_AnchorToMetadataMap]
					(
					[Metadata_ID],
					[Environment_ID],
					[DBTableSchema],
					[DBTableName],
					[DBTableColumnName],
					[DWHTableName],
					[DWHTableColumnData],
					[JoinOrder],
					[JoinColumn],
					[JoinAlias],
					[DWHType],
					[DWHName],
					[KnotMnemonic],
					[AnchorMnemonic],
					[AttributeMnemonic],
					[TieMnemonic],
					[KnotRange],
					[PKColumn],
					[DateRestrictionColumn],
					[IsTextColumn],
					[IsMaterialisedColumn],
					[MaterialisedColumnFunction],
					[CreateNCIndexInDWH],
					[IsHistorised],
					[GenerateID],
					[DBTableColumnID]
					)
				SELECT	@Metadata_ID,
						@Environment_ID,
						QUOTENAME([DBTableSchema]),
						[DBTableName],
						QUOTENAME([SourcePKColumnName]),
						[DWHDBTableName],
						QUOTENAME([TieDBColumnName]),
						[TieJoinOrder],
						(CASE WHEN [TieJoinColumn] <> '' THEN QUOTENAME([TieJoinColumn]) ELSE '' END),
						[TableAlias] AS [JoinAlias],
						'Tie',
						@Name,
						@KnotMnemonic, 
						@AnchorMnemonic,
						@AttributeMnemonic,
						@TieMnemonic,
						@KnotRange,
						1 AS [PKColumn],
						(CASE WHEN [DateRestrictionColumn] <> '' THEN QUOTENAME([DateRestrictionColumn]) ELSE '' END),
						0 AS [IsTextColumn],
						0 AS [IsMaterialisedColumn],
						'' AS [MaterialisedColumnFunction],
						[CreateNCIndexInDWH],
						[IsHistorised],
						[GenerateID],
						[DBTableColumnID]
				FROM [MeDriAnchor].[fnGetTieETLMetadata](@Name, @Environment_ID);

			END

		END
		FETCH NEXT FROM ProcCreate INTO @Type, @Name, @KnotMnemonic, @AnchorMnemonic, @AttributeMnemonic, @TieMnemonic, @KnotRange;
	END

	CLOSE ProcCreate;
	DEALLOCATE ProcCreate;

	INSERT INTO [MeDriAnchor].[EventAlerts]([Batch_ID],[SeverityID],[AlertMessage])
	VALUES(@Batch_ID, 1, 'Finished creating the metadata mapping');

	--COMMIT TRAN;

	RETURN 0;

END TRY

BEGIN CATCH

	DECLARE @ErrorMessage NVARCHAR(4000);
	DECLARE @ErrorSeverity INT;
	DECLARE @ErrorState INT;

	SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();

	RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);

	--ROLLBACK TRANSACTION;

	INSERT INTO [MeDriAnchor].[EventAlerts]([Batch_ID],[SeverityID],[AlertMessage])
	VALUES(@Batch_ID, 4, 'Error creating the metadata mapping: ' + @ErrorMessage);

	RETURN -1;

END CATCH;
