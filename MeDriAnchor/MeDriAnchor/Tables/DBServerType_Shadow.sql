
CREATE TABLE [MeDriAnchor].[DBServerType_Shadow] (
    [ShadowID]                        BIGINT         IDENTITY (1, 1) NOT NULL,
    [ShadowType]                      CHAR (1)       CONSTRAINT [DF_DBServerType_Shadow_DeletionType] DEFAULT ('D') NOT NULL,
    [DBServerTypeID]                  SMALLINT       NOT NULL,
    [DBServerType]                    NVARCHAR (100) NOT NULL,
    [DBServerConnectionString]        NVARCHAR (500) NULL,
    [DBServerConnectionStringTrusted] NVARCHAR (500) NULL,
    [Metadata_ID]                     BIGINT         NULL,
    [EditingSQLUser]                  NVARCHAR (128) CONSTRAINT [DF_DBServerType_Shadow_EditingSQLUser] DEFAULT (original_login()) NULL,
    [EditingDate]                     DATETIME       CONSTRAINT [DF_DBServerType_Shadow_EditingDate] DEFAULT (getdate()) NULL,
    CONSTRAINT [PK_DBServerType_Shadow] PRIMARY KEY CLUSTERED ([DBServerTypeID] ASC, [ShadowID] ASC) ON [MeDriAnchor_Current]
);






GO
CREATE NONCLUSTERED INDEX [IDX_MetadataID]
    ON [MeDriAnchor].[DBServerType_Shadow]([Metadata_ID] ASC)
    ON [MeDriAnchor_Current];

