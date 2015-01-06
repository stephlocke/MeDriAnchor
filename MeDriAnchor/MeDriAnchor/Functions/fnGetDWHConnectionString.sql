CREATE FUNCTION [MeDriAnchor].[fnGetDWHConnectionString](@Environment_ID SMALLINT)
RETURNS NVARCHAR(MAX)
AS
BEGIN

	RETURN (SELECT	REPLACE(REPLACE(REPLACE(REPLACE(REPLACE((CASE WHEN ISNULL(CONVERT(NVARCHAR(256), db.[DBUserName]), '') = ''
				THEN st.[DBServerConnectionStringTrusted] -- no username so a trusted connection
				ELSE st.[DBServerConnectionString] -- a username so not a trusted connection
			END), '{SERVER}', s.[ServerName]), '{DATABASE}', db.[DBName]), '{USER}', db.[DBUserName]),
			'{PASSWORD}', db.[DBUserPassword]), 
			'@{SERVER_SHORT}', CASE WHEN CHARINDEX('@', db.[DBUserName]) = 0 THEN '@' + REPLACE(s.[ServerName], '.database.windows.net', '') ELSE '' END)
	FROM [MeDriAnchor].[DBServer] s
	INNER JOIN [MeDriAnchor].[DBServerType] st
		ON s.[DBServerTypeID] = st.[DBServerTypeID]
	INNER JOIN [MeDriAnchor].[DB] db
		ON s.[DBServerID] = db.[DBServerID]
	WHERE db.[DBIsDestination] = 1
		AND (db.[Environment_ID] = @Environment_ID OR db.[Environment_ID] IS NULL));

END
