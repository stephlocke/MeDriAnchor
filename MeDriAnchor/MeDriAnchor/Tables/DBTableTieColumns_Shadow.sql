
CREATE TABLE [MeDriAnchor].[DBTableTieColumns_Shadow] (
    [ShadowID]            BIGINT         IDENTITY (1, 1) NOT NULL,
    [ShadowType]          CHAR (1)       CONSTRAINT [DF_DBTableTieColumns_Shadow_DeletionType] DEFAULT ('D') NOT NULL,
    [DBTableTieColumnsID] INT            NOT NULL,
    [TieID]               INT            NOT NULL,
    [DBTableColumnID]     BIGINT         NOT NULL,
    [AnchorMnemonicRef]   NVARCHAR (3)   NOT NULL,
    [RoleName]            NVARCHAR (50)  NOT NULL,
    [TieJoinOrder]        SMALLINT       NOT NULL,
    [TieJoinColumn]       NVARCHAR (128) NOT NULL,
    [Metadata_ID]         BIGINT         NULL,
    [EditingSQLUser]      NVARCHAR (128) CONSTRAINT [DF_DBTableTieColumns_Shadow_EditingSQLUser] DEFAULT (original_login()) NULL,
    [EditingDate]         DATETIME       CONSTRAINT [DF_DBTableTieColumns_Shadow_EditingDate] DEFAULT (getdate()) NULL,
    [IsIdentity]          BIT            NOT NULL,
    CONSTRAINT [PK_DBTableTieColumns_Shadow] PRIMARY KEY CLUSTERED ([DBTableTieColumnsID] ASC, [ShadowID] ASC)
);




GO
CREATE NONCLUSTERED INDEX [IDX_MetadataID]
    ON [MeDriAnchor].[DBTableTieColumns_Shadow]([Metadata_ID] ASC);

