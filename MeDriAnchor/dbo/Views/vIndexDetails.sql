

-- INDEX DETAILS VIEW
CREATE VIEW [dbo].[vIndexDetails]
/*
LISTS ALL THE DETAILS OF A COLUMNS INDEX USAGE

DATE: SEPTEMBER 2014

YOU MAY ALTER THIS CODE AS YOU WISH. KNOCK YOURSELF OUT BUT...THIS CODE AND 
INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED 
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY 
AND/OR FITNESS FOR A PARTICULAR PURPOSE.
*/
AS
SELECT	sic.[object_id],
		sic.[column_id],
		s.[name] AS TableSchema,
		st.[name] AS TableName,
		sc.[name] AS ColumnName, 
		si.[name] AS IDXName,
		si.[index_id] As IDXID,
		si.is_primary_key AS IDXPK,
		fg.[name] AS IDXFilegroup,
		sic.key_ordinal AS IDXColOrdinal,
		sic.is_descending_key AS IDXDescOrder,
		si.is_unique AS IDXUnique,
		ISNULL(ps.[name], '') AS IDXPartitionSchemeName,
		sic.partition_ordinal AS IDXPartitionOrdinal
FROM sys.columns sc
INNER JOIN sys.tables st
	ON sc.[object_id] = st.[object_id]
INNER JOIN sys.schemas s
	ON st.[schema_id] = s.[schema_id]
INNER JOIN sys.index_columns sic 
	ON sc.[object_id] = sic.[object_id]
	AND sc.column_id = sic.column_id
INNER JOIN sys.indexes si
	ON sic.[object_id] = si.[object_id] 
	AND sic.index_id = si.index_id
LEFT OUTER JOIN sys.filegroups fg
	ON si.data_space_id = fg.data_space_id
LEFT OUTER JOIN sys.partition_schemes ps
	ON si.data_space_id = ps.data_space_id
LEFT OUTER JOIN sys.partition_functions pf
	ON ps.function_id = ps.function_id
GROUP BY	sic.[object_id],
			sic.[column_id],
			s.[name],
			st.[name],
			sc.[name],
			si.[name],
			si.[index_id],
			si.is_primary_key,
			fg.[name],
			sic.key_ordinal,
			sic.is_descending_key,
			si.is_unique,
			ISNULL(ps.[name], ''),
			sic.partition_ordinal;