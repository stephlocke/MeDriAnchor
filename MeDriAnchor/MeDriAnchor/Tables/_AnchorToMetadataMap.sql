
CREATE TABLE [MeDriAnchor].[_AnchorToMetadataMap] (
    [ATMM_ID]                    BIGINT         IDENTITY (1, 1) NOT NULL,
    [Metadata_ID]                BIGINT         NULL,
    [Environment_ID]             SMALLINT       NULL,
    [DBTableSchema]              [sysname]      NOT NULL,
    [DBTableName]                [sysname]      NOT NULL,
    [DBTableColumnName]          [sysname]      NOT NULL,
    [DWHTableName]               [sysname]      NOT NULL,
    [DWHTableColumnData]         [sysname]      NOT NULL,
    [JoinOrder]                  SMALLINT       NULL,
    [JoinColumn]                 [sysname]      NOT NULL,
    [JoinAlias]                  NVARCHAR (100) NULL,
    [DWHType]                    NVARCHAR (20)  NULL,
    [DWHName]                    [sysname]      NOT NULL,
    [KnotMnemonic]               NVARCHAR (100) NULL,
    [AnchorMnemonic]             NVARCHAR (100) NULL,
    [AttributeMnemonic]          NVARCHAR (100) NULL,
    [TieMnemonic]                NVARCHAR (100) NULL,
    [KnotRange]                  NVARCHAR (100) NULL,
    [PKColumn]                   BIT            NULL,
    [DateRestrictionColumn]      [sysname]      NOT NULL,
    [IsTextColumn]               BIT            NULL,
    [IsMaterialisedColumn]       BIT            NULL,
    [MaterialisedColumnFunction] [sysname]      NOT NULL,
    [CreateNCIndexInDWH]         BIT            NULL,
    [IsHistorised]               BIT            NULL,
    [GenerateID]                 BIT            NULL,
    [DBTableColumnID]            BIGINT         NULL,
    CONSTRAINT [PK_AnchorToMetadataMap] PRIMARY KEY CLUSTERED ([ATMM_ID] ASC) ON [MeDriAnchor_Current]
);








GO
CREATE NONCLUSTERED INDEX [IDX_Meta_Environ_Type_Name]
    ON [MeDriAnchor].[_AnchorToMetadataMap]([Metadata_ID] ASC, [Environment_ID] ASC, [DWHType] ASC, [DWHName] ASC)
    ON [MeDriAnchor_Current];


GO
CREATE TRIGGER [MeDriAnchor].[atr_AnchorToMetadataMap_Update]ON [MeDriAnchor].[_AnchorToMetadataMap] WITH EXECUTE AS 'MeDriAnchorUser'FOR UPDATEAS/**revisions: - author: MeDriAnchor	date: 05 Jan 2015revisions: - author: MeDriAnchor	date: 05 Jan 2015summary:	>				Records the update of an [MeDriAnchor].[_AnchorToMetadataMap] table record - code:	Cannot be called from client code	parameters: n/areturns: on success nothing, otherwise throws an error**/BEGIN TRY	INSERT INTO [MeDriAnchor].[_AnchorToMetadataMap_Shadow]	([ShadowType],[ATMM_ID],[Metadata_ID],[Environment_ID],[DBTableSchema],[DBTableName],[DBTableColumnName],[DWHTableName],[DWHTableColumnData],[JoinOrder],[JoinColumn],[JoinAlias],[DWHType],[DWHName],[KnotMnemonic],[AnchorMnemonic],[AttributeMnemonic],[TieMnemonic],[KnotRange],[PKColumn],[DateRestrictionColumn],[IsTextColumn],[IsMaterialisedColumn],[MaterialisedColumnFunction],[CreateNCIndexInDWH],[IsHistorised],[GenerateID],[DBTableColumnID])	SELECT 'U',[DELETED].[ATMM_ID],[DELETED].[Metadata_ID],[DELETED].[Environment_ID],[DELETED].[DBTableSchema],[DELETED].[DBTableName],[DELETED].[DBTableColumnName],[DELETED].[DWHTableName],[DELETED].[DWHTableColumnData],[DELETED].[JoinOrder],[DELETED].[JoinColumn],[DELETED].[JoinAlias],[DELETED].[DWHType],[DELETED].[DWHName],[DELETED].[KnotMnemonic],[DELETED].[AnchorMnemonic],[DELETED].[AttributeMnemonic],[DELETED].[TieMnemonic],[DELETED].[KnotRange],[DELETED].[PKColumn],[DELETED].[DateRestrictionColumn],[DELETED].[IsTextColumn],[DELETED].[IsMaterialisedColumn],[DELETED].[MaterialisedColumnFunction],[DELETED].[CreateNCIndexInDWH],[DELETED].[IsHistorised],[DELETED].[GenerateID],[DELETED].[DBTableColumnID]	FROM DELETED;END TRYBEGIN CATCH	DECLARE @ErrorMessage NVARCHAR(4000);	DECLARE @ErrorSeverity INT;	DECLARE @ErrorState INT;	SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();	RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);END CATCH;
GO
CREATE TRIGGER [MeDriAnchor].[atr_AnchorToMetadataMap_Insert]ON [MeDriAnchor].[_AnchorToMetadataMap] WITH EXECUTE AS 'MeDriAnchorUser'FOR INSERTAS/**revisions: - author: MeDriAnchor	date: 05 Jan 2015summary:	>				Records the insert of an [MeDriAnchor].[_AnchorToMetadataMap] table record - code:	Cannot be called from client code	parameters: n/areturns: on success nothing, otherwise throws an error**/BEGIN TRY	INSERT INTO [MeDriAnchor].[_AnchorToMetadataMap_Shadow]	([ShadowType],[ATMM_ID],[Metadata_ID],[Environment_ID],[DBTableSchema],[DBTableName],[DBTableColumnName],[DWHTableName],[DWHTableColumnData],[JoinOrder],[JoinColumn],[JoinAlias],[DWHType],[DWHName],[KnotMnemonic],[AnchorMnemonic],[AttributeMnemonic],[TieMnemonic],[KnotRange],[PKColumn],[DateRestrictionColumn],[IsTextColumn],[IsMaterialisedColumn],[MaterialisedColumnFunction],[CreateNCIndexInDWH],[IsHistorised],[GenerateID],[DBTableColumnID])	SELECT 'I',[INSERTED].[ATMM_ID],[INSERTED].[Metadata_ID],[INSERTED].[Environment_ID],[INSERTED].[DBTableSchema],[INSERTED].[DBTableName],[INSERTED].[DBTableColumnName],[INSERTED].[DWHTableName],[INSERTED].[DWHTableColumnData],[INSERTED].[JoinOrder],[INSERTED].[JoinColumn],[INSERTED].[JoinAlias],[INSERTED].[DWHType],[INSERTED].[DWHName],[INSERTED].[KnotMnemonic],[INSERTED].[AnchorMnemonic],[INSERTED].[AttributeMnemonic],[INSERTED].[TieMnemonic],[INSERTED].[KnotRange],[INSERTED].[PKColumn],[INSERTED].[DateRestrictionColumn],[INSERTED].[IsTextColumn],[INSERTED].[IsMaterialisedColumn],[INSERTED].[MaterialisedColumnFunction],[INSERTED].[CreateNCIndexInDWH],[INSERTED].[IsHistorised],[INSERTED].[GenerateID],[INSERTED].[DBTableColumnID]	FROM INSERTED;END TRYBEGIN CATCH	DECLARE @ErrorMessage NVARCHAR(4000);	DECLARE @ErrorSeverity INT;	DECLARE @ErrorState INT;	SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();	RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);END CATCH;
GO
CREATE TRIGGER [MeDriAnchor].[atr_AnchorToMetadataMap_Delete]ON [MeDriAnchor].[_AnchorToMetadataMap] WITH EXECUTE AS 'MeDriAnchorUser'FOR DELETEAS/**revisions: - author: MeDriAnchor	date: 05 Jan 2015summary:	>				Records the delete of an [MeDriAnchor].[_AnchorToMetadataMap] table record - code:	Cannot be called from client code	parameters: n/areturns: on success nothing, otherwise throws an error**/BEGIN TRY	INSERT INTO [MeDriAnchor].[_AnchorToMetadataMap_Shadow]	([ShadowType],[ATMM_ID],[Metadata_ID],[Environment_ID],[DBTableSchema],[DBTableName],[DBTableColumnName],[DWHTableName],[DWHTableColumnData],[JoinOrder],[JoinColumn],[JoinAlias],[DWHType],[DWHName],[KnotMnemonic],[AnchorMnemonic],[AttributeMnemonic],[TieMnemonic],[KnotRange],[PKColumn],[DateRestrictionColumn],[IsTextColumn],[IsMaterialisedColumn],[MaterialisedColumnFunction],[CreateNCIndexInDWH],[IsHistorised],[GenerateID],[DBTableColumnID])	SELECT 'D',[DELETED].[ATMM_ID],[DELETED].[Metadata_ID],[DELETED].[Environment_ID],[DELETED].[DBTableSchema],[DELETED].[DBTableName],[DELETED].[DBTableColumnName],[DELETED].[DWHTableName],[DELETED].[DWHTableColumnData],[DELETED].[JoinOrder],[DELETED].[JoinColumn],[DELETED].[JoinAlias],[DELETED].[DWHType],[DELETED].[DWHName],[DELETED].[KnotMnemonic],[DELETED].[AnchorMnemonic],[DELETED].[AttributeMnemonic],[DELETED].[TieMnemonic],[DELETED].[KnotRange],[DELETED].[PKColumn],[DELETED].[DateRestrictionColumn],[DELETED].[IsTextColumn],[DELETED].[IsMaterialisedColumn],[DELETED].[MaterialisedColumnFunction],[DELETED].[CreateNCIndexInDWH],[DELETED].[IsHistorised],[DELETED].[GenerateID],[DELETED].[DBTableColumnID]	FROM DELETED;END TRYBEGIN CATCH	DECLARE @ErrorMessage NVARCHAR(4000);	DECLARE @ErrorSeverity INT;	DECLARE @ErrorState INT;	SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();	RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);END CATCH;