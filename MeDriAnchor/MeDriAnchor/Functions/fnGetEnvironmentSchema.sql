CREATE FUNCTION [MeDriAnchor].[fnGetEnvironmentSchema]
(
	@Environment_ID SMALLINT
)
RETURNS SYSNAME
AS
BEGIN
	
	-- get the schema for the given environment
	RETURN (SELECT COALESCE(se.[SettingValue], s.[SettingValue])
	FROM [MeDriAnchor].[Settings] s
	LEFT OUTER JOIN [MeDriAnchor].[SettingsEnvironment] se
		ON s.[SettingKey] = se.[SettingKey]
		AND se.Environment_ID = @Environment_ID
	WHERE s.[SettingKey] = 'encapsulation');

END

