
CREATE TABLE [MeDriAnchor].[DB] (
    [DBID]               BIGINT          IDENTITY (1, 1) NOT NULL,
    [DBServerID]         BIGINT          NOT NULL,
    [DBName]             [sysname]       NOT NULL,
    [DBUserName]         VARBINARY (256) NULL,
    [DBUserPassword]     VARBINARY (256) NULL,
    [DBIsLocal]          BIT             NOT NULL,
    [DBIsSource]         BIT             NOT NULL,
    [DBIsDestination]    BIT             NOT NULL,
    [Metadata_ID]        BIGINT          NULL,
    [Environment_ID]     SMALLINT        NULL,
    [StageData]          BIT             CONSTRAINT [DF_DB_StageData] DEFAULT ((0)) NOT NULL,
    [UseSchemaPromotion] BIT             CONSTRAINT [DF_DB_UseSchemaPromotion] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_DB] PRIMARY KEY CLUSTERED ([DBID] ASC) ON [MeDriAnchor_Current],
    CONSTRAINT [FK_DB_DBServer] FOREIGN KEY ([DBServerID]) REFERENCES [MeDriAnchor].[DBServer] ([DBServerID]),
    CONSTRAINT [FK_DB_Environment] FOREIGN KEY ([Environment_ID]) REFERENCES [MeDriAnchor].[Environment] ([Environment_ID]),
    CONSTRAINT [FK_DB_Metadata] FOREIGN KEY ([Metadata_ID]) REFERENCES [MeDriAnchor].[Metadata] ([Metadata_ID])
);








GO
CREATE TRIGGER [MeDriAnchor].[atrDB_Update]ON [MeDriAnchor].[DB] WITH EXECUTE AS 'MeDriAnchorUser'FOR UPDATEAS/**revisions: - author: MeDriAnchor	date: 05 Jan 2015revisions: - author: MeDriAnchor	date: 05 Jan 2015summary:	>				Records the update of an [MeDriAnchor].[DB] table record - code:	Cannot be called from client code	parameters: n/areturns: on success nothing, otherwise throws an error**/BEGIN TRY	INSERT INTO [MeDriAnchor].[DB_Shadow]	([ShadowType],[DBID],[DBServerID],[DBName],[DBUserName],[DBUserPassword],[DBIsLocal],[DBIsSource],[DBIsDestination],[Metadata_ID],[Environment_ID],[StageData],[UseSchemaPromotion])	SELECT 'U',[DELETED].[DBID],[DELETED].[DBServerID],[DELETED].[DBName],[DELETED].[DBUserName],[DELETED].[DBUserPassword],[DELETED].[DBIsLocal],[DELETED].[DBIsSource],[DELETED].[DBIsDestination],[DELETED].[Metadata_ID],[DELETED].[Environment_ID],[DELETED].[StageData],[DELETED].[UseSchemaPromotion]	FROM DELETED;END TRYBEGIN CATCH	DECLARE @ErrorMessage NVARCHAR(4000);	DECLARE @ErrorSeverity INT;	DECLARE @ErrorState INT;	SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();	RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);END CATCH;
GO
CREATE TRIGGER [MeDriAnchor].[atrDB_Insert]ON [MeDriAnchor].[DB] WITH EXECUTE AS 'MeDriAnchorUser'FOR INSERTAS/**revisions: - author: MeDriAnchor	date: 05 Jan 2015summary:	>				Records the insert of an [MeDriAnchor].[DB] table record - code:	Cannot be called from client code	parameters: n/areturns: on success nothing, otherwise throws an error**/BEGIN TRY	INSERT INTO [MeDriAnchor].[DB_Shadow]	([ShadowType],[DBID],[DBServerID],[DBName],[DBUserName],[DBUserPassword],[DBIsLocal],[DBIsSource],[DBIsDestination],[Metadata_ID],[Environment_ID],[StageData],[UseSchemaPromotion])	SELECT 'I',[INSERTED].[DBID],[INSERTED].[DBServerID],[INSERTED].[DBName],[INSERTED].[DBUserName],[INSERTED].[DBUserPassword],[INSERTED].[DBIsLocal],[INSERTED].[DBIsSource],[INSERTED].[DBIsDestination],[INSERTED].[Metadata_ID],[INSERTED].[Environment_ID],[INSERTED].[StageData],[INSERTED].[UseSchemaPromotion]	FROM INSERTED;END TRYBEGIN CATCH	DECLARE @ErrorMessage NVARCHAR(4000);	DECLARE @ErrorSeverity INT;	DECLARE @ErrorState INT;	SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();	RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);END CATCH;
GO
CREATE TRIGGER [MeDriAnchor].[atrDB_Delete]ON [MeDriAnchor].[DB] WITH EXECUTE AS 'MeDriAnchorUser'FOR DELETEAS/**revisions: - author: MeDriAnchor	date: 05 Jan 2015summary:	>				Records the delete of an [MeDriAnchor].[DB] table record - code:	Cannot be called from client code	parameters: n/areturns: on success nothing, otherwise throws an error**/BEGIN TRY	INSERT INTO [MeDriAnchor].[DB_Shadow]	([ShadowType],[DBID],[DBServerID],[DBName],[DBUserName],[DBUserPassword],[DBIsLocal],[DBIsSource],[DBIsDestination],[Metadata_ID],[Environment_ID],[StageData],[UseSchemaPromotion])	SELECT 'D',[DELETED].[DBID],[DELETED].[DBServerID],[DELETED].[DBName],[DELETED].[DBUserName],[DELETED].[DBUserPassword],[DELETED].[DBIsLocal],[DELETED].[DBIsSource],[DELETED].[DBIsDestination],[DELETED].[Metadata_ID],[DELETED].[Environment_ID],[DELETED].[StageData],[DELETED].[UseSchemaPromotion]	FROM DELETED;END TRYBEGIN CATCH	DECLARE @ErrorMessage NVARCHAR(4000);	DECLARE @ErrorSeverity INT;	DECLARE @ErrorState INT;	SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();	RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);END CATCH;