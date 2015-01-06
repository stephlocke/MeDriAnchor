
CREATE TABLE [MeDriAnchor].[DBTableColumn] (
    [DBTableColumnID]            BIGINT         IDENTITY (1, 1) NOT NULL,
    [DBTableID]                  BIGINT         NOT NULL,
    [DBTableColumnName]          [sysname]      NOT NULL,
    [Environment_ID]             SMALLINT       NOT NULL,
    [DBTableColumnAlias]         [sysname]      NULL,
    [DBTableColumnDescription]   NVARCHAR (500) NULL,
    [IsDatetimeComparison]       BIT            CONSTRAINT [DF_DBTableColumn_IsDatetimeComparison] DEFAULT ((0)) NOT NULL,
    [IsAnchor]                   BIT            CONSTRAINT [DF_DBTableColumn_IsAnchor] DEFAULT ((0)) NOT NULL,
    [AnchorMnemonic]             NVARCHAR (3)   CONSTRAINT [DF_DBTableColumn_Mnemonic] DEFAULT ('') NOT NULL,
    [AnchorMnemonicRef]          NVARCHAR (3)   CONSTRAINT [DF_DBTableColumn_AnchorMnemonicRef] DEFAULT ('') NOT NULL,
    [IsAttribute]                BIT            CONSTRAINT [DF_DBTableColumn_IsAttribute] DEFAULT ((0)) NOT NULL,
    [AttributeMnemonic]          NVARCHAR (7)   CONSTRAINT [DF_DBTableColumn_AttributeMnemonic] DEFAULT ('') NOT NULL,
    [IsHistorised]               BIT            CONSTRAINT [DF_DBTableColumn_IsHistorised] DEFAULT ((1)) NOT NULL,
    [HistorisedTimeRange]        [sysname]      CONSTRAINT [DF_DBTableColumn_HistorisedTimeRange] DEFAULT ('datetime') NOT NULL,
    [IsKnot]                     BIT            CONSTRAINT [DF_DBTableColumn_Isknot] DEFAULT ((0)) NOT NULL,
    [KnotMnemonic]               NVARCHAR (7)   CONSTRAINT [DF_DBTableColumn_KnotMnemonic] DEFAULT ('') NOT NULL,
    [KnotJoinColumn]             [sysname]      CONSTRAINT [DF_DBTableColumn_KnotJoinColumn] DEFAULT ('') NOT NULL,
    [AttributeMnemonicRef]       NVARCHAR (7)   CONSTRAINT [DF_DBTableColumn_AttributeMnemonicRef] DEFAULT ('') NOT NULL,
    [GenerateID]                 BIT            CONSTRAINT [DF_DBTableColumn_GenerateID] DEFAULT ((0)) NOT NULL,
    [IsReportable]               BIT            CONSTRAINT [DF_DBTableColumn_IsReportable] DEFAULT ((0)) NOT NULL,
    [RoleName]                   NVARCHAR (30)  CONSTRAINT [DF_DBTableColumn_RoleName] DEFAULT ('') NOT NULL,
    [RoleNameRef]                NVARCHAR (30)  CONSTRAINT [DF_DBTableColumn_RoleNameRef] DEFAULT ('') NOT NULL,
    [CreateNCIndexInDWH]         BIT            CONSTRAINT [DF_DBTableColumn_CreateNCIndexInDWH] DEFAULT ((0)) NOT NULL,
    [PKColumn]                   BIT            NOT NULL,
    [PKName]                     [sysname]      NOT NULL,
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
    [IsMaterialisedColumn]       BIT            CONSTRAINT [DF_DBTableColumn_IsMaterialisedColumn] DEFAULT ((0)) NOT NULL,
    [MaterialisedColumnFunction] [sysname]      CONSTRAINT [DF_DBTableColumn_MaterialisedColumnFunction] DEFAULT ('') NOT NULL,
    [TestColumnFunction]         [sysname]      CONSTRAINT [DF_DBTableColumn_TestColumnFunction] DEFAULT ('') NOT NULL,
    [IsActive]                   BIT            CONSTRAINT [DF_DBTableColumn_IsActive] DEFAULT ((1)) NOT NULL,
    [Metadata_ID]                BIGINT         NULL,
    [SwapIfGUID]                 BIT            CONSTRAINT [DF_DBTableColumn_SwapIfGUID] DEFAULT ((0)) NOT NULL,
    [TestValue1]                 SQL_VARIANT    NULL,
    [TestValue2]                 SQL_VARIANT    NULL,
    [TestLkpDBTableColumnID]     BIGINT         NULL,
    CONSTRAINT [PK_DBTableColumn] PRIMARY KEY CLUSTERED ([DBTableColumnID] ASC) ON [MeDriAnchor_Current],
    CONSTRAINT [FK_DBTableColumn_DBTable] FOREIGN KEY ([DBTableID]) REFERENCES [MeDriAnchor].[DBTable] ([DBTableID]),
    CONSTRAINT [FK_DBTableColumn_Environment] FOREIGN KEY ([Environment_ID]) REFERENCES [MeDriAnchor].[Environment] ([Environment_ID]),
    CONSTRAINT [FK_DBTableColumn_Metadata] FOREIGN KEY ([Metadata_ID]) REFERENCES [MeDriAnchor].[Metadata] ([Metadata_ID])
);








GO
CREATE TRIGGER [MeDriAnchor].[atrDBTableColumn_Update]ON [MeDriAnchor].[DBTableColumn] WITH EXECUTE AS 'MeDriAnchorUser'FOR UPDATEAS/**revisions: - author: MeDriAnchor	date: 05 Jan 2015revisions: - author: MeDriAnchor	date: 05 Jan 2015summary:	>				Records the update of an [MeDriAnchor].[DBTableColumn] table record - code:	Cannot be called from client code	parameters: n/areturns: on success nothing, otherwise throws an error**/BEGIN TRY	INSERT INTO [MeDriAnchor].[DBTableColumn_Shadow]	([ShadowType],[DBTableColumnID],[DBTableID],[DBTableColumnName],[Environment_ID],[DBTableColumnAlias],[DBTableColumnDescription],[IsDatetimeComparison],[IsAnchor],[AnchorMnemonic],[AnchorMnemonicRef],[IsAttribute],[AttributeMnemonic],[IsHistorised],[HistorisedTimeRange],[IsKnot],[KnotMnemonic],[KnotJoinColumn],[AttributeMnemonicRef],[GenerateID],[IsReportable],[RoleName],[RoleNameRef],[CreateNCIndexInDWH],[PKColumn],[PKName],[PKClustered],[PKColOrdinal],[PKDescOrder],[IdentityColumn],[ColPosition],[DataType],[NumericPrecision],[NumericScale],[CharMaxLength],[IsNullable],[IsComputedCol],[IsMaterialisedColumn],[MaterialisedColumnFunction],[TestColumnFunction],[IsActive],[Metadata_ID],[SwapIfGUID],[TestValue1],[TestValue2],[TestLkpDBTableColumnID])	SELECT 'U',[DELETED].[DBTableColumnID],[DELETED].[DBTableID],[DELETED].[DBTableColumnName],[DELETED].[Environment_ID],[DELETED].[DBTableColumnAlias],[DELETED].[DBTableColumnDescription],[DELETED].[IsDatetimeComparison],[DELETED].[IsAnchor],[DELETED].[AnchorMnemonic],[DELETED].[AnchorMnemonicRef],[DELETED].[IsAttribute],[DELETED].[AttributeMnemonic],[DELETED].[IsHistorised],[DELETED].[HistorisedTimeRange],[DELETED].[IsKnot],[DELETED].[KnotMnemonic],[DELETED].[KnotJoinColumn],[DELETED].[AttributeMnemonicRef],[DELETED].[GenerateID],[DELETED].[IsReportable],[DELETED].[RoleName],[DELETED].[RoleNameRef],[DELETED].[CreateNCIndexInDWH],[DELETED].[PKColumn],[DELETED].[PKName],[DELETED].[PKClustered],[DELETED].[PKColOrdinal],[DELETED].[PKDescOrder],[DELETED].[IdentityColumn],[DELETED].[ColPosition],[DELETED].[DataType],[DELETED].[NumericPrecision],[DELETED].[NumericScale],[DELETED].[CharMaxLength],[DELETED].[IsNullable],[DELETED].[IsComputedCol],[DELETED].[IsMaterialisedColumn],[DELETED].[MaterialisedColumnFunction],[DELETED].[TestColumnFunction],[DELETED].[IsActive],[DELETED].[Metadata_ID],[DELETED].[SwapIfGUID],[DELETED].[TestValue1],[DELETED].[TestValue2],[DELETED].[TestLkpDBTableColumnID]	FROM DELETED;END TRYBEGIN CATCH	DECLARE @ErrorMessage NVARCHAR(4000);	DECLARE @ErrorSeverity INT;	DECLARE @ErrorState INT;	SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();	RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);END CATCH;
GO
CREATE TRIGGER [MeDriAnchor].[atrDBTableColumn_Insert]ON [MeDriAnchor].[DBTableColumn] WITH EXECUTE AS 'MeDriAnchorUser'FOR INSERTAS/**revisions: - author: MeDriAnchor	date: 05 Jan 2015summary:	>				Records the insert of an [MeDriAnchor].[DBTableColumn] table record - code:	Cannot be called from client code	parameters: n/areturns: on success nothing, otherwise throws an error**/BEGIN TRY	INSERT INTO [MeDriAnchor].[DBTableColumn_Shadow]	([ShadowType],[DBTableColumnID],[DBTableID],[DBTableColumnName],[Environment_ID],[DBTableColumnAlias],[DBTableColumnDescription],[IsDatetimeComparison],[IsAnchor],[AnchorMnemonic],[AnchorMnemonicRef],[IsAttribute],[AttributeMnemonic],[IsHistorised],[HistorisedTimeRange],[IsKnot],[KnotMnemonic],[KnotJoinColumn],[AttributeMnemonicRef],[GenerateID],[IsReportable],[RoleName],[RoleNameRef],[CreateNCIndexInDWH],[PKColumn],[PKName],[PKClustered],[PKColOrdinal],[PKDescOrder],[IdentityColumn],[ColPosition],[DataType],[NumericPrecision],[NumericScale],[CharMaxLength],[IsNullable],[IsComputedCol],[IsMaterialisedColumn],[MaterialisedColumnFunction],[TestColumnFunction],[IsActive],[Metadata_ID],[SwapIfGUID],[TestValue1],[TestValue2],[TestLkpDBTableColumnID])	SELECT 'I',[INSERTED].[DBTableColumnID],[INSERTED].[DBTableID],[INSERTED].[DBTableColumnName],[INSERTED].[Environment_ID],[INSERTED].[DBTableColumnAlias],[INSERTED].[DBTableColumnDescription],[INSERTED].[IsDatetimeComparison],[INSERTED].[IsAnchor],[INSERTED].[AnchorMnemonic],[INSERTED].[AnchorMnemonicRef],[INSERTED].[IsAttribute],[INSERTED].[AttributeMnemonic],[INSERTED].[IsHistorised],[INSERTED].[HistorisedTimeRange],[INSERTED].[IsKnot],[INSERTED].[KnotMnemonic],[INSERTED].[KnotJoinColumn],[INSERTED].[AttributeMnemonicRef],[INSERTED].[GenerateID],[INSERTED].[IsReportable],[INSERTED].[RoleName],[INSERTED].[RoleNameRef],[INSERTED].[CreateNCIndexInDWH],[INSERTED].[PKColumn],[INSERTED].[PKName],[INSERTED].[PKClustered],[INSERTED].[PKColOrdinal],[INSERTED].[PKDescOrder],[INSERTED].[IdentityColumn],[INSERTED].[ColPosition],[INSERTED].[DataType],[INSERTED].[NumericPrecision],[INSERTED].[NumericScale],[INSERTED].[CharMaxLength],[INSERTED].[IsNullable],[INSERTED].[IsComputedCol],[INSERTED].[IsMaterialisedColumn],[INSERTED].[MaterialisedColumnFunction],[INSERTED].[TestColumnFunction],[INSERTED].[IsActive],[INSERTED].[Metadata_ID],[INSERTED].[SwapIfGUID],[INSERTED].[TestValue1],[INSERTED].[TestValue2],[INSERTED].[TestLkpDBTableColumnID]	FROM INSERTED;END TRYBEGIN CATCH	DECLARE @ErrorMessage NVARCHAR(4000);	DECLARE @ErrorSeverity INT;	DECLARE @ErrorState INT;	SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();	RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);END CATCH;
GO
CREATE TRIGGER [MeDriAnchor].[atrDBTableColumn_Delete]ON [MeDriAnchor].[DBTableColumn] WITH EXECUTE AS 'MeDriAnchorUser'FOR DELETEAS/**revisions: - author: MeDriAnchor	date: 05 Jan 2015summary:	>				Records the delete of an [MeDriAnchor].[DBTableColumn] table record - code:	Cannot be called from client code	parameters: n/areturns: on success nothing, otherwise throws an error**/BEGIN TRY	INSERT INTO [MeDriAnchor].[DBTableColumn_Shadow]	([ShadowType],[DBTableColumnID],[DBTableID],[DBTableColumnName],[Environment_ID],[DBTableColumnAlias],[DBTableColumnDescription],[IsDatetimeComparison],[IsAnchor],[AnchorMnemonic],[AnchorMnemonicRef],[IsAttribute],[AttributeMnemonic],[IsHistorised],[HistorisedTimeRange],[IsKnot],[KnotMnemonic],[KnotJoinColumn],[AttributeMnemonicRef],[GenerateID],[IsReportable],[RoleName],[RoleNameRef],[CreateNCIndexInDWH],[PKColumn],[PKName],[PKClustered],[PKColOrdinal],[PKDescOrder],[IdentityColumn],[ColPosition],[DataType],[NumericPrecision],[NumericScale],[CharMaxLength],[IsNullable],[IsComputedCol],[IsMaterialisedColumn],[MaterialisedColumnFunction],[TestColumnFunction],[IsActive],[Metadata_ID],[SwapIfGUID],[TestValue1],[TestValue2],[TestLkpDBTableColumnID])	SELECT 'D',[DELETED].[DBTableColumnID],[DELETED].[DBTableID],[DELETED].[DBTableColumnName],[DELETED].[Environment_ID],[DELETED].[DBTableColumnAlias],[DELETED].[DBTableColumnDescription],[DELETED].[IsDatetimeComparison],[DELETED].[IsAnchor],[DELETED].[AnchorMnemonic],[DELETED].[AnchorMnemonicRef],[DELETED].[IsAttribute],[DELETED].[AttributeMnemonic],[DELETED].[IsHistorised],[DELETED].[HistorisedTimeRange],[DELETED].[IsKnot],[DELETED].[KnotMnemonic],[DELETED].[KnotJoinColumn],[DELETED].[AttributeMnemonicRef],[DELETED].[GenerateID],[DELETED].[IsReportable],[DELETED].[RoleName],[DELETED].[RoleNameRef],[DELETED].[CreateNCIndexInDWH],[DELETED].[PKColumn],[DELETED].[PKName],[DELETED].[PKClustered],[DELETED].[PKColOrdinal],[DELETED].[PKDescOrder],[DELETED].[IdentityColumn],[DELETED].[ColPosition],[DELETED].[DataType],[DELETED].[NumericPrecision],[DELETED].[NumericScale],[DELETED].[CharMaxLength],[DELETED].[IsNullable],[DELETED].[IsComputedCol],[DELETED].[IsMaterialisedColumn],[DELETED].[MaterialisedColumnFunction],[DELETED].[TestColumnFunction],[DELETED].[IsActive],[DELETED].[Metadata_ID],[DELETED].[SwapIfGUID],[DELETED].[TestValue1],[DELETED].[TestValue2],[DELETED].[TestLkpDBTableColumnID]	FROM DELETED;END TRYBEGIN CATCH	DECLARE @ErrorMessage NVARCHAR(4000);	DECLARE @ErrorSeverity INT;	DECLARE @ErrorState INT;	SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();	RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);END CATCH;