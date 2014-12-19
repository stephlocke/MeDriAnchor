-- GUID Swap
MERGE [MeDriAnchor].[GUIDSwap] AS TARGET
USING
(SELECT 330, [ApplicationID] FROM [DPRGateway].[MeDriAnchor].[vApplicationOrigination]) AS SOURCE([DBTableColumnID], [GUID])
ON (TARGET.[DBTableColumnID] = SOURCE.[DBTableColumnID] AND TARGET.[GUID] = SOURCE.[GUID])
WHEN NOT MATCHED THEN
    INSERT ([DBTableColumnID], [GUID])
    VALUES (SOURCE.[DBTableColumnID], SOURCE.[GUID]);

UPDATE gs SET [NewID] = nid.[NewID]
FROM [MeDriAnchor].[GUIDSwap] gs
INNER JOIN
(
SELECT  gss.[DBTableColumnID],  gss.[GUID], ROW_NUMBER() OVER(PARTITION BY  gss.[DBTableColumnID] ORDER BY (SELECT 0)) + ISNULL([MaxNewID], 0) AS [NewID]
FROM [MeDriAnchor].[GUIDSwap] gss
LEFT OUTER JOIN 
(
SELECT [DBTableColumnID], MAX([NewID]) AS [MaxNewID]
FROM [MeDriAnchor].[GUIDSwap]
WHERE [NewID] IS NOT NULL
GROUP BY [DBTableColumnID]
) mgss
	ON mgss.[DBTableColumnID] = gss.[DBTableColumnID]
WHERE gss.[NewID] IS NULL
) nid
	ON nid.[DBTableColumnID] = gs.[DBTableColumnID]
	AND nid.[GUID] = gs.[GUID]
WHERE gs.[NewID] IS NULL;

-- mass constraint drop
DECLARE @SQL NVARCHAR(MAX) = '';

SELECT @SQL += 'ALTER TABLE ' + ccu.TABLE_SCHEMA + '.' + ccu.TABLE_NAME + ' DROP CONSTRAINT ' +  cc.CONSTRAINT_NAME + ';' + CHAR(10) + 'GO' + CHAR(10)
FROM            INFORMATION_SCHEMA.CHECK_CONSTRAINTS cc
INNER JOIN [INFORMATION_SCHEMA].[CONSTRAINT_COLUMN_USAGE] ccu
	ON ccu.CONSTRAINT_NAME = cc.CONSTRAINT_NAME
WHERE        (cc.CHECK_CLAUSE LIKE '%[DWHDev]%')

SELECT CONVERT(XML, @SQL);

-- table schema transfer
DECLARE @SQL NVARCHAR(MAX) = '';

SELECT @SQL += 'ALTER SCHEMA [Dwh] TRANSFER ' + [TABLE_SCHEMA] + '.' + [TABLE_NAME] + ';' + CHAR(10)
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'DwhDev'
AND TABLE_TYPE = 'BASE TABLE';

SELECT CONVERT(XML, @SQL);

-- move from dev to live
UPDATE [MeDriAnchor].[DBTableColumn] SET Environment_ID = 3
WHERE [DBTableColumnID] IN
(SELECT [DBTableColumnID] FROM [MeDriAnchor].[svTableColumnsWithMetadata]);


-- useful alert table queries
SELECT TOP 1000 [EventAlertID]
      ,[Batch_ID]
      ,[SeverityID]
      ,[AlertMessage]
      ,[AlertDate]
      ,[RecordsInserted]
      ,[DBTableColumnID]
      ,[PKDBTableColumnValue]
  FROM [MeDriAnchor].[MeDriAnchor].[EventAlerts]
  order by [AlertDate] desc;

SELECT TOP 1000 [EventAlertID]
      ,[Batch_ID]
      ,[SeverityID]
      ,[AlertMessage]
      ,[AlertDate]
      ,[RecordsInserted]
      ,[DBTableColumnID]
      ,[PKDBTableColumnValue]
  FROM [MeDriAnchor].[MeDriAnchor].[EventAlerts]
  where severityID>2
  order by [AlertDate] desc;

SELECT convert(varchar,[AlertDate], 101)
      ,sum([RecordsInserted])
  FROM [MeDriAnchor].[MeDriAnchor].[EventAlerts]
  group by convert(varchar,[AlertDate], 101)
  order by  convert(varchar,[AlertDate], 101) desc;

select 
cur.AlertMessage, prev.AlertDate, cur.AlertDate, datediff(s,prev.AlertDate, cur.AlertDate) SecsToRun
  FROM [MeDriAnchor].[MeDriAnchor].[EventAlerts] prev
  inner join [MeDriAnchor].[MeDriAnchor].[EventAlerts] cur on prev.[EventAlertID]=cur.[EventAlertID]-1 and prev.[Batch_ID]=cur.[Batch_ID]
  where datediff(s,prev.AlertDate, cur.AlertDate)>60;

