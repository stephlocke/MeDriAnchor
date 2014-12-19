
CREATE TABLE [MeDriAnchor].[DBTable] (
    [DBTableID]           BIGINT         IDENTITY (1, 1) NOT NULL,
    [DBID]                BIGINT         NOT NULL,
    [DBTableSchema]       [sysname]      NOT NULL,
    [DBTableName]         [sysname]      NOT NULL,
    [DBTableType]         NVARCHAR (20)  NOT NULL,
    [DBTableOrder]        INT            CONSTRAINT [DF_DBTable_DBTableOrder] DEFAULT ((0)) NOT NULL,
    [DBTableAlias]        [sysname]      NULL,
    [DBTableDescription]  NVARCHAR (500) NULL,
    [IsActive]            BIT            CONSTRAINT [DF_DBTable_IsActive] DEFAULT ((1)) NOT NULL,
    [MinutesBetweenLoads] INT            CONSTRAINT [DF_DBTable_MinutesBetweenLoads] DEFAULT ((1440)) NOT NULL,
    [Metadata_ID]         BIGINT         NULL,
    CONSTRAINT [PK_DBTable] PRIMARY KEY CLUSTERED ([DBTableID] ASC) ON [MeDriAnchor_Current],
    CONSTRAINT [FK_DBTable_DB] FOREIGN KEY ([DBID]) REFERENCES [MeDriAnchor].[DB] ([DBID]),
    CONSTRAINT [FK_DBTable_Metadata] FOREIGN KEY ([Metadata_ID]) REFERENCES [MeDriAnchor].[Metadata] ([Metadata_ID])
);






GO
CREATE TRIGGER [MeDriAnchor].[atrDBTable_Update]ON [MeDriAnchor].[DBTable] WITH EXECUTE AS 'MeDriAnchorUser'FOR UPDATEAS/**revisions: - author: MeDriAnchor	date: 24 Nov 2014revisions: - author: MeDriAnchor	date: 24 Nov 2014summary:	>				Records the update of an [MeDriAnchor].[DBTable] table record - code:	Cannot be called from client code	parameters: n/areturns: on success nothing, otherwise throws an error**/BEGIN TRY	INSERT INTO [MeDriAnchor].[DBTable_Shadow]	([ShadowType],[DBTableID],[DBID],[DBTableSchema],[DBTableName],[DBTableType],[DBTableOrder],[DBTableAlias],[DBTableDescription],[IsActive],[MinutesBetweenLoads],[Metadata_ID])	SELECT 'U',[DELETED].[DBTableID],[DELETED].[DBID],[DELETED].[DBTableSchema],[DELETED].[DBTableName],[DELETED].[DBTableType],[DELETED].[DBTableOrder],[DELETED].[DBTableAlias],[DELETED].[DBTableDescription],[DELETED].[IsActive],[DELETED].[MinutesBetweenLoads],[DELETED].[Metadata_ID]	FROM DELETED;END TRYBEGIN CATCH	DECLARE @ErrorMessage NVARCHAR(4000);	DECLARE @ErrorSeverity INT;	DECLARE @ErrorState INT;	SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();	RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);END CATCH;
GO
CREATE TRIGGER [MeDriAnchor].[atrDBTable_Insert]ON [MeDriAnchor].[DBTable] WITH EXECUTE AS 'MeDriAnchorUser'FOR INSERTAS/**revisions: - author: MeDriAnchor	date: 24 Nov 2014summary:	>				Records the insert of an [MeDriAnchor].[DBTable] table record - code:	Cannot be called from client code	parameters: n/areturns: on success nothing, otherwise throws an error**/BEGIN TRY	INSERT INTO [MeDriAnchor].[DBTable_Shadow]	([ShadowType],[DBTableID],[DBID],[DBTableSchema],[DBTableName],[DBTableType],[DBTableOrder],[DBTableAlias],[DBTableDescription],[IsActive],[MinutesBetweenLoads],[Metadata_ID])	SELECT 'I',[INSERTED].[DBTableID],[INSERTED].[DBID],[INSERTED].[DBTableSchema],[INSERTED].[DBTableName],[INSERTED].[DBTableType],[INSERTED].[DBTableOrder],[INSERTED].[DBTableAlias],[INSERTED].[DBTableDescription],[INSERTED].[IsActive],[INSERTED].[MinutesBetweenLoads],[INSERTED].[Metadata_ID]	FROM INSERTED;END TRYBEGIN CATCH	DECLARE @ErrorMessage NVARCHAR(4000);	DECLARE @ErrorSeverity INT;	DECLARE @ErrorState INT;	SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();	RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);END CATCH;
GO
CREATE TRIGGER [MeDriAnchor].[atrDBTable_Delete]ON [MeDriAnchor].[DBTable] WITH EXECUTE AS 'MeDriAnchorUser'FOR DELETEAS/**revisions: - author: MeDriAnchor	date: 24 Nov 2014summary:	>				Records the delete of an [MeDriAnchor].[DBTable] table record - code:	Cannot be called from client code	parameters: n/areturns: on success nothing, otherwise throws an error**/BEGIN TRY	INSERT INTO [MeDriAnchor].[DBTable_Shadow]	([ShadowType],[DBTableID],[DBID],[DBTableSchema],[DBTableName],[DBTableType],[DBTableOrder],[DBTableAlias],[DBTableDescription],[IsActive],[MinutesBetweenLoads],[Metadata_ID])	SELECT 'D',[DELETED].[DBTableID],[DELETED].[DBID],[DELETED].[DBTableSchema],[DELETED].[DBTableName],[DELETED].[DBTableType],[DELETED].[DBTableOrder],[DELETED].[DBTableAlias],[DELETED].[DBTableDescription],[DELETED].[IsActive],[DELETED].[MinutesBetweenLoads],[DELETED].[Metadata_ID]	FROM DELETED;END TRYBEGIN CATCH	DECLARE @ErrorMessage NVARCHAR(4000);	DECLARE @ErrorSeverity INT;	DECLARE @ErrorState INT;	SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();	RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);END CATCH;