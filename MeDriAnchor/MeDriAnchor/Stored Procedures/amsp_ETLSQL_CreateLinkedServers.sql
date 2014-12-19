
CREATE PROCEDURE [MeDriAnchor].[amsp_ETLSQL_CreateLinkedServers]
AS

DECLARE @ServerName SYSNAME;
DECLARE @DBServerType NVARCHAR(100);
DECLARE @DBName SYSNAME;
DECLARE @DBUserName NVARCHAR(256); 
DECLARE @DBUserPassword NVARCHAR(256);
DECLARE @DBIsLocal BIT;
DECLARE @DBIsTrusted BIT;
DECLARE @DBServerConnectionString NVARCHAR(500);
DECLARE @SQL NVARCHAR(MAX);

BEGIN TRY

	DECLARE LINKEDSERVERS CURSOR
	READ_ONLY FORWARD_ONLY LOCAL
	FOR 
	SELECT	s.[ServerName] AS [ServerName], 
			st.[DBServerType], 
			db.[DBName],
			CONVERT(NVARCHAR(256), db.[DBUserName]) AS [DBUserName],
			CONVERT(NVARCHAR(256), db.[DBUserPassword]) AS [DBUserPassword],
			db.[DBIsLocal],
			(CASE WHEN ISNULL(CONVERT(NVARCHAR(256), db.[DBUserName]), '') = ''
				THEN st.[DBServerConnectionStringTrusted] -- no username so a trusted connection
				ELSE st.[DBServerConnectionString] -- a username so not a trusted connection
			END),
			(CASE WHEN ISNULL(CONVERT(NVARCHAR(256), db.[DBUserName]), '') = ''
				THEN 1
				ELSE 0
			END) AS [DBIsTrusted]
	FROM [MeDriAnchor].[DBServer] s
	INNER JOIN [MeDriAnchor].[DBServerType] st
		ON s.[DBServerTypeID] = st.[DBServerTypeID]
	INNER JOIN [MeDriAnchor].[DB] db
		ON s.[DBServerID] = db.[DBServerID];

	OPEN LINKEDSERVERS

	FETCH NEXT FROM LINKEDSERVERS INTO @ServerName, @DBServerType, @DBName, @DBUserName, @DBUserPassword, @DBIsLocal, @DBServerConnectionString, @DBIsTrusted;
	WHILE (@@fetch_status <> -1)
	BEGIN
		IF (@@fetch_status <> -2)
		BEGIN

			SET @DBServerConnectionString = REPLACE(@DBServerConnectionString, '{SERVER}', @ServerName);
			SET @DBServerConnectionString = REPLACE(@DBServerConnectionString, '{SERVER_SHORT}', REPLACE(@ServerName, '.database.windows.net', ''));
			SET @DBServerConnectionString = REPLACE(@DBServerConnectionString, '{DATABASE}', @DBName);
			SET @DBServerConnectionString = REPLACE(@DBServerConnectionString, '{USER}', @DBUserName);
			SET @DBServerConnectionString = REPLACE(@DBServerConnectionString, '{PASSWORD}', @DBUserPassword);

			IF (@DBServerType = 'SQLSERVER')
			BEGIN
			
				IF (@DBIsLocal = 0 AND NOT EXISTS(SELECT * FROM master.sys.servers WHERE [name] = @ServerName))
				BEGIN
					EXEC master.dbo.sp_dropserver @server = @ServerName, @droplogins = 'droplogins';
				END

				-- add the linked server
				EXEC master.dbo.sp_addlinkedserver 
					@server = @ServerName, 
					@srvproduct = N'SQL Server';

				-- add the login (either windows or sql)
				IF (@DBIsTrusted = 1)
				BEGIN
					EXEC master.dbo.sp_addlinkedsrvlogin 
						@rmtsrvname = @ServerName,
						@useself = N'True',
						@locallogin = NULL,
						@rmtuser = NULL,
						@rmtpassword = NULL;
				END
				ELSE
				BEGIN
					EXEC master.dbo.sp_addlinkedsrvlogin 
						@rmtsrvname = @ServerName,
						@useself = N'False',
						@locallogin = NULL,
						@rmtuser = @DBUserName,
						@rmtpassword = @DBUserPassword;
				END

				-- set the rpc options
				EXEC master.dbo.sp_serveroption 
					@server = @ServerName, 
					@optname = N'rpc', 
					@optvalue = N'true';

				EXEC master.dbo.sp_serveroption 
					@server = @ServerName, 
					@optname = N'rpc out', 
					@optvalue = N'true';

			END

			IF (@DBServerType = 'SQLAZURE')
			BEGIN
			
				IF (NOT EXISTS(SELECT * FROM master.sys.servers WHERE [name] = @ServerName))
				BEGIN
					EXEC master.dbo.sp_dropserver @server = @ServerName, @droplogins = 'droplogins';
				END

				-- add the linked server
				EXEC master.dbo.sp_addlinkedserver 
					@server = @ServerName, 
					@srvproduct = N'SQLSERVER', 
					@provider = N'SQLNCLI11', 
					@provstr = @DBServerConnectionString;

				EXEC master.dbo.sp_addlinkedsrvlogin 
					@rmtsrvname = @ServerName,
					@useself = N'False',
					@locallogin = NULL,
					@rmtuser = @DBUserName,
					@rmtpassword = @DBUserPassword;

				-- set the rpc options
				EXEC master.dbo.sp_serveroption 
					@server = @ServerName, 
					@optname = N'rpc', 
					@optvalue = N'true';

				EXEC master.dbo.sp_serveroption 
					@server = @ServerName, 
					@optname = N'rpc out', 
					@optvalue = N'true';


			END

		END
		FETCH NEXT FROM LINKEDSERVERS INTO @ServerName, @DBServerType, @DBName, @DBUserName, @DBUserPassword, @DBIsLocal, @DBServerConnectionString, @DBIsTrusted;
	END

	CLOSE LINKEDSERVERS;
	DEALLOCATE LINKEDSERVERS;

END TRY

BEGIN CATCH

	DECLARE @ErrorMessage NVARCHAR(4000);
	DECLARE @ErrorSeverity INT;
	DECLARE @ErrorState INT;

	SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();

	RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);

	RETURN -1;

END CATCH;
