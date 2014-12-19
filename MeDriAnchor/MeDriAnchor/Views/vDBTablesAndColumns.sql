
-- Create metadata views

CREATE VIEW [MeDriAnchor].[vDBTablesAndColumns]
AS
SELECT	db.[DBName],
		db.[Metadata_ID],
		t.[DBTableSchema],
		t.[DBTableName],
		t.[DBTableType],
		tc.[DBTableColumnName],
		tc.[ColPosition],
		env.[EnvironmentName],
		tc.[IsAnchor],
		tc.[AnchorMnemonic],
		tc.[IsAttribute],
		tc.[AttributeMnemonic],
		tc.[IsHistorised],
		tc.[HistorisedTimeRange],
		tc.[AnchorMnemonicRef],
		tc.[IsKnot],
		tc.[KnotMnemonic],
		tc.[GenerateID],
		tc.[IsReportable],
		tc.[RoleName],
		tc.[RoleNameRef]
FROM [MeDriAnchor].[DBTableColumn] tc
INNER JOIN [MeDriAnchor].[Environment] env
	ON tc.[Environment_ID] = env.[Environment_ID]
INNER JOIN [MeDriAnchor].[DBTable] t
	ON t.[DBTableID] = tc.[DBTableID]
INNER JOIN [MeDriAnchor].[DB] db
	ON t.[DBID] = db.[DBID]
INNER JOIN [MeDriAnchor].[DBServer] srv
	ON db.[DBServerID] = srv.[DBServerID]
WHERE t.[DBTableName] NOT IN('vIndexDetails','vTableColumns')
	AND t.[IsActive] = 1
	AND tc.[IsActive] = 1;
