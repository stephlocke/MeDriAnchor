
CREATE TABLE [MeDriAnchor].[Severity] (
    [SeverityID]    TINYINT      IDENTITY (1, 1) NOT NULL,
    [ServerityName] VARCHAR (20) NOT NULL,
    CONSTRAINT [PK_Severity] PRIMARY KEY CLUSTERED ([SeverityID] ASC) ON [MeDriAnchor_Current]
);






GO
CREATE TRIGGER [MeDriAnchor].[atrSeverity_Update]ON [MeDriAnchor].[Severity] WITH EXECUTE AS 'MeDriAnchorUser'FOR UPDATEAS/**revisions: - author: MeDriAnchor	date: 24 Nov 2014revisions: - author: MeDriAnchor	date: 24 Nov 2014summary:	>				Records the update of an [MeDriAnchor].[Severity] table record - code:	Cannot be called from client code	parameters: n/areturns: on success nothing, otherwise throws an error**/BEGIN TRY	INSERT INTO [MeDriAnchor].[Severity_Shadow]	([ShadowType],[SeverityID],[ServerityName])	SELECT 'U',[DELETED].[SeverityID],[DELETED].[ServerityName]	FROM DELETED;END TRYBEGIN CATCH	DECLARE @ErrorMessage NVARCHAR(4000);	DECLARE @ErrorSeverity INT;	DECLARE @ErrorState INT;	SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();	RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);END CATCH;
GO
CREATE TRIGGER [MeDriAnchor].[atrSeverity_Insert]ON [MeDriAnchor].[Severity] WITH EXECUTE AS 'MeDriAnchorUser'FOR INSERTAS/**revisions: - author: MeDriAnchor	date: 24 Nov 2014summary:	>				Records the insert of an [MeDriAnchor].[Severity] table record - code:	Cannot be called from client code	parameters: n/areturns: on success nothing, otherwise throws an error**/BEGIN TRY	INSERT INTO [MeDriAnchor].[Severity_Shadow]	([ShadowType],[SeverityID],[ServerityName])	SELECT 'I',[INSERTED].[SeverityID],[INSERTED].[ServerityName]	FROM INSERTED;END TRYBEGIN CATCH	DECLARE @ErrorMessage NVARCHAR(4000);	DECLARE @ErrorSeverity INT;	DECLARE @ErrorState INT;	SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();	RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);END CATCH;
GO
CREATE TRIGGER [MeDriAnchor].[atrSeverity_Delete]ON [MeDriAnchor].[Severity] WITH EXECUTE AS 'MeDriAnchorUser'FOR DELETEAS/**revisions: - author: MeDriAnchor	date: 24 Nov 2014summary:	>				Records the delete of an [MeDriAnchor].[Severity] table record - code:	Cannot be called from client code	parameters: n/areturns: on success nothing, otherwise throws an error**/BEGIN TRY	INSERT INTO [MeDriAnchor].[Severity_Shadow]	([ShadowType],[SeverityID],[ServerityName])	SELECT 'D',[DELETED].[SeverityID],[DELETED].[ServerityName]	FROM DELETED;END TRYBEGIN CATCH	DECLARE @ErrorMessage NVARCHAR(4000);	DECLARE @ErrorSeverity INT;	DECLARE @ErrorState INT;	SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();	RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);END CATCH;