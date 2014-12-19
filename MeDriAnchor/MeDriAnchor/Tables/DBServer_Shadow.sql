
CREATE TABLE [MeDriAnchor].[DBServer_Shadow] (
    [ShadowID]       BIGINT         IDENTITY (1, 1) NOT NULL,
    [ShadowType]     CHAR (1)       CONSTRAINT [DF_DBServer_Shadow_DeletionType] DEFAULT ('D') NOT NULL,
    [DBServerID]     BIGINT         NOT NULL,
    [DBServerTypeID] SMALLINT       NULL,
    [ServerName]     NVARCHAR (128) NOT NULL,
    [ServerIP]       NVARCHAR (30)  NULL,
    [Metadata_ID]    BIGINT         NULL,
    [EditingSQLUser] NVARCHAR (128) CONSTRAINT [DF_DBServer_Shadow_EditingSQLUser] DEFAULT (original_login()) NULL,
    [EditingDate]    DATETIME       CONSTRAINT [DF_DBServer_Shadow_EditingDate] DEFAULT (getdate()) NULL,
    CONSTRAINT [PK_DBServer_Shadow] PRIMARY KEY CLUSTERED ([DBServerID] ASC, [ShadowID] ASC) ON [MeDriAnchor_Current]
);




GO
CREATE NONCLUSTERED INDEX [IDX_MetadataID]
    ON [MeDriAnchor].[DBServer_Shadow]([Metadata_ID] ASC)
    ON [MeDriAnchor_Current];

