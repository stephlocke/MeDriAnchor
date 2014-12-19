
CREATE VIEW [MeDriAnchor].[vTableDatetimeComparisonField]
AS
SELECT	t.[DBTableSchema], t.[DBTableName], tc.[DBTableColumnName]
FROM [MeDriAnchor].[DBTableColumn] tc
INNER JOIN [MeDriAnchor].[DBTable] t
	ON tc.[DBTableID] = t.[DBTableID]
WHERE tc.[IsDatetimeComparison] = 1;
