
CREATE TABLE [MeDriAnchor].[DBTableTie] (
    [TieID]          INT           IDENTITY (1, 1) NOT NULL,
    [TieMnemonic]    NVARCHAR (20) CONSTRAINT [DF_DBTableTie_TieMnemonic] DEFAULT ('') NOT NULL,
    [GenerateID]     BIT           CONSTRAINT [DF_DBTableTie_GenerateID] DEFAULT ((0)) NOT NULL,
    [IsHistorised]   BIT           CONSTRAINT [DF_DBTableTie_IsHistorised] DEFAULT ((1)) NOT NULL,
    [KnotMnemonic]   NVARCHAR (20) CONSTRAINT [DF_DBTableTie_KnotMnemonic] DEFAULT ('') NOT NULL,
    [KnotRoleName]   NVARCHAR (50) CONSTRAINT [DF_DBTableTie_KnotRoleName] DEFAULT ('') NOT NULL,
    [Environment_ID] SMALLINT      NOT NULL,
    [Metadata_ID]    BIGINT        NULL,
    CONSTRAINT [PK_DBTableTie] PRIMARY KEY CLUSTERED ([TieID] ASC),
    CONSTRAINT [FK_DBTableTie_Metadata] FOREIGN KEY ([Metadata_ID]) REFERENCES [MeDriAnchor].[Metadata] ([Metadata_ID])
);







GO
CREATE TRIGGER [MeDriAnchor].[atrDBTableTie_Update]ON [MeDriAnchor].[DBTableTie] WITH EXECUTE AS 'MeDriAnchorUser'FOR UPDATEAS/**revisions: - author: MeDriAnchor	date: 05 Jan 2015revisions: - author: MeDriAnchor	date: 05 Jan 2015summary:	>				Records the update of an [MeDriAnchor].[DBTableTie] table record - code:	Cannot be called from client code	parameters: n/areturns: on success nothing, otherwise throws an error**/BEGIN TRY	INSERT INTO [MeDriAnchor].[DBTableTie_Shadow]	([ShadowType],[TieID],[TieMnemonic],[GenerateID],[IsHistorised],[KnotMnemonic],[KnotRoleName],[Environment_ID],[Metadata_ID])	SELECT 'U',[DELETED].[TieID],[DELETED].[TieMnemonic],[DELETED].[GenerateID],[DELETED].[IsHistorised],[DELETED].[KnotMnemonic],[DELETED].[KnotRoleName],[DELETED].[Environment_ID],[DELETED].[Metadata_ID]	FROM DELETED;END TRYBEGIN CATCH	DECLARE @ErrorMessage NVARCHAR(4000);	DECLARE @ErrorSeverity INT;	DECLARE @ErrorState INT;	SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();	RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);END CATCH;
GO
CREATE TRIGGER [MeDriAnchor].[atrDBTableTie_Insert]ON [MeDriAnchor].[DBTableTie] WITH EXECUTE AS 'MeDriAnchorUser'FOR INSERTAS/**revisions: - author: MeDriAnchor	date: 05 Jan 2015summary:	>				Records the insert of an [MeDriAnchor].[DBTableTie] table record - code:	Cannot be called from client code	parameters: n/areturns: on success nothing, otherwise throws an error**/BEGIN TRY	INSERT INTO [MeDriAnchor].[DBTableTie_Shadow]	([ShadowType],[TieID],[TieMnemonic],[GenerateID],[IsHistorised],[KnotMnemonic],[KnotRoleName],[Environment_ID],[Metadata_ID])	SELECT 'I',[INSERTED].[TieID],[INSERTED].[TieMnemonic],[INSERTED].[GenerateID],[INSERTED].[IsHistorised],[INSERTED].[KnotMnemonic],[INSERTED].[KnotRoleName],[INSERTED].[Environment_ID],[INSERTED].[Metadata_ID]	FROM INSERTED;END TRYBEGIN CATCH	DECLARE @ErrorMessage NVARCHAR(4000);	DECLARE @ErrorSeverity INT;	DECLARE @ErrorState INT;	SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();	RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);END CATCH;
GO
CREATE TRIGGER [MeDriAnchor].[atrDBTableTie_Delete]ON [MeDriAnchor].[DBTableTie] WITH EXECUTE AS 'MeDriAnchorUser'FOR DELETEAS/**revisions: - author: MeDriAnchor	date: 05 Jan 2015summary:	>				Records the delete of an [MeDriAnchor].[DBTableTie] table record - code:	Cannot be called from client code	parameters: n/areturns: on success nothing, otherwise throws an error**/BEGIN TRY	INSERT INTO [MeDriAnchor].[DBTableTie_Shadow]	([ShadowType],[TieID],[TieMnemonic],[GenerateID],[IsHistorised],[KnotMnemonic],[KnotRoleName],[Environment_ID],[Metadata_ID])	SELECT 'D',[DELETED].[TieID],[DELETED].[TieMnemonic],[DELETED].[GenerateID],[DELETED].[IsHistorised],[DELETED].[KnotMnemonic],[DELETED].[KnotRoleName],[DELETED].[Environment_ID],[DELETED].[Metadata_ID]	FROM DELETED;END TRYBEGIN CATCH	DECLARE @ErrorMessage NVARCHAR(4000);	DECLARE @ErrorSeverity INT;	DECLARE @ErrorState INT;	SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();	RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);END CATCH;