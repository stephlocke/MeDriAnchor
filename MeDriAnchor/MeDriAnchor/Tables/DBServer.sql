
CREATE TABLE [MeDriAnchor].[DBServer] (
    [DBServerID]     BIGINT        IDENTITY (1, 1) NOT NULL,
    [DBServerTypeID] SMALLINT      NULL,
    [ServerName]     [sysname]     NOT NULL,
    [ServerIP]       NVARCHAR (30) NULL,
    [Metadata_ID]    BIGINT        NULL,
    CONSTRAINT [PK_DBServer] PRIMARY KEY CLUSTERED ([DBServerID] ASC) ON [MeDriAnchor_Current],
    CONSTRAINT [FK_DBServer_DBServerType] FOREIGN KEY ([DBServerTypeID]) REFERENCES [MeDriAnchor].[DBServerType] ([DBServerTypeID]),
    CONSTRAINT [FK_DBServer_Metadata] FOREIGN KEY ([Metadata_ID]) REFERENCES [MeDriAnchor].[Metadata] ([Metadata_ID])
);








GO
CREATE TRIGGER [MeDriAnchor].[atrDBServer_Update]ON [MeDriAnchor].[DBServer] WITH EXECUTE AS 'MeDriAnchorUser'FOR UPDATEAS/**revisions: - author: MeDriAnchor	date: 05 Jan 2015revisions: - author: MeDriAnchor	date: 05 Jan 2015summary:	>				Records the update of an [MeDriAnchor].[DBServer] table record - code:	Cannot be called from client code	parameters: n/areturns: on success nothing, otherwise throws an error**/BEGIN TRY	INSERT INTO [MeDriAnchor].[DBServer_Shadow]	([ShadowType],[DBServerID],[DBServerTypeID],[ServerName],[ServerIP],[Metadata_ID])	SELECT 'U',[DELETED].[DBServerID],[DELETED].[DBServerTypeID],[DELETED].[ServerName],[DELETED].[ServerIP],[DELETED].[Metadata_ID]	FROM DELETED;END TRYBEGIN CATCH	DECLARE @ErrorMessage NVARCHAR(4000);	DECLARE @ErrorSeverity INT;	DECLARE @ErrorState INT;	SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();	RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);END CATCH;
GO
CREATE TRIGGER [MeDriAnchor].[atrDBServer_Insert]ON [MeDriAnchor].[DBServer] WITH EXECUTE AS 'MeDriAnchorUser'FOR INSERTAS/**revisions: - author: MeDriAnchor	date: 05 Jan 2015summary:	>				Records the insert of an [MeDriAnchor].[DBServer] table record - code:	Cannot be called from client code	parameters: n/areturns: on success nothing, otherwise throws an error**/BEGIN TRY	INSERT INTO [MeDriAnchor].[DBServer_Shadow]	([ShadowType],[DBServerID],[DBServerTypeID],[ServerName],[ServerIP],[Metadata_ID])	SELECT 'I',[INSERTED].[DBServerID],[INSERTED].[DBServerTypeID],[INSERTED].[ServerName],[INSERTED].[ServerIP],[INSERTED].[Metadata_ID]	FROM INSERTED;END TRYBEGIN CATCH	DECLARE @ErrorMessage NVARCHAR(4000);	DECLARE @ErrorSeverity INT;	DECLARE @ErrorState INT;	SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();	RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);END CATCH;
GO
CREATE TRIGGER [MeDriAnchor].[atrDBServer_Delete]ON [MeDriAnchor].[DBServer] WITH EXECUTE AS 'MeDriAnchorUser'FOR DELETEAS/**revisions: - author: MeDriAnchor	date: 05 Jan 2015summary:	>				Records the delete of an [MeDriAnchor].[DBServer] table record - code:	Cannot be called from client code	parameters: n/areturns: on success nothing, otherwise throws an error**/BEGIN TRY	INSERT INTO [MeDriAnchor].[DBServer_Shadow]	([ShadowType],[DBServerID],[DBServerTypeID],[ServerName],[ServerIP],[Metadata_ID])	SELECT 'D',[DELETED].[DBServerID],[DELETED].[DBServerTypeID],[DELETED].[ServerName],[DELETED].[ServerIP],[DELETED].[Metadata_ID]	FROM DELETED;END TRYBEGIN CATCH	DECLARE @ErrorMessage NVARCHAR(4000);	DECLARE @ErrorSeverity INT;	DECLARE @ErrorState INT;	SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();	RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);END CATCH;