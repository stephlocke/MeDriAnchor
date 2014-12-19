
CREATE PROCEDURE [MeDriAnchor].[sspDropDWHObjectView]
(
	@Environment_ID SMALLINT,
	@Debug BIT = 0
)
AS
/*
GENERATES THE SQL FOR THE DROP OF A VIEW
*/
DECLARE @SQL NVARCHAR(MAX) = '';
DECLARE @encapsulation NVARCHAR(100);

BEGIN TRY

	SELECT @encapsulation = MAX(CASE WHEN s.[SettingKey] = 'encapsulation' THEN COALESCE(se.[SettingValue], s.[SettingValue]) ELSE '' END)
	FROM [MeDriAnchor].[Settings] s
	LEFT OUTER JOIN [MeDriAnchor].[SettingsEnvironment] se
		ON s.[SettingKey] = se.[SettingKey]
		AND se.Environment_ID = @Environment_ID
	WHERE s.[SettingKey] IN('encapsulation');
	
	-- generate the drop
	SET @SQL += 'IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N''[' + @encapsulation + '].[_AnchorObjects]'') AND type = N''V'')' + CHAR(13)
	SET @SQL += 'DROP VIEW [' + @encapsulation + '].[_AnchorObjects];' + CHAR(13) + CHAR(13);

	IF (@Debug = 0)
	BEGIN
		EXEC sys.sp_executesql @SQL;
	END
	ELSE
	BEGIN
		PRINT @SQL;
	END

	RETURN 0;

END TRY

BEGIN CATCH

	DECLARE @ErrorMessage NVARCHAR(4000);
	DECLARE @ErrorSeverity INT;
	DECLARE @ErrorState INT;

	SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();

	RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);

	RETURN -1;

END CATCH;
