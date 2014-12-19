
CREATE TABLE [MeDriAnchor].[SeverityEmailRecipients] (
    [SeverityID]       TINYINT         IDENTITY (1, 1) NOT NULL,
    [DistributionList] NVARCHAR (2000) NOT NULL,
    CONSTRAINT [PK_SeverityEmailRecipients] PRIMARY KEY CLUSTERED ([SeverityID] ASC) ON [MeDriAnchor_Current],
    CONSTRAINT [FK_SeverityEmailRecipients_Severity] FOREIGN KEY ([SeverityID]) REFERENCES [MeDriAnchor].[Severity] ([SeverityID])
);






GO
CREATE TRIGGER [MeDriAnchor].[atrSeverityEmailRecipients_Update]ON [MeDriAnchor].[SeverityEmailRecipients] WITH EXECUTE AS 'MeDriAnchorUser'FOR UPDATEAS/**revisions: - author: MeDriAnchor	date: 24 Nov 2014revisions: - author: MeDriAnchor	date: 24 Nov 2014summary:	>				Records the update of an [MeDriAnchor].[SeverityEmailRecipients] table record - code:	Cannot be called from client code	parameters: n/areturns: on success nothing, otherwise throws an error**/BEGIN TRY	INSERT INTO [MeDriAnchor].[SeverityEmailRecipients_Shadow]	([ShadowType],[SeverityID],[DistributionList])	SELECT 'U',[DELETED].[SeverityID],[DELETED].[DistributionList]	FROM DELETED;END TRYBEGIN CATCH	DECLARE @ErrorMessage NVARCHAR(4000);	DECLARE @ErrorSeverity INT;	DECLARE @ErrorState INT;	SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();	RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);END CATCH;
GO
CREATE TRIGGER [MeDriAnchor].[atrSeverityEmailRecipients_Insert]ON [MeDriAnchor].[SeverityEmailRecipients] WITH EXECUTE AS 'MeDriAnchorUser'FOR INSERTAS/**revisions: - author: MeDriAnchor	date: 24 Nov 2014summary:	>				Records the insert of an [MeDriAnchor].[SeverityEmailRecipients] table record - code:	Cannot be called from client code	parameters: n/areturns: on success nothing, otherwise throws an error**/BEGIN TRY	INSERT INTO [MeDriAnchor].[SeverityEmailRecipients_Shadow]	([ShadowType],[SeverityID],[DistributionList])	SELECT 'I',[INSERTED].[SeverityID],[INSERTED].[DistributionList]	FROM INSERTED;END TRYBEGIN CATCH	DECLARE @ErrorMessage NVARCHAR(4000);	DECLARE @ErrorSeverity INT;	DECLARE @ErrorState INT;	SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();	RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);END CATCH;
GO
CREATE TRIGGER [MeDriAnchor].[atrSeverityEmailRecipients_Delete]ON [MeDriAnchor].[SeverityEmailRecipients] WITH EXECUTE AS 'MeDriAnchorUser'FOR DELETEAS/**revisions: - author: MeDriAnchor	date: 24 Nov 2014summary:	>				Records the delete of an [MeDriAnchor].[SeverityEmailRecipients] table record - code:	Cannot be called from client code	parameters: n/areturns: on success nothing, otherwise throws an error**/BEGIN TRY	INSERT INTO [MeDriAnchor].[SeverityEmailRecipients_Shadow]	([ShadowType],[SeverityID],[DistributionList])	SELECT 'D',[DELETED].[SeverityID],[DELETED].[DistributionList]	FROM DELETED;END TRYBEGIN CATCH	DECLARE @ErrorMessage NVARCHAR(4000);	DECLARE @ErrorSeverity INT;	DECLARE @ErrorState INT;	SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();	RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);END CATCH;