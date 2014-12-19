
CREATE TABLE [MeDriAnchor].[Metadata] (
    [Metadata_ID]  BIGINT   IDENTITY (1, 1) NOT NULL,
    [MetadataDate] DATETIME CONSTRAINT [DF_Metadata_MetadataDate] DEFAULT (getdate()) NOT NULL,
    CONSTRAINT [PK_Metadata] PRIMARY KEY CLUSTERED ([Metadata_ID] ASC) ON [MeDriAnchor_Current]
);






GO

