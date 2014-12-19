
CREATE TABLE [MeDriAnchor].[_AnchorToMetadataMap_Shadow] (
    [ShadowID]                   BIGINT         IDENTITY (1, 1) NOT NULL,
    [ShadowType]                 CHAR (1)       CONSTRAINT [DF__AnchorToMetadataMap_Shadow_DeletionType] DEFAULT ('D') NOT NULL,
    [ATMM_ID]                    BIGINT         NOT NULL,
    [Metadata_ID]                BIGINT         NULL,
    [Environment_ID]             SMALLINT       NULL,
    [DBTableSchema]              NVARCHAR (128) NOT NULL,
    [DBTableName]                NVARCHAR (128) NOT NULL,
    [DBTableColumnName]          NVARCHAR (128) NOT NULL,
    [DWHTableName]               NVARCHAR (128) NOT NULL,
    [DWHTableColumnData]         NVARCHAR (128) NOT NULL,
    [JoinOrder]                  SMALLINT       NULL,
    [JoinColumn]                 NVARCHAR (128) NOT NULL,
    [JoinAlias]                  NVARCHAR (100) NULL,
    [DWHType]                    NVARCHAR (20)  NULL,
    [DWHName]                    NVARCHAR (128) NOT NULL,
    [KnotMnemonic]               NVARCHAR (100) NULL,
    [AnchorMnemonic]             NVARCHAR (100) NULL,
    [AttributeMnemonic]          NVARCHAR (100) NULL,
    [TieMnemonic]                NVARCHAR (100) NULL,
    [KnotRange]                  NVARCHAR (100) NULL,
    [PKColumn]                   BIT            NULL,
    [DateRestrictionColumn]      NVARCHAR (128) NOT NULL,
    [IsTextColumn]               BIT            NULL,
    [IsMaterialisedColumn]       BIT            NULL,
    [MaterialisedColumnFunction] NVARCHAR (128) NOT NULL,
    [CreateNCIndexInDWH]         BIT            NULL,
    [IsHistorised]               BIT            NULL,
    [GenerateID]                 BIT            NULL,
    [EditingSQLUser]             NVARCHAR (128) CONSTRAINT [DF__AnchorToMetadataMap_Shadow_EditingSQLUser] DEFAULT (original_login()) NULL,
    [EditingDate]                DATETIME       CONSTRAINT [DF__AnchorToMetadataMap_Shadow_EditingDate] DEFAULT (getdate()) NULL,
    [DBTableColumnID] BIGINT NULL, 
    CONSTRAINT [PK_AnchorToMetadataMap_Shadow] PRIMARY KEY CLUSTERED ([ATMM_ID] ASC, [ShadowID] ASC) ON [MeDriAnchor_Current]
);




GO
CREATE NONCLUSTERED INDEX [IDX_MetadataID]
    ON [MeDriAnchor].[_AnchorToMetadataMap_Shadow]([Metadata_ID] ASC)
    ON [MeDriAnchor_Current];

