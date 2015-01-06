CREATE PROCEDURE [MeDriAnchor].[sspGetSchemaFromSourceDB]
	@DBID BIGINT,
	@Environment_ID SMALLINT
AS
SET NOCOUNT ON;
SET ANSI_NULLS ON;
SET ANSI_WARNINGS ON;

DECLARE @ServerName SYSNAME;
DECLARE @DBName SYSNAME;
DECLARE @SQL NVARCHAR(MAX) = '';

BEGIN TRY

	-- From the DBID get the server we are pulling from
	SELECT	@ServerName = srv.[ServerName],
			@DBName = db.[DBName]
	FROM [MeDriAnchor].[DB] db
	INNER JOIN [MeDriAnchor].[DBServer] srv
		ON srv.[DBServerID] = db.[DBServerID]
	WHERE db.[DBID] = @DBID
		AND (db.[Environment_ID] = @Environment_ID OR db.[Environment_ID] IS NULL);

	SET @SQL = 
	'
	MERGE [MeDriAnchor].[DBTable] AS target
	USING 
	(
	SELECT	' + CONVERT(VARCHAR(20), @DBID) + ',
			[TableSchema],
			[TableName],
			[TableType]
	FROM [' + @ServerName + '].[' + @DBName + '].[dbo].[vTableColumns]
	GROUP BY	[TableSchema],
				[TableName],
				[TableType]
	) AS source 
	(
	[DBID], 
	[DBTableSchema], 
	[DBTableName],
	[DBTableType]
	)
	ON (target.[DBID] = source.[DBID]
		AND target.[DBTableName] = source.[DBTableName] COLLATE DATABASE_DEFAULT)
	WHEN NOT MATCHED BY TARGET THEN
		INSERT
			(
			[DBID], 
			[DBTableSchema], 
			[DBTableName],
			[DBTableType]
			)
		VALUES 
			(
			source.[DBID], 
			source.[DBTableSchema], 
			source.[DBTableName],
			source.[DBTableType]
			)
	WHEN NOT MATCHED BY SOURCE THEN
		UPDATE SET [IsActive] = 0;

	MERGE [MeDriAnchor].[DBTableColumn] AS target
	USING 
	(
	SELECT	t.[DBTableID],
			tc.[ColumnName],
			' + CONVERT(NVARCHAR(20), @Environment_ID) + ' AS [Environment_ID],
			[PKColumn], 
			[PKName], 
			[PKClustered], 
			[PKColOrdinal], 
			[PKDescOrder], 
			[IdentityColumn], 
			[ColPosition], 
			[DataType], 
			[NumericPrecision], 
			[NumericScale], 
			[CharMaxLength], 
			[IsNullable], 
			[IsComputedCol],
			0 AS [IsMaterialisedColumn],
			'''' AS [MaterialisedColumnFunction]
	FROM [' + @ServerName + '].[' + @DBName + '].[dbo].[vTableColumns] tc
	INNER JOIN [MeDriAnchor].[DBTable] t
		ON tc.[TableSchema] = t.[DBTableSchema] COLLATE DATABASE_DEFAULT
		AND tc.[TableName] = t.[DBTableName] COLLATE DATABASE_DEFAULT
	) AS source 
	(
	[DBTableID], 
	[DBTableColumnName], 
	[Environment_ID],  
	[PKColumn], 
	[PKName], 
	[PKClustered], 
	[PKColOrdinal], 
	[PKDescOrder], 
	[IdentityColumn], 
	[ColPosition], 
	[DataType], 
	[NumericPrecision], 
	[NumericScale], 
	[CharMaxLength], 
	[IsNullable], 
	[IsComputedCol],
	[IsMaterialisedColumn],
	[MaterialisedColumnFunction]
	)
	ON (target.[DBTableID] = source.[DBTableID]
		AND target.[DBTableColumnName] = source.[DBTableColumnName] COLLATE DATABASE_DEFAULT)
	WHEN NOT MATCHED BY TARGET THEN
		INSERT
			(
			[DBTableID], 
			[DBTableColumnName], 
			[Environment_ID],  
			[PKColumn], 
			[PKName], 
			[PKClustered], 
			[PKColOrdinal], 
			[PKDescOrder], 
			[IdentityColumn], 
			[ColPosition], 
			[DataType], 
			[NumericPrecision], 
			[NumericScale], 
			[CharMaxLength], 
			[IsNullable], 
			[IsComputedCol],
			[IsMaterialisedColumn],
			[MaterialisedColumnFunction]
			)
		VALUES 
			(
			source.[DBTableID], 
			source.[DBTableColumnName], 
			source.[Environment_ID],  
			source.[PKColumn], 
			source.[PKName], 
			source.[PKClustered], 
			source.[PKColOrdinal], 
			source.[PKDescOrder], 
			source.[IdentityColumn], 
			source.[ColPosition], 
			source.[DataType], 
			source.[NumericPrecision], 
			source.[NumericScale], 
			source.[CharMaxLength], 
			source.[IsNullable], 
			source.[IsComputedCol],
			source.[IsMaterialisedColumn],
			source.[MaterialisedColumnFunction]
			)
	WHEN NOT MATCHED BY SOURCE THEN
		UPDATE SET [IsActive] = 0;';
	
	--PRINT @SQL;
		
	EXEC sys.sp_executesql @SQL;	
	
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