
CREATE TABLE [MeDriAnchor].[DBTable_Shadow] (
    [ShadowID]            BIGINT         IDENTITY (1, 1) NOT NULL,
    [ShadowType]          CHAR (1)       CONSTRAINT [DF_DBTable_Shadow_DeletionType] DEFAULT ('D') NOT NULL,
    [DBTableID]           BIGINT         NOT NULL,
    [DBID]                BIGINT         NOT NULL,
    [DBTableSchema]       NVARCHAR (128) NOT NULL,
    [DBTableName]         NVARCHAR (128) NOT NULL,
    [DBTableType]         NVARCHAR (20)  NOT NULL,
    [DBTableOrder]        INT            NOT NULL,
    [DBTableAlias]        NVARCHAR (128) NULL,
    [DBTableDescription]  NVARCHAR (500) NULL,
    [IsActive]            BIT            NOT NULL,
    [MinutesBetweenLoads] INT            NOT NULL,
    [Metadata_ID]         BIGINT         NULL,
    [EditingSQLUser]      NVARCHAR (128) CONSTRAINT [DF_DBTable_Shadow_EditingSQLUser] DEFAULT (original_login()) NULL,
    [EditingDate]         DATETIME       CONSTRAINT [DF_DBTable_Shadow_EditingDate] DEFAULT (getdate()) NULL,
    CONSTRAINT [PK_DBTable_Shadow] PRIMARY KEY CLUSTERED ([DBTableID] ASC, [ShadowID] ASC) ON [MeDriAnchor_Current]
);




GO
CREATE NONCLUSTERED INDEX [IDX_MetadataID]
    ON [MeDriAnchor].[DBTable_Shadow]([Metadata_ID] ASC)
    ON [MeDriAnchor_Current];

