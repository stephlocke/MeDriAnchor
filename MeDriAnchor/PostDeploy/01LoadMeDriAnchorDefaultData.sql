
PRINT 'START: Loading MeDriAnchor default data...';

SET NOCOUNT ON;

-- Add severities
IF NOT EXISTS(SELECT * FROM [MeDriAnchor].[Severity])
BEGIN
	INSERT INTO [MeDriAnchor].[Severity]([ServerityName])
	SELECT 'INFO' UNION ALL
	SELECT 'VALIDATION' UNION ALL
	SELECT 'WARNING' UNION ALL
	SELECT 'ERROR' UNION ALL
	SELECT 'CRITICAL ERROR';
END

-- Add default batch type
IF NOT EXISTS(SELECT * FROM [MeDriAnchor].[BatchType])
BEGIN
	INSERT INTO [MeDriAnchor].[BatchType]([BatchType]) VALUES('ETL');
END

-- Add default types
IF NOT EXISTS(SELECT * FROM [MeDriAnchor].[Environment])
BEGIN
	INSERT INTO [MeDriAnchor].[Environment]
	(
	[EnvironmentName]
	)
	SELECT 'DEVELOPMENT'
	UNION ALL
	SELECT 'UAT'
	UNION ALL
	SELECT 'PRODUCTION';
END

-- add the default settings
IF NOT EXISTS(SELECT * FROM [MeDriAnchor].[Settings])
BEGIN

	-- add the default development settings
	DECLARE @Environment_ID SMALLINT = (SELECT [Environment_ID] FROM [MeDriAnchor].[Environment] WHERE [EnvironmentName] = 'DEVELOPMENT');

	INSERT INTO [MeDriAnchor].[Settings]
		(
		[SettingKey],
		[SettingValue],
		[SettingInSchemaMD]
		)
	SELECT 'format', '0.98', 0 UNION ALL
	SELECT 'changingRange', 'datetime', 1 UNION ALL
	SELECT 'encapsulation', 'Dwh', 1 UNION ALL
	SELECT 'identity', 'bigint', 1 UNION ALL
	SELECT 'metadataPrefix', 'Batch', 1 UNION ALL
	SELECT 'metadataType', 'bigint', 1 UNION ALL
	SELECT 'metadataUsage', 'true', 1 UNION ALL
	SELECT 'changingSuffix', 'ChangedAt', 1 UNION ALL
	SELECT 'identitySuffix', 'ID', 1 UNION ALL
	SELECT 'positIdentity', 'bigint', 1 UNION ALL
	SELECT 'positGenerator', 'true', 1 UNION ALL
	SELECT 'positingRange', 'datetime', 1 UNION ALL
	SELECT 'positingSuffix', 'PositedAt', 1 UNION ALL
	SELECT 'positorRange', 'tinyint', 1 UNION ALL
	SELECT 'positorSuffix', 'Positor', 1 UNION ALL
	SELECT 'reliabilityRange', 'tinyint', 1 UNION ALL
	SELECT 'reliabilitySuffix', 'Reliability', 1 UNION ALL
	SELECT 'reliableCutoff', '1', 1 UNION ALL
	SELECT 'deleteReliability', '0', 1 UNION ALL
	SELECT 'reliableSuffix', 'Reliable', 1 UNION ALL
	SELECT 'partitioning', 'false', 1 UNION ALL
	SELECT 'entityIntegrity', 'true', 1 UNION ALL
	SELECT 'restatability', 'true', 1 UNION ALL
	SELECT 'idempotency', 'false', 1 UNION ALL
	SELECT 'naming', 'improved', 1 UNION ALL
	SELECT 'positSuffix', 'Posit', 1 UNION ALL
	SELECT 'annexSuffix', 'Annex', 1 UNION ALL
	SELECT 'chronon', 'datetime2(7)', 1 UNION ALL
	SELECT 'now', 'sysdatetime()', 1 UNION ALL
	SELECT 'dummySuffix', 'Dummy', 1 UNION ALL
	SELECT 'versionSuffix', 'Version', 1 UNION ALL
	SELECT 'statementTypeSuffix', 'StatementType', 1 UNION ALL
	SELECT 'checksumSuffix', 'Checksum', 1 UNION ALL
	SELECT 'businessViews', 'true', 1 UNION ALL
	SELECT 'databaseTarget', 'SQLServer', 1 UNION ALL
	SELECT 'temporalization', 'uni', 1 UNION ALL
	SELECT 'batchkillafterminutes', '60', 0;
	--SELECT 'temporalization', 'crt', 1;

	INSERT INTO [MeDriAnchor].[SettingsEnvironment]
		(
		[Environment_ID],
		[SettingKey],
		[SettingValue],
		[SettingInSchemaMD]
		)
	SELECT @Environment_ID, 'encapsulation', 'DwhDev', 1 UNION ALL
	SELECT @Environment_ID, 'batchkillafterminutes', '60', 0;

	SET @Environment_ID = (SELECT [Environment_ID] FROM [MeDriAnchor].[Environment] WHERE [EnvironmentName] = 'UAT');

	INSERT INTO [MeDriAnchor].[SettingsEnvironment]
		(
		[Environment_ID],
		[SettingKey],
		[SettingValue],
		[SettingInSchemaMD]
		)
	SELECT @Environment_ID, 'encapsulation', 'DwhUat', 1 UNION ALL
	SELECT @Environment_ID, 'batchkillafterminutes', '60', 0;

	SET @Environment_ID = (SELECT [Environment_ID] FROM [MeDriAnchor].[Environment] WHERE [EnvironmentName] = 'PRODUCTION');

	INSERT INTO [MeDriAnchor].[SettingsEnvironment]
		(
		[Environment_ID],
		[SettingKey],
		[SettingValue],
		[SettingInSchemaMD]
		)
	SELECT @Environment_ID, 'encapsulation', 'Dwh', 1 UNION ALL
	SELECT @Environment_ID, 'batchkillafterminutes', '60', 0;

END

-- add the default server types
IF NOT EXISTS(SELECT * FROM [MeDriAnchor].[DBServerType])
BEGIN
	INSERT INTO [MeDriAnchor].[DBServerType]
	(
	[DBServerType], 
	[DBServerConnectionString],
	[DBServerConnectionStringTrusted]
	)
	SELECT 'SQLSERVER', 'Server={SERVER};Database={DATABASE};User Id={USER};Password={PASSWORD};', 'Server={SERVER};Database={DATABASE};Trusted_Connection=True;'
	UNION ALL
	SELECT 'SQLAZURE', 'Server=tcp:{SERVER};Database={DATABASE};User ID={USER}@{SERVER_SHORT};Password={PASSWORD};', ''
	UNION ALL
	SELECT 'MYSQL', 'Server={SERVER};Database={DATABASE};Uid={USER};Pwd={PASSWORD};', ''
	UNION ALL
	SELECT 'PostgreSQL', 'User ID={USER};Password={PASSWORD};Host={SERVER};Port=5432;Database={DATABASE};Pooling=true;Min Pool Size=0;Max Pool Size=100;Connection Lifetime=0;', '';
END

-- add the default server
IF NOT EXISTS(SELECT * FROM [MeDriAnchor].[DBServerType])
BEGIN
	INSERT INTO [MeDriAnchor].[DBServer]
		(
		[DBServerTypeID],
		[ServerName]
		)
	SELECT	(SELECT [DBServerTypeID] FROM [MeDriAnchor].[DBServerType] WHERE [DBServerType] = 'SQLSERVER'),
			'TECHNOBITCH';
END
GO

PRINT 'END: Loading MeDriAnchor default data...';
GO