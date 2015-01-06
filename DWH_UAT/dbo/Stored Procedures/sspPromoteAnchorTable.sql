CREATE PROCEDURE [dbo].[sspPromoteAnchorTable]
(
	@AnchorObjectName SYSNAME,
	@MoveToSchema SYSNAME,
	@Debug BIT = 1
)
AS

/*
EXEC [dbo].[sspPromoteAnchorTable]
	@AnchorObjectName = '[DwhDev].[SP_SP_BON_AWSalesPersonID_Bonus]',
	@MoveToSchema = '[Dwh]',
	@Debug = 0;
*/

SET NOCOUNT ON;

DECLARE @SQL NVARCHAR(MAX) = '';
DECLARE @DROPS TABLE
	(
	[level] INT,
	[dropPosition] INT,
	[dropSQL] NVARCHAR(MAX),
	[referencing_schema_name] SYSNAME, 
	[referencing_entity_name] SYSNAME
	);

BEGIN TRY

	BEGIN TRAN;
	
	WITH ObjectDepends([dropSQL], [dropPosition], [typeDesc], [referencing_schema_name], [referencing_entity_name], [referencing_id], [level])
	AS (
		SELECT 
			CAST((CASE so.type_desc
				WHEN 'CHECK_CONSTRAINT' THEN 'ALTER TABLE ' + @AnchorObjectName + ' DROP CONSTRAINT ' + QUOTENAME(re.referencing_entity_name) + ';'
				WHEN 'SQL_INLINE_TABLE_VALUED_FUNCTION' THEN 'DROP FUNCTION ' + QUOTENAME(re.referencing_schema_name) + '.' + QUOTENAME(re.referencing_entity_name) + ';'
				WHEN 'SQL_SCALAR_FUNCTION' THEN 'DROP FUNCTION ' + QUOTENAME(re.referencing_schema_name) + '.' + QUOTENAME(re.referencing_entity_name) + ';'
				WHEN 'VIEW' THEN 'DROP VIEW ' + QUOTENAME(re.referencing_schema_name) + '.' + QUOTENAME(re.referencing_entity_name) + ';'
			END) AS NVARCHAR(MAX)),
			ROW_NUMBER() OVER (ORDER BY (CASE so.type_desc
				WHEN 'CHECK_CONSTRAINT' THEN 1
				WHEN 'SQL_INLINE_TABLE_VALUED_FUNCTION' THEN 2
				WHEN 'SQL_SCALAR_FUNCTION' THEN 3
				WHEN 'VIEW' THEN 4
			END)) AS [dropPosition],
			so.[type_desc] AS [typeDesc],
			[referencing_schema_name],
			[referencing_entity_name],
			[referencing_id],
			0 AS [level]
		FROM sys.dm_sql_referencing_entities (@AnchorObjectName, 'OBJECT') re
		INNER JOIN sys.objects so
			ON so.[object_id] = re.[referencing_id]
		UNION ALL
		SELECT
			CAST((CASE so.type_desc
				WHEN 'CHECK_CONSTRAINT' THEN 'ALTER TABLE ' + @AnchorObjectName + ' DROP CONSTRAINT ' + QUOTENAME(re.referencing_entity_name) + ';'
				WHEN 'SQL_INLINE_TABLE_VALUED_FUNCTION' THEN 'DROP FUNCTION ' + QUOTENAME(re.referencing_schema_name) + '.' + QUOTENAME(re.referencing_entity_name) + ';'
				WHEN 'SQL_SCALAR_FUNCTION' THEN 'DROP FUNCTION ' + QUOTENAME(re.referencing_schema_name) + '.' + QUOTENAME(re.referencing_entity_name) + ';'
				WHEN 'VIEW' THEN 'DROP VIEW ' + QUOTENAME(re.referencing_schema_name) + '.' + QUOTENAME(re.referencing_entity_name) + ';'
			END) AS NVARCHAR(MAX)),
			ROW_NUMBER() OVER (ORDER BY (CASE so.type_desc
				WHEN 'CHECK_CONSTRAINT' THEN 1
				WHEN 'SQL_INLINE_TABLE_VALUED_FUNCTION' THEN 2
				WHEN 'SQL_SCALAR_FUNCTION' THEN 3
				WHEN 'VIEW' THEN 4
			END)) AS [dropPosition],
			so.[type_desc] AS [typeDesc],
			re.[referencing_schema_name],
			re.[referencing_entity_name],
			re.[referencing_id],
			o.[level] + 1 
		FROM ObjectDepends AS o
		CROSS APPLY sys.dm_sql_referencing_entities(QUOTENAME(o.referencing_schema_name) + N'.' + QUOTENAME(o.referencing_entity_name), 'OBJECT') AS re
		INNER JOIN sys.objects so
			ON so.[object_id] = re.[referencing_id]
		)
	INSERT INTO @DROPS
	SELECT	MAX([level]) AS [level],
			MIN([dropPosition]) AS [dropPosition],
			[dropSQL],
			[referencing_schema_name], 
			[referencing_entity_name]
	FROM ObjectDepends
	GROUP BY
		[dropSQL],
		[referencing_schema_name], 
		[referencing_entity_name];

	SELECT @SQL += [dropSQL] + CHAR(10)
	FROM @DROPS
	ORDER BY [level] DESC, [dropPosition];

	SET @SQL += 'ALTER SCHEMA ' + @MoveToSchema + ' TRANSFER ' + @AnchorObjectName + ';'

	IF (@Debug = 0)
	BEGIN
		EXEC sp_executesql @SQL;
	END
	ELSE
	BEGIN
		PRINT @SQL;
	END

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