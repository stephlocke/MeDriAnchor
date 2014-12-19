
CREATE TABLE [MeDriAnchor].[DBTableTie] (
    [TieID]        INT           IDENTITY (1, 1) NOT NULL,
    [TieMnemonic]  NVARCHAR (20) CONSTRAINT [DF_DBTableTie_TieMnemonic] DEFAULT ('') NOT NULL,
    [GenerateID]   BIT           CONSTRAINT [DF_DBTableTie_GenerateID] DEFAULT ((0)) NOT NULL,
    [IsHistorised] BIT           CONSTRAINT [DF_DBTableTie_IsHistorised] DEFAULT ((1)) NOT NULL,
    [KnotMnemonic] NVARCHAR (20) CONSTRAINT [DF_DBTableTie_KnotMnemonic] DEFAULT ('') NOT NULL,
    [KnotRoleName] NVARCHAR (50) CONSTRAINT [DF_DBTableTie_KnotRoleName] DEFAULT ('') NOT NULL,
    [Metadata_ID]  BIGINT        NULL,
    CONSTRAINT [PK_DBTableTie] PRIMARY KEY CLUSTERED ([TieID] ASC),
    CONSTRAINT [FK_DBTableTie_Metadata] FOREIGN KEY ([Metadata_ID]) REFERENCES [MeDriAnchor].[Metadata] ([Metadata_ID])
);





GO
CREATE TRIGGER [MeDriAnchor].[atrDBTableTie_Update]
GO
CREATE TRIGGER [MeDriAnchor].[atrDBTableTie_Insert]
GO
CREATE TRIGGER [MeDriAnchor].[atrDBTableTie_Delete]