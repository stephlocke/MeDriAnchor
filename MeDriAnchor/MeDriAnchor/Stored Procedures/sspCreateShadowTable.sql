
-- CREATE SHADOW/AUDIT TABLE
CREATE PROCEDURE [MeDriAnchor].[sspCreateShadowTable]
(
	@TableSchema SYSNAME,
	@TableName SYSNAME,
	@TableColumnsCST [MeDriAnchor].[TableColumns] READONLY,
	@Debug BIT = 0
)
AS
/*
GENERATES THE SQL FOR THE CREATION OR ALTERATION OF A SHADOW/AUDIT TABLE
*/
DECLARE @SQL NVARCHAR(MAX) = '';
DECLARE @PK_SQL NVARCHAR(MAX) = '';
DECLARE @CLIDX_SQL NVARCHAR(MAX) = '';
DECLARE @TYPE_DEFAULT_SQL NVARCHAR(MAX) = '';
DECLARE @PK_NAME SYSNAME = '';
DECLARE @PK_COLUMNS NVARCHAR(MAX) = '';
DECLARE @PK_CLUSTERED BIT = 1;
DECLARE @PK_FILEGROUP SYSNAME;
DECLARE @PKPartitionScheme SYSNAME;
DECLARE @PKPartitionSchemeCol SYSNAME;
DECLARE @ALL_COLUMNS NVARCHAR(MAX) = '';
DECLARE @CLIDX_NAME SYSNAME = '';
DECLARE @CLIDX_COLUMNS NVARCHAR(MAX) = '';
DECLARE @CLIDX_UNIQUE BIT;
DECLARE @CLIDX_FILEGROUP SYSNAME;
DECLARE @CLIDXPartitionScheme SYSNAME;
DECLARE @CLIDXPartitionSchemeCol SYSNAME;
DECLARE @ShadowTableNamePrefix NVARCHAR(20) = '';
DECLARE @ShadowTableNamePostfix NVARCHAR(20) = '_Shadow';
DECLARE @MaintenanceMode VARCHAR(5) = 'False';
DECLARE @ShadowFilegroupPlacement SYSNAME = 'MIRROR';
DECLARE @MirrorPartitionScheme VARCHAR(5) = 'False';
DECLARE @TableColumnsDeleted [MeDriAnchor].[TableColumns];

BEGIN TRY 

	SELECT	@ShadowTableNamePrefix = [ShadowTableNamePrefix],
			@ShadowTableNamePostfix = [ShadowTableNamePostfix],
			@MaintenanceMode = [MaintenanceMode],
			@ShadowFilegroupPlacement = [ShadowFilegroupPlacement],
			@MirrorPartitionScheme = [MirrorPartitionScheme]
	FROM [MeDriAnchor].[svExtProps];

	IF (@MaintenanceMode = 'False')
	BEGIN

		-- build the new PK definition
		SELECT	TOP 1
				@PK_NAME = ISNULL(PKName, ''),
				@PK_CLUSTERED = ISNULL(PKClustered, 0),
				@PK_FILEGROUP = ISNULL(PKFilegroup, ''),
				@PKPartitionScheme = ISNULL(PKPartitionScheme, '')
		FROM @TableColumnsCST
		WHERE PKColumn = 1;

		SELECT @PK_COLUMNS = QUOTENAME(ColumnName) 
			+ (CASE WHEN ISNULL(PKDescOrder, 0) = 1 THEN ' DESC' ELSE 'ASC' END) + ','
		FROM @TableColumnsCST
		WHERE PKColumn = 1;

		SET @PK_COLUMNS = @PK_COLUMNS + '[' + RIGHT(@ShadowTableNamePostfix, LEN(@ShadowTableNamePostfix) - 1) + 'ID] ASC'

		SET @PK_SQL = 'CONSTRAINT [' + @PK_NAME + @ShadowTableNamePostfix + '] 
			PRIMARY KEY ' + (CASE WHEN @PK_CLUSTERED = 1 THEN 'CLUSTERED' ELSE 'NONCLUSTERED' END)
			 + ' (' + @PK_COLUMNS + ')' + CHAR(13) + CHAR(13);

		-- now build the deletion type column constraint
		SET @TYPE_DEFAULT_SQL += 'CONSTRAINT [DF_' + @ShadowTableNamePrefix + @TableName 
			+ @ShadowTableNamePostfix + '_DeletionType] DEFAULT (''D'')';

		-- create the table
		SET @SQL = 'CREATE TABLE ' + QUOTENAME(@TableSchema) + '.' + QUOTENAME(@ShadowTableNamePrefix + @TableName + @ShadowTableNamePostfix) + '(
			[' + RIGHT(@ShadowTableNamePostfix, LEN(@ShadowTableNamePostfix) - 1) + 'ID] BIGINT IDENTITY(1,1) NOT NULL, [' 
			+ RIGHT(@ShadowTableNamePostfix, LEN(@ShadowTableNamePostfix) - 1) + 'Type] CHAR(1) ' 
			+ @TYPE_DEFAULT_SQL + ' NOT NULL,'
		SELECT @SQL += + QUOTENAME(ColumnName) + ' ' + ShadowTableColumnType + ','
		FROM @TableColumnsCST
		ORDER BY [ColPosition];
		SET @SQL += '[EditingSQLUser] SYSNAME CONSTRAINT [DF_' + @ShadowTableNamePrefix
			+ @TableName + @ShadowTableNamePostfix + '_EditingSQLUser] DEFAULT(ORIGINAL_LOGIN()),'
		SET @SQL += '[EditingDate] DATETIME CONSTRAINT [DF_' + @ShadowTableNamePrefix
			+ @TableName + @ShadowTableNamePostfix + '_EditingDate] DEFAULT(GETDATE()),'
		SET @SQL += @PK_SQL + ')' 

		-- if following partition scheme then follow
		IF(@MirrorPartitionScheme = 'True' AND @PKPartitionScheme <> '')
		BEGIN
			SET @PKPartitionSchemeCol = 
				ISNULL((
				SELECT [ColumnName]
				FROM @TableColumnsCST
				WHERE PKPartitionScheme = @PKPartitionScheme
					AND PKPartitionOrdinal = 1
				), '');
				IF CHARINDEX(@PKPartitionSchemeCol, @PK_COLUMNS) > 0
					SET @SQL += ' ON ' + @PKPartitionScheme + '(' + QUOTENAME(@PKPartitionSchemeCol) + ');';
		END
		ELSE
		BEGIN
			-- table not partitioned, so if mirroring filegroup include an on clause
			-- if shadow filegroup placement set to MIRROR then same as the source table else the given filegroup
			SET @SQL += ' ON ' + QUOTENAME(CASE WHEN @ShadowFilegroupPlacement = 'MIRROR' THEN @PK_FILEGROUP ELSE @ShadowFilegroupPlacement END) + ';';
		END

		-- if there is a clustered index that isn't the pk then put that on as well
		-- but only if it's partitioned
		SELECT	TOP 1
				@CLIDX_NAME = ISNULL(CLIDXName, ''),
				@CLIDX_UNIQUE = ISNULL(CLIDXUnique, 0),
				@CLIDX_FILEGROUP = ISNULL(CLIDXFilegroup, ''),
				@CLIDXPartitionScheme = ISNULL(CLIDXPartitionScheme, '')
		FROM @TableColumnsCST
		WHERE '' <> ISNULL(CLIDXName, '');

		IF (ISNULL(@CLIDX_NAME, '') <> '')
		BEGIN
			SELECT @CLIDX_COLUMNS += QUOTENAME([ColumnName]) 
				+ (CASE WHEN ISNULL([CLIDXDescOrder], 0) = 1 THEN ' DESC' ELSE 'ASC' END) + ','
			FROM @TableColumnsCST
			WHERE [CLIDXName] = @CLIDX_NAME
			ORDER BY [CLIDXColOrdinal];
			SET @CLIDX_COLUMNS += '[' + RIGHT(@ShadowTableNamePostfix, LEN(@ShadowTableNamePostfix) - 1) + 'ID] ASC';

			SET @CLIDX_SQL = 'CREATE ' + (CASE WHEN @CLIDX_UNIQUE = 1 THEN 'UNIQUE' ELSE '' END) 
			+ ' CLUSTERED INDEX [' + @CLIDX_NAME + @ShadowTableNamePostfix + '] 
			ON [' + @TableSchema + '].[' + @ShadowTableNamePrefix + @TableName + @ShadowTableNamePostfix + ']'
			+ ' (' + @CLIDX_COLUMNS + ')' + CHAR(13) + CHAR(13);
			SET @SQL += @CLIDX_SQL;
			
			-- if following partition scheme then follow
			IF(@MirrorPartitionScheme = 'True')
			BEGIN
				SET @CLIDXPartitionSchemeCol = 
					ISNULL((
					SELECT [ColumnName]
					FROM @TableColumnsCST
					WHERE CLIDXPartitionScheme = @CLIDXPartitionScheme
						AND CLIDXPartitionOrdinal = 1
					), '');
					IF CHARINDEX(@CLIDXPartitionSchemeCol, @CLIDX_COLUMNS) > 0
						SET @SQL += ' ON ' + @CLIDXPartitionScheme + '(' + QUOTENAME(@CLIDXPartitionSchemeCol) + ');';
			END
			ELSE
			BEGIN
				-- table not partitioned, so if mirroring filegroup include an on clause
				-- if shadow filegroup placement set to MIRROR then same as the source table else the given filegroup
				SET @SQL += ' ON ' + QUOTENAME(CASE WHEN @ShadowFilegroupPlacement = 'MIRROR' THEN @CLIDX_FILEGROUP ELSE @ShadowFilegroupPlacement END) + ';';
			END

		END

		-- If there is a Metadata_ID column then auto-index it (non-clustered non unique)
		IF EXISTS(SELECT * FROM @TableColumnsCST WHERE [ColumnName] = 'Metadata_ID')
		BEGIN
			SET @SQL += 'CREATE NONCLUSTERED INDEX [IDX_MetadataID] ON ' + CHAR(13);
			SET @SQL += QUOTENAME(@TableSchema) + '.' + QUOTENAME(@ShadowTableNamePrefix + @TableName + @ShadowTableNamePostfix) + CHAR(13);
			SET @SQL += '([Metadata_ID] ASC);' + CHAR(13);
		END

	END
	ELSE
	BEGIN

		-- in maintenance mode, so do not drop any columns dropped from the table, just make#
		-- them nullable and add any new columns as is

		INSERT INTO @TableColumnsDeleted
		SELECT *
		FROM [MeDriAnchor].[svTableColumns]
		WHERE TableSchema = @TableSchema
			AND TableName = @ShadowTableNamePrefix + @TableName + @ShadowTableNamePostfix;

		-- null any dropped columns
		SELECT @SQL +='ALTER TABLE ' + QUOTENAME(@TableSchema) + '.' + QUOTENAME(@ShadowTableNamePrefix + @TableName + @ShadowTableNamePostfix) 
			+ ' ALTER COLUMN ' + QUOTENAME(ColumnName) + ' ' + REPLACE(TableColumnType, 'NOT NULL', 'NULL')
			+ ';' + CHAR(13)
		FROM @TableColumnsDeleted sht
		WHERE sht.ColumnName NOT IN
				(
				SELECT ColumnName
				FROM @TableColumnsCST
				)
			AND sht.IsNullable = 0
			AND sht.ColPosition > 2;

		-- add any new columns
		SELECT @SQL +='ALTER TABLE ' + QUOTENAME(@TableSchema) + '.' + QUOTENAME(@ShadowTableNamePrefix + @TableName + @ShadowTableNamePostfix) 
			+ ' ADD ' + QUOTENAME(ColumnName) + ' ' + TableColumnType
			+ ';' + CHAR(13)
		FROM @TableColumnsCST mt
		WHERE mt.ColumnName NOT IN
				(
				SELECT ColumnName
				FROM @TableColumnsDeleted
				)
		ORDER BY mt.ColPosition;

		-- alter any columns where the data type has changed
		SELECT @SQL +='ALTER TABLE ' + QUOTENAME(@TableSchema) + '.' + QUOTENAME(@ShadowTableNamePrefix + @TableName + @ShadowTableNamePostfix) 
			+ ' ALTER COLUMN ' + QUOTENAME(dt.ColumnName) + ' ' + mt.ShadowTableColumnType
			+ ';' + CHAR(13)
		FROM @TableColumnsCST mt
		INNER JOIN @TableColumnsDeleted dt
			ON mt.ColumnName = dt.ColumnName
		WHERE mt.ShadowTableColumnType <> dt.ShadowTableColumnType
		ORDER BY mt.ColPosition;

	END

	IF (@Debug = 0)
	BEGIN
		EXEC sys.sp_executesql @SQL;
	END
	ELSE
	BEGIN
		PRINT @SQL;
	END

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
