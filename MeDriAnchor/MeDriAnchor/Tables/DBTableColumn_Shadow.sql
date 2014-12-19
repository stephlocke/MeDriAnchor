
CREATE TABLE [MeDriAnchor].[DBTableColumn_Shadow] (
    [ShadowID]                   BIGINT         IDENTITY (1, 1) NOT NULL,
    [ShadowType]                 CHAR (1)       CONSTRAINT [DF_DBTableColumn_Shadow_DeletionType] DEFAULT ('D') NOT NULL,
    [DBTableColumnID]            BIGINT         NOT NULL,
    [DBTableID]                  BIGINT         NOT NULL,
    [DBTableColumnName]          NVARCHAR (128) NOT NULL,
    [Environment_ID]             SMALLINT       NOT NULL,
    [DBTableColumnAlias]         NVARCHAR (128) NULL,
    [DBTableColumnDescription]   NVARCHAR (500) NULL,
    [IsDatetimeComparison]       BIT            NOT NULL,
    [IsAnchor]                   BIT            NOT NULL,
    [AnchorMnemonic]             NVARCHAR (3)   NOT NULL,
    [AnchorMnemonicRef]          NVARCHAR (3)   NOT NULL,
    [IsAttribute]                BIT            NOT NULL,
    [AttributeMnemonic]          NVARCHAR (7)   NOT NULL,
    [IsHistorised]               BIT            NOT NULL,
    [HistorisedTimeRange]        NVARCHAR (128) NOT NULL,
    [IsKnot]                     BIT            NOT NULL,
    [KnotMnemonic]               NVARCHAR (7)   NOT NULL,
    [KnotJoinColumn]             NVARCHAR (128) NOT NULL,
    [AttributeMnemonicRef]       NVARCHAR (7)   NOT NULL,
    [GenerateID]                 BIT            NOT NULL,
    [IsReportable]               BIT            NOT NULL,
    [RoleName]                   NVARCHAR (30)  NOT NULL,
    [RoleNameRef]                NVARCHAR (30)  NOT NULL,
    [CreateNCIndexInDWH]         BIT            NOT NULL,
    [PKColumn]                   BIT            NOT NULL,
    [PKName]                     NVARCHAR (128) NOT NULL,
    [PKClustered]                INT            NOT NULL,
    [PKColOrdinal]               TINYINT        NOT NULL,
    [PKDescOrder]                BIT            NOT NULL,
    [IdentityColumn]             BIT            NOT NULL,
    [ColPosition]                INT            NOT NULL,
    [DataType]                   NVARCHAR (553) NULL,
    [NumericPrecision]           TINYINT        NOT NULL,
    [NumericScale]               TINYINT        NOT NULL,
    [CharMaxLength]              INT            NULL,
    [IsNullable]                 BIT            NULL,
    [IsComputedCol]              BIT            NOT NULL,
    [IsMaterialisedColumn]       BIT            NOT NULL,
    [MaterialisedColumnFunction] NVARCHAR (128) NOT NULL,
    [TestColumnFunction]         NVARCHAR (128) NOT NULL,
    [IsActive]                   BIT            NOT NULL,
    [Metadata_ID]                BIGINT         NULL,
	[SwapIfGUID]				 BIT			NULL,
    [EditingSQLUser]             NVARCHAR (128) CONSTRAINT [DF_DBTableColumn_Shadow_EditingSQLUser] DEFAULT (original_login()) NULL,
    [EditingDate]                DATETIME       CONSTRAINT [DF_DBTableColumn_Shadow_EditingDate] DEFAULT (getdate()) NULL,
	[TestValue1] SQL_VARIANT NULL,
	[TestValue2] SQL_VARIANT NULL,
	[TestLkpDBTableColumnID] BIGINT NULL,
    CONSTRAINT [PK_DBTableColumn_Shadow] PRIMARY KEY CLUSTERED ([DBTableColumnID] ASC, [ShadowID] ASC) ON [MeDriAnchor_Current]
);




GO
CREATE NONCLUSTERED INDEX [IDX_MetadataID]
    ON [MeDriAnchor].[DBTableColumn_Shadow]([Metadata_ID] ASC)
    ON [MeDriAnchor_Current];

