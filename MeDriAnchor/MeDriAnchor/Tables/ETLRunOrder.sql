
CREATE TABLE [MeDriAnchor].[ETLRunOrder] (
    [ETLRunOrder_ID] BIGINT    IDENTITY (1, 1) NOT NULL,
    [ETLRun_ID]      BIGINT    NOT NULL,
    [SPOrder]        INT       NOT NULL,
    [SPName]         [sysname] NOT NULL,
    CONSTRAINT [PK_ETLRunOrder] PRIMARY KEY CLUSTERED ([ETLRunOrder_ID] ASC) ON [MeDriAnchor_Current],
    CONSTRAINT [FK_ETLRunOrder_ETLRun] FOREIGN KEY ([ETLRun_ID]) REFERENCES [MeDriAnchor].[ETLRun] ([ETLRun_ID])
);






GO
