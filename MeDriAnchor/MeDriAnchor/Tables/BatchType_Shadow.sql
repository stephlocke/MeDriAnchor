
CREATE TABLE [MeDriAnchor].[BatchType_Shadow] (
    [ShadowID]       BIGINT         IDENTITY (1, 1) NOT NULL,
    [ShadowType]     CHAR (1)       CONSTRAINT [DF_BatchType_Shadow_DeletionType] DEFAULT ('D') NOT NULL,
    [BatchTypeID]    SMALLINT       NOT NULL,
    [BatchType]      NVARCHAR (20)  NOT NULL,
    [EditingSQLUser] NVARCHAR (128) CONSTRAINT [DF_BatchType_Shadow_EditingSQLUser] DEFAULT (original_login()) NULL,
    [EditingDate]    DATETIME       CONSTRAINT [DF_BatchType_Shadow_EditingDate] DEFAULT (getdate()) NULL,
    CONSTRAINT [PK_BatchType_Shadow] PRIMARY KEY CLUSTERED ([BatchTypeID] ASC, [ShadowID] ASC) ON [MeDriAnchor_Current]
);



