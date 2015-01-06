
CREATE TABLE [MeDriAnchor].[DBTableTie_Shadow] (
    [ShadowID]       BIGINT         IDENTITY (1, 1) NOT NULL,
    [ShadowType]     CHAR (1)       CONSTRAINT [DF_DBTableTie_Shadow_DeletionType] DEFAULT ('D') NOT NULL,
    [TieID]          INT            NOT NULL,
    [TieMnemonic]    NVARCHAR (20)  NOT NULL,
    [GenerateID]     BIT            NOT NULL,
    [IsHistorised]   BIT            NOT NULL,
    [KnotMnemonic]   NVARCHAR (20)  NOT NULL,
    [KnotRoleName]   NVARCHAR (50)  NOT NULL,
    [Metadata_ID]    BIGINT         NULL,
    [EditingSQLUser] NVARCHAR (128) CONSTRAINT [DF_DBTableTie_Shadow_EditingSQLUser] DEFAULT (original_login()) NULL,
    [EditingDate]    DATETIME       CONSTRAINT [DF_DBTableTie_Shadow_EditingDate] DEFAULT (getdate()) NULL,
    [Environment_ID] SMALLINT       NOT NULL,
    CONSTRAINT [PK_DBTableTie_Shadow] PRIMARY KEY CLUSTERED ([TieID] ASC, [ShadowID] ASC)
);






GO
CREATE NONCLUSTERED INDEX [IDX_MetadataID]
    ON [MeDriAnchor].[DBTableTie_Shadow]([Metadata_ID] ASC);

