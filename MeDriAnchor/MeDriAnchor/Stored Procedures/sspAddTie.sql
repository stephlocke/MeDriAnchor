CREATE PROCEDURE [MeDriAnchor].[sspAddTie]
(
@TieMnemonic NVARCHAR(20),
@GenerateID BIT = 0,
@IsHistorised BIT = 1,
@KnotMnemonic NVARCHAR(20) = '',
@KnotRoleName NVARCHAR(50) = '',
@J1AnchorMnemonicRef NVARCHAR(3),
@J1DBTableSchema SYSNAME,
@J1DBTableName SYSNAME,
@J1DBTableColumnName SYSNAME,
@J1RoleName NVARCHAR(50),
@J1TieJoinOrder SMALLINT = 1,
@J1TieJoinColumn SYSNAME,
@J1IsIdentity BIT = 1,
@J2AnchorMnemonicRef NVARCHAR(3),
@J2DBTableSchema SYSNAME,
@J2DBTableName SYSNAME,
@J2DBTableColumnName SYSNAME,
@J2RoleName NVARCHAR(50),
@J2TieJoinOrder SMALLINT = 2,
@J2TieJoinColumn SYSNAME,
@J2IsIdentity BIT = 1
)
AS
SET NOCOUNT ON;

DECLARE @TieID INT;
DECLARE @J1DBTableColumnID BIGINT;
DECLARE @J2DBTableColumnID BIGINT;

-- Validate the first table
DECLARE @J1DBTableID BIGINT = (SELECT [DBTableID] FROM [MeDriAnchor].[DBTable] WHERE [DBTableSchema] = @J1DBTableSchema
	AND [DBTableName] = @J1DBTableName); -- table or view that contains the anchor

-- validate the table or view is one we know about
IF (@J1DBTableID IS NULL)
	THROW 51000, 'No table matches @J1DBTableSchema and @J1DBTableName.', 1;

IF NOT EXISTS (SELECT * FROM [MeDriAnchor].[DBTableColumn] WHERE [DBTableID] = @J1DBTableID
	AND [DBTableColumnName] = @J1DBTableColumnName)
	THROW 51000, '@J1DBTableColumnName does not exists in this table.', 1;

-- Validate the second table
DECLARE @J2DBTableID BIGINT = (SELECT [DBTableID] FROM [MeDriAnchor].[DBTable] WHERE [DBTableSchema] = @J2DBTableSchema
	AND [DBTableName] = @J2DBTableName); -- table or view that contains the anchor

-- validate the table or view is one we know about
IF (@J2DBTableID IS NULL)
	THROW 51000, 'No table matches @J1DBTableSchema and @J1DBTableName.', 1;

IF NOT EXISTS (SELECT * FROM [MeDriAnchor].[DBTableColumn] WHERE [DBTableID] = @J2DBTableID
	AND [DBTableColumnName] = @J2DBTableColumnName)
	THROW 51000, '@J2DBTableColumnName does not exists in this table.', 1;

BEGIN TRAN;

BEGIN TRY

	-- No, so create
	IF NOT EXISTS(SELECT * FROM [MeDriAnchor].[DBTableTie] WHERE [TieMnemonic] = @TieMnemonic)
	BEGIN
		-- add the tie
		INSERT INTO [MeDriAnchor].[DBTableTie]
			(
			[TieMnemonic]
			)
		VALUES
			(
			@TieMnemonic
			);

		SET @TieID = SCOPE_IDENTITY();
	END
	ELSE
	BEGIN
		SET @TieID = (SELECT [TieID] FROM [MeDriAnchor].[DBTableTie] WHERE [TieMnemonic] = @TieMnemonic);
	END

	-- Get the column ids
	SET @J1DBTableColumnID = (SELECT [DBTableColumnID] FROM [MeDriAnchor].[DBTableColumn] WHERE [DBTableID] = @J1DBTableID
	AND [DBTableColumnName] = @J1DBTableColumnName);

	SET @J2DBTableColumnID = (SELECT [DBTableColumnID] FROM [MeDriAnchor].[DBTableColumn] WHERE [DBTableID] = @J2DBTableID
	AND [DBTableColumnName] = @J2DBTableColumnName);

	-- Merge the tie table columns

	-- join column 1
	MERGE [MeDriAnchor].[DBTableTieColumns] ttc
	USING 
	(
	SELECT	@TieID AS [TieID],
			@J1DBTableColumnID AS [DBTableColumnID],
			@J1AnchorMnemonicRef AS [AnchorMnemonicRef],
			@J1RoleName AS [RoleName],
			@J1TieJoinOrder AS [TieJoinOrder],
			@J1TieJoinColumn AS [TieJoinColumn],
			@J1IsIdentity AS [IsIdentity]
	) j1
	ON ttc.[TieID] = j1.[TieID]
		AND ttc.[TieJoinOrder] = j1.[TieJoinOrder]
	WHEN MATCHED AND 
	(
	ttc.[DBTableColumnID] <> j1.[DBTableColumnID] 
	OR ttc.[RoleName] <> j1.[RoleName]
	Or ttc.[TieJoinOrder] <> j1.[TieJoinOrder]
	OR ttc.[TieJoinColumn] <> j1.[TieJoinColumn]
	OR ttc.[IsIdentity] <> j1.[IsIdentity]
	) THEN
	  UPDATE
	  SET ttc.[DBTableColumnID] = j1.[DBTableColumnID],
		 ttc.[RoleName] = j1.[RoleName],
		 ttc.[TieJoinOrder] = j1.[TieJoinOrder],
		 ttc.[TieJoinColumn] = j1.[TieJoinColumn],
		 ttc.[IsIdentity] = j1.[IsIdentity]
	WHEN NOT MATCHED BY TARGET THEN
	  INSERT ([TieID], [DBTableColumnID], [AnchorMnemonicRef], [RoleName], [TieJoinOrder], [TieJoinColumn], [IsIdentity])
	  VALUES (j1.[TieID], j1.[DBTableColumnID], j1.[AnchorMnemonicRef], j1.[RoleName], j1.[TieJoinOrder], j1.[TieJoinColumn], j1.[IsIdentity]);
 
	-- join column 2
	MERGE [MeDriAnchor].[DBTableTieColumns] ttc
	USING 
	(
	SELECT	@TieID AS [TieID],
			@J2DBTableColumnID AS [DBTableColumnID],
			@J2AnchorMnemonicRef AS [AnchorMnemonicRef],
			@J2RoleName AS [RoleName],
			@J2TieJoinOrder AS [TieJoinOrder],
			@J2TieJoinColumn AS [TieJoinColumn],
			@J2IsIdentity AS [IsIdentity]
	) j2
	ON ttc.[TieID] = j2.[TieID]
		AND ttc.[TieJoinOrder] = j2.[TieJoinOrder]
	WHEN MATCHED AND 
	(
	ttc.[DBTableColumnID] <> j2.[DBTableColumnID] 
	OR ttc.[RoleName] <> j2.[RoleName]
	OR ttc.[TieJoinOrder] <> j2.[TieJoinOrder]
	OR ttc.[TieJoinColumn] <> j2.[TieJoinColumn]
	OR ttc.[IsIdentity] <> j2.[IsIdentity]
	) THEN
	  UPDATE
	  SET ttc.[DBTableColumnID] = j2.[DBTableColumnID],
		 ttc.[RoleName] = j2.[RoleName],
		 ttc.[TieJoinOrder] = j2.[TieJoinOrder],
		 ttc.[TieJoinColumn] = j2.[TieJoinColumn],
		 ttc.[IsIdentity] = j2.[IsIdentity]
	WHEN NOT MATCHED BY TARGET THEN
	  INSERT ([TieID], [DBTableColumnID], [AnchorMnemonicRef], [RoleName], [TieJoinOrder], [TieJoinColumn], [IsIdentity])
	  VALUES (j2.[TieID], j2.[DBTableColumnID], j2.[AnchorMnemonicRef], j2.[RoleName], j2.[TieJoinOrder], j2.[TieJoinColumn], j2.[IsIdentity]);

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