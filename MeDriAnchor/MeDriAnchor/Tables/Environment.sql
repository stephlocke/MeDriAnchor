
CREATE TABLE [MeDriAnchor].[Environment] (
    [Environment_ID]  SMALLINT       IDENTITY (1, 1) NOT NULL,
    [EnvironmentName] NVARCHAR (100) NOT NULL,
    CONSTRAINT [PK_Environment] PRIMARY KEY CLUSTERED ([Environment_ID] ASC) ON [MeDriAnchor_Current]
);








GO
CREATE TRIGGER [MeDriAnchor].[atrEnvironment_Update]ON [MeDriAnchor].[Environment] WITH EXECUTE AS 'MeDriAnchorUser'FOR UPDATEAS/**revisions: - author: MeDriAnchor	date: 05 Jan 2015revisions: - author: MeDriAnchor	date: 05 Jan 2015summary:	>				Records the update of an [MeDriAnchor].[Environment] table record - code:	Cannot be called from client code	parameters: n/areturns: on success nothing, otherwise throws an error**/BEGIN TRY	INSERT INTO [MeDriAnchor].[Environment_Shadow]	([ShadowType],[Environment_ID],[EnvironmentName])	SELECT 'U',[DELETED].[Environment_ID],[DELETED].[EnvironmentName]	FROM DELETED;END TRYBEGIN CATCH	DECLARE @ErrorMessage NVARCHAR(4000);	DECLARE @ErrorSeverity INT;	DECLARE @ErrorState INT;	SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();	RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);END CATCH;
GO
CREATE TRIGGER [MeDriAnchor].[atrEnvironment_Insert]ON [MeDriAnchor].[Environment] WITH EXECUTE AS 'MeDriAnchorUser'FOR INSERTAS/**revisions: - author: MeDriAnchor	date: 05 Jan 2015summary:	>				Records the insert of an [MeDriAnchor].[Environment] table record - code:	Cannot be called from client code	parameters: n/areturns: on success nothing, otherwise throws an error**/BEGIN TRY	INSERT INTO [MeDriAnchor].[Environment_Shadow]	([ShadowType],[Environment_ID],[EnvironmentName])	SELECT 'I',[INSERTED].[Environment_ID],[INSERTED].[EnvironmentName]	FROM INSERTED;END TRYBEGIN CATCH	DECLARE @ErrorMessage NVARCHAR(4000);	DECLARE @ErrorSeverity INT;	DECLARE @ErrorState INT;	SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();	RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);END CATCH;
GO
CREATE TRIGGER [MeDriAnchor].[atrEnvironment_Delete]ON [MeDriAnchor].[Environment] WITH EXECUTE AS 'MeDriAnchorUser'FOR DELETEAS/**revisions: - author: MeDriAnchor	date: 05 Jan 2015summary:	>				Records the delete of an [MeDriAnchor].[Environment] table record - code:	Cannot be called from client code	parameters: n/areturns: on success nothing, otherwise throws an error**/BEGIN TRY	INSERT INTO [MeDriAnchor].[Environment_Shadow]	([ShadowType],[Environment_ID],[EnvironmentName])	SELECT 'D',[DELETED].[Environment_ID],[DELETED].[EnvironmentName]	FROM DELETED;END TRYBEGIN CATCH	DECLARE @ErrorMessage NVARCHAR(4000);	DECLARE @ErrorSeverity INT;	DECLARE @ErrorState INT;	SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();	RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);END CATCH;