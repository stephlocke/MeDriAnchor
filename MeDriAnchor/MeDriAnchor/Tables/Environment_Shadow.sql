
CREATE TABLE [MeDriAnchor].[Environment_Shadow] (
    [ShadowID]        BIGINT         IDENTITY (1, 1) NOT NULL,
    [ShadowType]      CHAR (1)       CONSTRAINT [DF_Environment_Shadow_DeletionType] DEFAULT ('D') NOT NULL,
    [Environment_ID]  SMALLINT       NOT NULL,
    [EnvironmentName] NVARCHAR (100) NOT NULL,
    [EditingSQLUser]  NVARCHAR (128) CONSTRAINT [DF_Environment_Shadow_EditingSQLUser] DEFAULT (original_login()) NULL,
    [EditingDate]     DATETIME       CONSTRAINT [DF_Environment_Shadow_EditingDate] DEFAULT (getdate()) NULL,
    CONSTRAINT [PK_Environment_Shadow] PRIMARY KEY CLUSTERED ([Environment_ID] ASC, [ShadowID] ASC) ON [MeDriAnchor_Current]
);



