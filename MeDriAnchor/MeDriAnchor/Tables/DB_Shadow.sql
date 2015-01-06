
CREATE TABLE [MeDriAnchor].[DB_Shadow] (
    [ShadowID]           BIGINT          IDENTITY (1, 1) NOT NULL,
    [ShadowType]         CHAR (1)        CONSTRAINT [DF_DB_Shadow_DeletionType] DEFAULT ('D') NOT NULL,
    [DBID]               BIGINT          NOT NULL,
    [DBServerID]         BIGINT          NOT NULL,
    [DBName]             NVARCHAR (128)  NOT NULL,
    [DBUserName]         VARBINARY (256) NULL,
    [DBUserPassword]     VARBINARY (256) NULL,
    [DBIsLocal]          BIT             NOT NULL,
    [DBIsSource]         BIT             NOT NULL,
    [DBIsDestination]    BIT             NOT NULL,
    [Metadata_ID]        BIGINT          NULL,
    [Environment_ID]     SMALLINT        NULL,
    [StageData]          BIT             NOT NULL,
    [UseSchemaPromotion] BIT             NOT NULL,
    [EditingSQLUser]     NVARCHAR (128)  CONSTRAINT [DF_DB_Shadow_EditingSQLUser] DEFAULT (original_login()) NULL,
    [EditingDate]        DATETIME        CONSTRAINT [DF_DB_Shadow_EditingDate] DEFAULT (getdate()) NULL,
    CONSTRAINT [PK_DB_Shadow] PRIMARY KEY CLUSTERED ([DBID] ASC, [ShadowID] ASC) ON [MeDriAnchor_Current]
);






GO
CREATE NONCLUSTERED INDEX [IDX_MetadataID]
    ON [MeDriAnchor].[DB_Shadow]([Metadata_ID] ASC)
    ON [MeDriAnchor_Current];

