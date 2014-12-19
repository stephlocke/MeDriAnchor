
CREATE TABLE [MeDriAnchor].[Batch] (
    [Batch_ID]         BIGINT        IDENTITY (1, 1) NOT NULL,
    [BatchTypeID]      SMALLINT      NOT NULL,
    [BatchDescription] VARCHAR (200) NOT NULL,
    [BatchDate]        DATETIME      NOT NULL,
    [BatchSuccessful] BIT CONSTRAINT [DF_Batch_BatchSuccessful] DEFAULT(0) NOT NULL, 
    [InProgress] BIT CONSTRAINT [DF_Batch_InProgress] DEFAULT(1) NOT NULL, 
    CONSTRAINT [PK_Batch] PRIMARY KEY CLUSTERED ([Batch_ID] ASC) ON [MeDriAnchor_Current],
    CONSTRAINT [FK_Batch_BatchType] FOREIGN KEY ([BatchTypeID]) REFERENCES [MeDriAnchor].[BatchType] ([BatchTypeID])
);




GO