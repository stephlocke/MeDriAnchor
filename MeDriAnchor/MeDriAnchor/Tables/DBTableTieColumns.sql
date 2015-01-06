
CREATE TABLE [MeDriAnchor].[DBTableTieColumns] (
    [DBTableTieColumnsID] INT           IDENTITY (1, 1) NOT NULL,
    [TieID]               INT           NOT NULL,
    [DBTableColumnID]     BIGINT        NOT NULL,
    [IsIdentity]          BIT           CONSTRAINT [DF_DBTableTieColumns_IsIdentity] DEFAULT ((0)) NOT NULL,
    [AnchorMnemonicRef]   NVARCHAR (3)  CONSTRAINT [DF_DBTableTieColumns_AnchorMnemonicRef] DEFAULT ('') NOT NULL,
    [RoleName]            NVARCHAR (50) NOT NULL,
    [TieJoinOrder]        SMALLINT      CONSTRAINT [DF_DBTableTieColumns_TieJoinOrder] DEFAULT ((0)) NOT NULL,
    [TieJoinColumn]       [sysname]     CONSTRAINT [DF_DBTableTieColumns_TieJoinColumn] DEFAULT ('') NOT NULL,
    [Metadata_ID]         BIGINT        NULL,
    CONSTRAINT [PK_DBTableTieColumns] PRIMARY KEY CLUSTERED ([DBTableTieColumnsID] ASC),
    CONSTRAINT [FK_DBTableTieColumns_DBTableTie] FOREIGN KEY ([TieID]) REFERENCES [MeDriAnchor].[DBTableTie] ([TieID]),
    CONSTRAINT [FK_DBTableTieColumns_Metadata] FOREIGN KEY ([Metadata_ID]) REFERENCES [MeDriAnchor].[Metadata] ([Metadata_ID])
);





GO
CREATE TRIGGER [MeDriAnchor].[atrDBTableTieColumns_Update]ON [MeDriAnchor].[DBTableTieColumns] WITH EXECUTE AS 'MeDriAnchorUser'FOR UPDATEAS/**revisions: - author: MeDriAnchor	date: 05 Jan 2015revisions: - author: MeDriAnchor	date: 05 Jan 2015summary:	>				Records the update of an [MeDriAnchor].[DBTableTieColumns] table record - code:	Cannot be called from client code	parameters: n/areturns: on success nothing, otherwise throws an error**/BEGIN TRY	INSERT INTO [MeDriAnchor].[DBTableTieColumns_Shadow]	([ShadowType],[DBTableTieColumnsID],[TieID],[DBTableColumnID],[IsIdentity],[AnchorMnemonicRef],[RoleName],[TieJoinOrder],[TieJoinColumn],[Metadata_ID])	SELECT 'U',[DELETED].[DBTableTieColumnsID],[DELETED].[TieID],[DELETED].[DBTableColumnID],[DELETED].[IsIdentity],[DELETED].[AnchorMnemonicRef],[DELETED].[RoleName],[DELETED].[TieJoinOrder],[DELETED].[TieJoinColumn],[DELETED].[Metadata_ID]	FROM DELETED;END TRYBEGIN CATCH	DECLARE @ErrorMessage NVARCHAR(4000);	DECLARE @ErrorSeverity INT;	DECLARE @ErrorState INT;	SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();	RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);END CATCH;
GO
CREATE TRIGGER [MeDriAnchor].[atrDBTableTieColumns_Insert]ON [MeDriAnchor].[DBTableTieColumns] WITH EXECUTE AS 'MeDriAnchorUser'FOR INSERTAS/**revisions: - author: MeDriAnchor	date: 05 Jan 2015summary:	>				Records the insert of an [MeDriAnchor].[DBTableTieColumns] table record - code:	Cannot be called from client code	parameters: n/areturns: on success nothing, otherwise throws an error**/BEGIN TRY	INSERT INTO [MeDriAnchor].[DBTableTieColumns_Shadow]	([ShadowType],[DBTableTieColumnsID],[TieID],[DBTableColumnID],[IsIdentity],[AnchorMnemonicRef],[RoleName],[TieJoinOrder],[TieJoinColumn],[Metadata_ID])	SELECT 'I',[INSERTED].[DBTableTieColumnsID],[INSERTED].[TieID],[INSERTED].[DBTableColumnID],[INSERTED].[IsIdentity],[INSERTED].[AnchorMnemonicRef],[INSERTED].[RoleName],[INSERTED].[TieJoinOrder],[INSERTED].[TieJoinColumn],[INSERTED].[Metadata_ID]	FROM INSERTED;END TRYBEGIN CATCH	DECLARE @ErrorMessage NVARCHAR(4000);	DECLARE @ErrorSeverity INT;	DECLARE @ErrorState INT;	SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();	RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);END CATCH;
GO
CREATE TRIGGER [MeDriAnchor].[atrDBTableTieColumns_Delete]ON [MeDriAnchor].[DBTableTieColumns] WITH EXECUTE AS 'MeDriAnchorUser'FOR DELETEAS/**revisions: - author: MeDriAnchor	date: 05 Jan 2015summary:	>				Records the delete of an [MeDriAnchor].[DBTableTieColumns] table record - code:	Cannot be called from client code	parameters: n/areturns: on success nothing, otherwise throws an error**/BEGIN TRY	INSERT INTO [MeDriAnchor].[DBTableTieColumns_Shadow]	([ShadowType],[DBTableTieColumnsID],[TieID],[DBTableColumnID],[IsIdentity],[AnchorMnemonicRef],[RoleName],[TieJoinOrder],[TieJoinColumn],[Metadata_ID])	SELECT 'D',[DELETED].[DBTableTieColumnsID],[DELETED].[TieID],[DELETED].[DBTableColumnID],[DELETED].[IsIdentity],[DELETED].[AnchorMnemonicRef],[DELETED].[RoleName],[DELETED].[TieJoinOrder],[DELETED].[TieJoinColumn],[DELETED].[Metadata_ID]	FROM DELETED;END TRYBEGIN CATCH	DECLARE @ErrorMessage NVARCHAR(4000);	DECLARE @ErrorSeverity INT;	DECLARE @ErrorState INT;	SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();	RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);END CATCH;