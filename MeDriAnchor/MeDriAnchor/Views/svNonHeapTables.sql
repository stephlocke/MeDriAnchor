
-- NON-HEAP TABLES VIEW
CREATE VIEW [MeDriAnchor].[svNonHeapTables]
AS
/*
LISTS ALL THE TABLES IN THE DATABASE THAT ARE NOT HEAPS
(AND ALSO NOT MeDriAnchor SHADOW/AUDIT TABLES)
*/
SELECT	ss.[name] AS TableSchema,
		st.[name] AS TableName,
		st.[schema_id],
		st.[object_id]
FROM sys.key_constraints kc
INNER JOIN sys.tables st
	ON kc.parent_object_id = st.[object_id]
INNER JOIN sys.schemas ss
	ON st.[schema_id] = ss.[schema_id]
WHERE kc.[type] = 'PK'
	AND ss.[name] NOT IN('dbo')
	AND st.[name] NOT LIKE '%' + (SELECT [ShadowTableNamePostfix] FROM [MeDriAnchor].[svExtProps]);
