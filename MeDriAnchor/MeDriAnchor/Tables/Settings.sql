﻿
CREATE TABLE [MeDriAnchor].[Settings] (
    [SettingID]         SMALLINT       IDENTITY (1, 1) NOT NULL,
    [SettingKey]        NVARCHAR (100) NOT NULL,
    [SettingValue]      NVARCHAR (100) NOT NULL,
    [SettingInSchemaMD] BIT            NOT NULL,
    [Metadata_ID]       BIGINT         NULL,
    CONSTRAINT [PK_Settings] PRIMARY KEY CLUSTERED ([SettingID] ASC) ON [MeDriAnchor_Current]
);






GO
CREATE UNIQUE NONCLUSTERED INDEX [IDX_SettingKey]
    ON [MeDriAnchor].[Settings]([SettingKey] ASC)
    ON [MeDriAnchor_Current];


GO
CREATE TRIGGER [MeDriAnchor].[atrSettings_Update]
GO
CREATE TRIGGER [MeDriAnchor].[atrSettings_Insert]
GO
CREATE TRIGGER [MeDriAnchor].[atrSettings_Delete]