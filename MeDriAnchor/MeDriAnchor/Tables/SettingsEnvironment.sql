﻿
CREATE TABLE [MeDriAnchor].[SettingsEnvironment] (
    [SettingsEnvironment_ID] SMALLINT       IDENTITY (1, 1) NOT NULL,
    [Environment_ID]         SMALLINT       NOT NULL,
    [Metadata_ID]            BIGINT         NULL,
    [SettingKey]             NVARCHAR (100) NOT NULL,
    [SettingValue]           NVARCHAR (100) NOT NULL,
    [SettingInSchemaMD]      BIT            NOT NULL,
    CONSTRAINT [PK_SettingsEnvironment] PRIMARY KEY CLUSTERED ([SettingsEnvironment_ID] ASC) ON [MeDriAnchor_Current],
    CONSTRAINT [FK_SettingsEnvironment_Metadata] FOREIGN KEY ([Metadata_ID]) REFERENCES [MeDriAnchor].[Metadata] ([Metadata_ID]),
    CONSTRAINT [FK_SettingsEnvironment_Setting] FOREIGN KEY ([SettingKey]) REFERENCES [MeDriAnchor].[Settings] ([SettingKey])
);






GO
CREATE UNIQUE NONCLUSTERED INDEX [IDX_SettingKey]
    ON [MeDriAnchor].[SettingsEnvironment]([SettingKey] ASC, [Environment_ID] ASC)
    ON [MeDriAnchor_Current];


GO
CREATE TRIGGER [MeDriAnchor].[atrSettingsEnvironment_Update]
GO
CREATE TRIGGER [MeDriAnchor].[atrSettingsEnvironment_Insert]
GO
CREATE TRIGGER [MeDriAnchor].[atrSettingsEnvironment_Delete]