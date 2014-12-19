
-- INSTALL CREATION OBJECTS

-- ACTIVE TABLES VIEW
CREATE VIEW [MeDriAnchor].[svActiveTables]
AS
/*
LISTS ALL THE TABLES IN THE DATABASE THAT ARE ENABLED
FOR SOME FORM OF MeDriAnchor
*/
SELECT	SCHEMA_NAME(t.schema_id) AS TableSchema,
		t.[name] AS TableName,
		t.[schema_id],
		t.[object_id]
FROM sys.tables t
GROUP BY	SCHEMA_NAME(t.schema_id),
			t.[name],
			t.[schema_id],
			t.[object_id];
