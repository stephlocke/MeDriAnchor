
CREATE FUNCTION [MeDriAnchor].[fnGetSchemaMetadataElement](@Environment_ID SMALLINT)
RETURNS XML
AS
BEGIN
	
	DECLARE @XML NVARCHAR(MAX) = '<metadata ';

	SELECT @XML += s.[SettingKey] + '=''' + COALESCE(se.[SettingValue], s.[SettingValue]) + ''' '
	FROM [MeDriAnchor].[Settings] s
	LEFT OUTER JOIN [MeDriAnchor].[SettingsEnvironment] se
		ON s.[SettingKey] = se.[SettingKey]
		AND se.Environment_ID = @Environment_ID
	WHERE s.[SettingInSchemaMD] = 1;

	SET @XML = @XML + ' />';

	RETURN CONVERT(XML, @XML);

END
