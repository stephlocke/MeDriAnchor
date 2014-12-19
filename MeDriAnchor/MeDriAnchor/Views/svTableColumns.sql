
-- TABLE COLUMNS VIEW
CREATE VIEW [MeDriAnchor].[svTableColumns]
AS
/*
LISTS ALL THE COLUMNS FOR TABLES IN THE DATABASE WITH ALL
THE DETAILS NEEDED FOR AUTOMATED OBJECT BUILDING
*/
SELECT	TableSchema,
		TableName,
		ColumnName,
		PKColumn, 
		PKName,
		PKClustered,
		PKFilegroup,
		PKColOrdinal,
		PKDescOrder,
		PKPartitionScheme,
		PKPartitionOrdinal,
		CLIDXName,
		CLIDXUnique,
		CLIDXFilegroup,
		CLIDXColOrdinal,
		CLIDXDescOrder,
		CLIDXPartitionScheme,
		CLIDXPartitionOrdinal,
		IdentityColumn,
		ColPosition,
		DataType,
		IsUserDataType,
		NumericPrecision,
		NumericScale,
		CharMaxLength,
		IsNullable,
		ISNULL(ColumnDefaultName, '') AS ColumnDefaultName,
		ColumnDefault,
		IsComputedCol,
		(CASE WHEN LOWER(DataType) IN(N'numeric',N'decimal') 
			THEN DataType + N'(' + CONVERT(NVARCHAR(10), NumericPrecision) + ',' + CONVERT(NVARCHAR(10), NumericScale) + ')' ELSE DataType END)
			+ (CASE WHEN CharMaxLength IS NOT NULL AND LOWER(DataType) NOT IN('hierarchyid') AND (CharMaxLength > 0 or (UPPER(DataType) IN(N'VARCHAR', N'NVARCHAR', N'VARBINARY') AND CharMaxLength = -1)) THEN '(' + CASE WHEN CONVERT(VARCHAR(10), CharMaxLength) = N'-1' THEN N'max' ELSE CONVERT(VARCHAR(10), CharMaxLength) END + N')' ELSE N'' END) + N' ' +
			+ (CASE WHEN IsNullable = 1 THEN
					CASE WHEN ColumnDefault IS NULL
						THEN N' = NULL'
						ELSE N''
					END
				ELSE
					CASE WHEN (ColumnDefault IS NULL AND IdentityColumn = 0) THEN N''
					ELSE
						CASE WHEN ISNULL(PKColumn, 0) = 1
							THEN N' = NULL'
							ELSE 
								CASE WHEN CHARINDEX(N'()', ColumnDefault) > 0 THEN N' = NULL'
								ELSE	' = ' + REPLACE((CASE 
													WHEN SUBSTRING(ColumnDefault, 1, 2) = N'(('
														THEN SUBSTRING(ColumnDefault, 3, LEN(ColumnDefault) - 4)
													WHEN SUBSTRING(ColumnDefault, 1, 1) = N'('
														THEN SUBSTRING(ColumnDefault, 2, LEN(ColumnDefault) - 2)
													ELSE REPLACE(REPLACE(ColumnDefault, N'(', N''), N')', N'')
												END), N'()', N'')
								END
							END
				END
		END) AS ParameterType,
		(CASE WHEN CHARINDEX(N'()', ColumnDefault) > 0
			THEN N'SET @' + ColumnName + ' = ' + SUBSTRING(ColumnDefault, 2, LEN(ColumnDefault) - 2) + ';'
			ELSE N''
		END) AS ParameterTypeSet,
		(
		(CASE WHEN DataType IN('numeric', 'decimal') THEN DataType + '(' + CONVERT(VARCHAR(10), NumericPrecision) + ',' + CONVERT(VARCHAR(10), NumericScale) + ')' ELSE DataType END) + 
		+ (CASE WHEN CharMaxLength IS NOT NULL AND LOWER(DataType) NOT IN('hierarchyid') AND (CharMaxLength > 0 or (UPPER(DataType) IN('VARCHAR', 'NVARCHAR', 'VARBINARY') AND CharMaxLength = -1)) THEN '(' + CASE WHEN CONVERT(VARCHAR(10), CharMaxLength) = '-1' THEN 'max' ELSE CONVERT(VARCHAR(10), CharMaxLength) END + ')' ELSE '' END) + ' ' +
		+ (CASE WHEN IdentityColumn = 1 THEN 'IDENTITY(1,1) ' ELSE '' END)
		+ (CASE WHEN IsNullable = 1 THEN 'NULL' ELSE 'NOT NULL' END)
		) AS TableColumnType,
		(
		(CASE WHEN DataType IN('numeric', 'decimal') THEN DataType + '(' + CONVERT(VARCHAR(10), NumericPrecision) + ',' + CONVERT(VARCHAR(10), NumericScale) + ')' ELSE DataType END) + 
		+ (CASE WHEN CharMaxLength IS NOT NULL AND LOWER(DataType) NOT IN('hierarchyid') AND (CharMaxLength > 0 or (UPPER(DataType) IN('VARCHAR', 'NVARCHAR', 'VARBINARY') AND CharMaxLength = -1)) THEN '(' + CASE WHEN CONVERT(VARCHAR(10), CharMaxLength) = '-1' THEN 'max' ELSE CONVERT(VARCHAR(10), CharMaxLength) END + ')' ELSE '' END) + ' ' +
		+ (CASE WHEN IsNullable = 1 THEN 'NULL' ELSE 'NOT NULL' END)
		) AS ShadowTableColumnType,
		tc.CheckConstraintName,
		tc.CheckConstraintDef
FROM
(
SELECT	s.[name] AS TableSchema,
		st.[name] AS TableName,
		sc.[name] AS ColumnName,
		ISNULL(pk.[IDXPK], 0) AS PKColumn, 
		ISNULL(pk.IDXName, '') AS PKName,
		(CASE WHEN pk.[IDXID] = 1 THEN 1 ELSE 0 END) AS PKClustered,
		ISNULL(pk.[IDXFilegroup], 'PRIMARY') AS PKFilegroup,
		ISNULL(pk.IDXColOrdinal, 0) AS PKColOrdinal,
		ISNULL(pk.IDXDescOrder, 0) AS PKDescOrder,
		(CASE 
			WHEN ISNULL(clidx.[IDXPartitionSchemeName], '') <> '' THEN '' 
			ELSE ISNULL(pk.[IDXPartitionSchemeName], '')
		END) AS PKPartitionScheme,
		(CASE 
			WHEN ISNULL(clidx.[IDXPartitionSchemeName], '') <> '' THEN 0 
			ELSE ISNULL(pk.[IDXPartitionOrdinal], 0)
		END) AS PKPartitionOrdinal,
		ISNULL(clidx.IDXName, '') AS CLIDXName,
		ISNULL(clidx.IDXUnique, 0) AS CLIDXUnique,
		ISNULL(clidx.[IDXFilegroup], 'PRIMARY') AS CLIDXFilegroup,
		ISNULL(clidx.IDXColOrdinal, 0) AS CLIDXColOrdinal,
		ISNULL(clidx.IDXDescOrder, 0) AS CLIDXDescOrder,
		ISNULL(clidx.[IDXPartitionSchemeName], '') AS CLIDXPartitionScheme,
		ISNULL(clidx.[IDXPartitionOrdinal], 0) AS CLIDXPartitionOrdinal,
		sc.is_identity AS IdentityColumn,
		sc.column_id AS ColPosition,
		stys.[name] AS DataType,
		(CASE WHEN sc.user_type_id <> sc.system_type_id THEN 1 ELSE 0 END) AS IsUserDataType,
		sc.[precision] AS NumericPrecision,
		sc.scale AS NumericScale,
		(CASE 
			WHEN sty.[name] = 'sysname' THEN 128
			WHEN sc.user_type_id <> sc.system_type_id THEN NULL 
			WHEN sty.[name] NOT IN('nvarchar', 'nchar', 'varchar', 'char', 'varbinary', 'binary') THEN NULL
			WHEN sty.[name] IN('nvarchar', 'nchar') AND sc.[max_length] <> - 1 THEN (sc.[max_length] / 2)
			ELSE sc.[max_length]
		END) AS CharMaxLength,
		sc.is_nullable AS IsNullable,
		sdc.[name] AS ColumnDefaultName,
		sdc.[definition] As ColumnDefault,
		sc.is_computed AS IsComputedCol,
		ISNULL(scc.[name], '') AS CheckConstraintName,
		ISNULL(scc.[definition], '') AS CheckConstraintDef
FROM sys.columns sc
INNER JOIN sys.tables st
	ON sc.[object_id] = st.[object_id]
INNER JOIN sys.schemas s
	ON st.[schema_id] = s.[schema_id]
INNER JOIN sys.types sty
	ON sc.user_type_id = sty.user_type_id
LEFT OUTER JOIN sys.types stys
	ON sty.system_type_id = stys.system_type_id
	AND stys.system_type_id =  stys.user_type_id
LEFT OUTER JOIN [MeDriAnchor].[svIndexDetails] pk
	ON sc.[object_id] = pk.[object_id]
	AND sc.[column_id] = pk.[column_id]
	AND pk.IDXPK = 1
LEFT OUTER JOIN [MeDriAnchor].[svIndexDetails] clidx
	ON sc.[object_id] = clidx.[object_id]
	AND sc.[column_id] = clidx.[column_id]
	AND clidx.IDXID = 1
	AND clidx.IDXPK = 0
LEFT OUTER JOIN sys.default_constraints sdc
	ON sc.default_object_id = sdc.[object_id]
LEFT OUTER JOIN sys.check_constraints scc
	ON sc.[object_id] = scc.parent_object_id
	AND sc.column_id = scc.parent_column_id
) tc;
