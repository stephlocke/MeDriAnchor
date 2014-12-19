
CREATE TABLE [MeDriAnchor].[SeverityEmailRecipients_Shadow] (
    [ShadowID]         BIGINT          IDENTITY (1, 1) NOT NULL,
    [ShadowType]       CHAR (1)        CONSTRAINT [DF_SeverityEmailRecipients_Shadow_DeletionType] DEFAULT ('D') NOT NULL,
    [SeverityID]       TINYINT         NOT NULL,
    [DistributionList] NVARCHAR (2000) NOT NULL,
    [EditingSQLUser]   NVARCHAR (128)  CONSTRAINT [DF_SeverityEmailRecipients_Shadow_EditingSQLUser] DEFAULT (original_login()) NULL,
    [EditingDate]      DATETIME        CONSTRAINT [DF_SeverityEmailRecipients_Shadow_EditingDate] DEFAULT (getdate()) NULL,
    CONSTRAINT [PK_SeverityEmailRecipients_Shadow] PRIMARY KEY CLUSTERED ([SeverityID] ASC, [ShadowID] ASC) ON [MeDriAnchor_Current]
);



