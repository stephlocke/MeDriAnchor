/*
CREATE VIEW [MeDriAnchor].[vConnectivity]
AS
SELECT TOP (1) 1 AS [AllAlive]
FROM
(
SELECT TOP 1 @@SERVERNAME AS [Server] FROM [592576-DB1\SQL_ORIGINATION].[master].[sys].[databases]
UNION ALL
SELECT TOP 1 @@SERVERNAME AS [Server] FROM [592576-DB1\SQL_SERVICING].[master].[sys].[databases]
UNION ALL
SELECT TOP 1 'COPTOWLDB1' AS [Server] FROM [COPTOWLDB1]...[lenderfee]
) srvs;
*/
