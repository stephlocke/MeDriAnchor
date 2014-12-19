
CREATE TABLE [MeDriAnchor].[SettingsEnvironment_Shadow] (
    [ShadowID]               BIGINT         IDENTITY (1, 1) NOT NULL,
    [ShadowType]             CHAR (1)       CONSTRAINT [DF_SettingsEnvironment_Shadow_DeletionType] DEFAULT ('D') NOT NULL,
    [SettingsEnvironment_ID] SMALLINT       NOT NULL,
    [Environment_ID]         SMALLINT       NOT NULL,
    [Metadata_ID]            BIGINT         NULL,
    [SettingKey]             NVARCHAR (100) NOT NULL,
    [SettingValue]           NVARCHAR (100) NOT NULL,
    [SettingInSchemaMD]      BIT            NOT NULL,
    [EditingSQLUser]         NVARCHAR (128) CONSTRAINT [DF_SettingsEnvironment_Shadow_EditingSQLUser] DEFAULT (original_login()) NULL,
    [EditingDate]            DATETIME       CONSTRAINT [DF_SettingsEnvironment_Shadow_EditingDate] DEFAULT (getdate()) NULL,
    CONSTRAINT [PK_SettingsEnvironment_Shadow] PRIMARY KEY CLUSTERED ([SettingsEnvironment_ID] ASC, [ShadowID] ASC) ON [MeDriAnchor_Current]
);




GO
CREATE NONCLUSTERED INDEX [IDX_MetadataID]
    ON [MeDriAnchor].[SettingsEnvironment_Shadow]([Metadata_ID] ASC)
    ON [MeDriAnchor_Current];

