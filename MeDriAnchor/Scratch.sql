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



-- move from dev to live
UPDATE [MeDriAnchor].[DBTableColumn] SET Environment_ID = 3
WHERE [DBTableColumnID] IN
(SELECT [DBTableColumnID] FROM [MeDriAnchor].[svTableColumnsWithMetadata] WHERE Environment_ID = 1);


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

