CREATE VIEW [MeDriAnchor].[svEnvironmentSchemas]
AS
SELECT	env.[Environment_ID],
		env.[EnvironmentName],
		sett.[SettingValue] AS [Encapsulation]
FROM [MeDriAnchor].[Environment] env
INNER JOIN
(
SELECT	se.[Environment_ID],
		COALESCE(se.[SettingValue], s.[SettingValue]) AS [SettingValue]
FROM [MeDriAnchor].[Settings] s
LEFT OUTER JOIN [MeDriAnchor].[SettingsEnvironment] se
	ON s.[SettingKey] = se.[SettingKey]
WHERE s.[SettingKey] = 'encapsulation'
) sett
	ON sett.[Environment_ID] = env.[Environment_ID];
