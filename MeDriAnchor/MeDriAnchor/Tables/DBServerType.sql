
CREATE TABLE [MeDriAnchor].[DBServerType] (
    [DBServerTypeID]                  SMALLINT       IDENTITY (1, 1) NOT NULL,
    [DBServerType]                    NVARCHAR (100) NOT NULL,
    [DBServerConnectionString]        NVARCHAR (500) NULL,
    [DBServerConnectionStringTrusted] NVARCHAR (500) NULL,
    [Metadata_ID]                     BIGINT         NULL,
    CONSTRAINT [PK_DBServerType] PRIMARY KEY CLUSTERED ([DBServerTypeID] ASC) ON [MeDriAnchor_Current],
    CONSTRAINT [FK_DBServerType_Metadata] FOREIGN KEY ([Metadata_ID]) REFERENCES [MeDriAnchor].[Metadata] ([Metadata_ID])
);






GO
CREATE TRIGGER [MeDriAnchor].[atrDBServerType_Update]ON [MeDriAnchor].[DBServerType] WITH EXECUTE AS 'MeDriAnchorUser'FOR UPDATEAS/**revisions: - author: MeDriAnchor	date: 24 Nov 2014revisions: - author: MeDriAnchor	date: 24 Nov 2014summary:	>				Records the update of an [MeDriAnchor].[DBServerType] table record - code:	Cannot be called from client code	parameters: n/areturns: on success nothing, otherwise throws an error**/BEGIN TRY	INSERT INTO [MeDriAnchor].[DBServerType_Shadow]	([ShadowType],[DBServerTypeID],[DBServerType],[DBServerConnectionString],[DBServerConnectionStringTrusted],[Metadata_ID])	SELECT 'U',[DELETED].[DBServerTypeID],[DELETED].[DBServerType],[DELETED].[DBServerConnectionString],[DELETED].[DBServerConnectionStringTrusted],[DELETED].[Metadata_ID]	FROM DELETED;END TRYBEGIN CATCH	DECLARE @ErrorMessage NVARCHAR(4000);	DECLARE @ErrorSeverity INT;	DECLARE @ErrorState INT;	SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();	RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);END CATCH;
GO
CREATE TRIGGER [MeDriAnchor].[atrDBServerType_Insert]ON [MeDriAnchor].[DBServerType] WITH EXECUTE AS 'MeDriAnchorUser'FOR INSERTAS/**revisions: - author: MeDriAnchor	date: 24 Nov 2014summary:	>				Records the insert of an [MeDriAnchor].[DBServerType] table record - code:	Cannot be called from client code	parameters: n/areturns: on success nothing, otherwise throws an error**/BEGIN TRY	INSERT INTO [MeDriAnchor].[DBServerType_Shadow]	([ShadowType],[DBServerTypeID],[DBServerType],[DBServerConnectionString],[DBServerConnectionStringTrusted],[Metadata_ID])	SELECT 'I',[INSERTED].[DBServerTypeID],[INSERTED].[DBServerType],[INSERTED].[DBServerConnectionString],[INSERTED].[DBServerConnectionStringTrusted],[INSERTED].[Metadata_ID]	FROM INSERTED;END TRYBEGIN CATCH	DECLARE @ErrorMessage NVARCHAR(4000);	DECLARE @ErrorSeverity INT;	DECLARE @ErrorState INT;	SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();	RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);END CATCH;
GO
CREATE TRIGGER [MeDriAnchor].[atrDBServerType_Delete]ON [MeDriAnchor].[DBServerType] WITH EXECUTE AS 'MeDriAnchorUser'FOR DELETEAS/**revisions: - author: MeDriAnchor	date: 24 Nov 2014summary:	>				Records the delete of an [MeDriAnchor].[DBServerType] table record - code:	Cannot be called from client code	parameters: n/areturns: on success nothing, otherwise throws an error**/BEGIN TRY	INSERT INTO [MeDriAnchor].[DBServerType_Shadow]	([ShadowType],[DBServerTypeID],[DBServerType],[DBServerConnectionString],[DBServerConnectionStringTrusted],[Metadata_ID])	SELECT 'D',[DELETED].[DBServerTypeID],[DELETED].[DBServerType],[DELETED].[DBServerConnectionString],[DELETED].[DBServerConnectionStringTrusted],[DELETED].[Metadata_ID]	FROM DELETED;END TRYBEGIN CATCH	DECLARE @ErrorMessage NVARCHAR(4000);	DECLARE @ErrorSeverity INT;	DECLARE @ErrorState INT;	SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();	RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);END CATCH;