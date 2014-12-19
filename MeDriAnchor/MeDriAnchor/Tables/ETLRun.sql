
CREATE TABLE [MeDriAnchor].[ETLRun] (
    [ETLRun_ID]      BIGINT   IDENTITY (1, 1) NOT NULL,
    [Batch_ID]       BIGINT   NOT NULL,
    [Metadata_ID]    BIGINT   NOT NULL,
    [Environment_ID] SMALLINT NOT NULL,
    [ETLRun_ID_Used] BIGINT   NULL,
    CONSTRAINT [PK_ETLRun] PRIMARY KEY CLUSTERED ([ETLRun_ID] ASC) ON [MeDriAnchor_Current],
    CONSTRAINT [FK_ETLRun_Batch] FOREIGN KEY ([Batch_ID]) REFERENCES [MeDriAnchor].[Batch] ([Batch_ID]),
    CONSTRAINT [FK_ETLRun_Environment] FOREIGN KEY ([Environment_ID]) REFERENCES [MeDriAnchor].[Environment] ([Environment_ID]),
    CONSTRAINT [FK_ETLRun_ETLRun] FOREIGN KEY ([ETLRun_ID_Used]) REFERENCES [MeDriAnchor].[ETLRun] ([ETLRun_ID]),
    CONSTRAINT [FK_ETLRun_MEtadata] FOREIGN KEY ([Metadata_ID]) REFERENCES [MeDriAnchor].[Metadata] ([Metadata_ID])
);






GO