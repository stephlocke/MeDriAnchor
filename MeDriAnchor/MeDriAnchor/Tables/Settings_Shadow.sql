
CREATE TABLE [MeDriAnchor].[Settings_Shadow] (
    [ShadowID]          BIGINT         IDENTITY (1, 1) NOT NULL,
    [ShadowType]        CHAR (1)       CONSTRAINT [DF_Settings_Shadow_DeletionType] DEFAULT ('D') NOT NULL,
    [SettingID]         SMALLINT       NOT NULL,
    [SettingKey]        NVARCHAR (100) NOT NULL,
    [SettingValue]      NVARCHAR (100) NOT NULL,
    [SettingInSchemaMD] BIT            NOT NULL,
    [EditingSQLUser]    NVARCHAR (128) CONSTRAINT [DF_Settings_Shadow_EditingSQLUser] DEFAULT (original_login()) NULL,
    [EditingDate]       DATETIME       CONSTRAINT [DF_Settings_Shadow_EditingDate] DEFAULT (getdate()) NULL,
    [Metadata_ID]       BIGINT         NULL,
    CONSTRAINT [PK_Settings_Shadow] PRIMARY KEY CLUSTERED ([SettingID] ASC, [ShadowID] ASC) ON [MeDriAnchor_Current]
);



