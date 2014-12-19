

-- TABLE COLUMNS VIEW
CREATE VIEW [dbo].[vTableColumns]
AS
/*
LISTS ALL THE COLUMNS FOR TABLES IN THE DATABASE WITH ALL
THE DETAILS NEEDED FOR AUTOMATED OBJECT BUILDING

DATE: SEPTEMBER 2014

YOU MAY ALTER THIS CODE AS YOU WISH. KNOCK YOURSELF OUT BUT...THIS CODE AND 
INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED 
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY 
AND/OR FITNESS FOR A PARTICULAR PURPOSE.
*/
SELECT	TableSchema,
		TableName,
		TableType,
		ColumnName,
		PKColumn, 
		PKName,
		PKClustered,
		PKFilegroup,
		PKColOrdinal,
		PKDescOrder,
		IdentityColumn,
		ColPosition,
		[DataType]
		+
		ISNULL((CASE 
			WHEN LOWER([DataType]) IN(N'numeric', N'decimal', N'float') THEN
				'(' + CONVERT(NVARCHAR(10), NumericPrecision) + ',' + CONVERT(NVARCHAR(10), NumericScale) + ')'
			WHEN UPPER([DataType]) IN(N'SYSNAME', N'CHAR', N'NCHAR', N'VARCHAR', N'NVARCHAR', N'VARBINARY') THEN
						(CASE 
							WHEN CONVERT(VARCHAR(10), CharMaxLength) = N'-1' 
							THEN N'(max)' 
							ELSE N'(' + CONVERT(VARCHAR(10), CharMaxLength) + N')'
						END) 
			ELSE N''
		END), N'') AS DataType,
		NumericPrecision,
		NumericScale,
		CharMaxLength,
		IsNullable,
		IsComputedCol
FROM
(
SELECT	st.[TABLE_SCHEMA] AS [TableSchema],
		st.[TABLE_NAME] AS [TableName],
		st.[TABLE_TYPE] AS [TableType],
		sc.[COLUMN_NAME] AS [ColumnName],
		ISNULL(pk.[IDXPK], 0) AS [PKColumn], 
		ISNULL(pk.IDXName, '') AS [PKName],
		(CASE WHEN pk.[IDXID] = 1 THEN 1 ELSE 0 END) AS [PKClustered],
		ISNULL(pk.[IDXFilegroup], 'PRIMARY') AS [PKFilegroup],
		ISNULL(pk.IDXColOrdinal, 0) AS [PKColOrdinal],
		ISNULL(pk.IDXDescOrder, 0) AS [PKDescOrder],
		ISNULL(pk.[IDXPartitionOrdinal], 0) AS [PKPartitionOrdinal],
		COLUMNPROPERTY(OBJECT_ID(st.[TABLE_SCHEMA] + '.' + st.[TABLE_NAME]), sc.[COLUMN_NAME], 'IsIdentity') AS [IdentityColumn],
		sc.[ORDINAL_POSITION] AS [ColPosition],
		sc.[DATA_TYPE] AS [DataType],
		ISNULL(sc.[NUMERIC_PRECISION], 0) AS [NumericPrecision],
		ISNULL(sc.[NUMERIC_SCALE], 0) AS [NumericScale],
		ISNULL(sc.[CHARACTER_MAXIMUM_LENGTH], 0) AS [CharMaxLength],
		(CASE WHEN sc.[IS_NULLABLE] = 'YES' THEN 1 ELSE 0 END) AS [IsNullable],
		COLUMNPROPERTY(OBJECT_ID(st.[TABLE_SCHEMA] + '.' + st.[TABLE_NAME]), sc.[COLUMN_NAME], 'IsComputed') AS [IsComputedCol]
FROM [INFORMATION_SCHEMA].[COLUMNS] sc
INNER JOIN [INFORMATION_SCHEMA].[TABLES] st
	ON sc.[TABLE_SCHEMA] = st.[TABLE_SCHEMA]
	AND sc.[TABLE_NAME] = st.[TABLE_NAME]
LEFT OUTER JOIN [dbo].[vIndexDetails] pk
	ON st.[TABLE_SCHEMA] = pk.[TableSchema]
	AND st.[TABLE_NAME] = pk.[TableName]
	AND sc.[COLUMN_NAME] = pk.[ColumnName]
	AND pk.IDXPK = 1
) tc
WHERE tc.[TableName] NOT IN('vIndexDetails', 'vTableColumns');