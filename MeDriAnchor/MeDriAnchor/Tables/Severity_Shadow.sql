
CREATE TABLE [MeDriAnchor].[Severity_Shadow] (
    [ShadowID]       BIGINT         IDENTITY (1, 1) NOT NULL,
    [ShadowType]     CHAR (1)       CONSTRAINT [DF_Severity_Shadow_DeletionType] DEFAULT ('D') NOT NULL,
    [SeverityID]     TINYINT        NOT NULL,
    [ServerityName]  VARCHAR (20)   NOT NULL,
    [EditingSQLUser] NVARCHAR (128) CONSTRAINT [DF_Severity_Shadow_EditingSQLUser] DEFAULT (original_login()) NULL,
    [EditingDate]    DATETIME       CONSTRAINT [DF_Severity_Shadow_EditingDate] DEFAULT (getdate()) NULL,
    CONSTRAINT [PK_Severity_Shadow] PRIMARY KEY CLUSTERED ([SeverityID] ASC, [ShadowID] ASC) ON [MeDriAnchor_Current]
);



