
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
CREATE TRIGGER [MeDriAnchor].[atrSettingsEnvironment_Update]ON [MeDriAnchor].[SettingsEnvironment] WITH EXECUTE AS 'MeDriAnchorUser'FOR UPDATEAS/**revisions: - author: MeDriAnchor	date: 05 Jan 2015revisions: - author: MeDriAnchor	date: 05 Jan 2015summary:	>				Records the update of an [MeDriAnchor].[SettingsEnvironment] table record - code:	Cannot be called from client code	parameters: n/areturns: on success nothing, otherwise throws an error**/BEGIN TRY	INSERT INTO [MeDriAnchor].[SettingsEnvironment_Shadow]	([ShadowType],[SettingsEnvironment_ID],[Environment_ID],[Metadata_ID],[SettingKey],[SettingValue],[SettingInSchemaMD])	SELECT 'U',[DELETED].[SettingsEnvironment_ID],[DELETED].[Environment_ID],[DELETED].[Metadata_ID],[DELETED].[SettingKey],[DELETED].[SettingValue],[DELETED].[SettingInSchemaMD]	FROM DELETED;END TRYBEGIN CATCH	DECLARE @ErrorMessage NVARCHAR(4000);	DECLARE @ErrorSeverity INT;	DECLARE @ErrorState INT;	SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();	RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);END CATCH;
GO
CREATE TRIGGER [MeDriAnchor].[atrSettingsEnvironment_Insert]ON [MeDriAnchor].[SettingsEnvironment] WITH EXECUTE AS 'MeDriAnchorUser'FOR INSERTAS/**revisions: - author: MeDriAnchor	date: 05 Jan 2015summary:	>				Records the insert of an [MeDriAnchor].[SettingsEnvironment] table record - code:	Cannot be called from client code	parameters: n/areturns: on success nothing, otherwise throws an error**/BEGIN TRY	INSERT INTO [MeDriAnchor].[SettingsEnvironment_Shadow]	([ShadowType],[SettingsEnvironment_ID],[Environment_ID],[Metadata_ID],[SettingKey],[SettingValue],[SettingInSchemaMD])	SELECT 'I',[INSERTED].[SettingsEnvironment_ID],[INSERTED].[Environment_ID],[INSERTED].[Metadata_ID],[INSERTED].[SettingKey],[INSERTED].[SettingValue],[INSERTED].[SettingInSchemaMD]	FROM INSERTED;END TRYBEGIN CATCH	DECLARE @ErrorMessage NVARCHAR(4000);	DECLARE @ErrorSeverity INT;	DECLARE @ErrorState INT;	SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();	RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);END CATCH;
GO
CREATE TRIGGER [MeDriAnchor].[atrSettingsEnvironment_Delete]ON [MeDriAnchor].[SettingsEnvironment] WITH EXECUTE AS 'MeDriAnchorUser'FOR DELETEAS/**revisions: - author: MeDriAnchor	date: 05 Jan 2015summary:	>				Records the delete of an [MeDriAnchor].[SettingsEnvironment] table record - code:	Cannot be called from client code	parameters: n/areturns: on success nothing, otherwise throws an error**/BEGIN TRY	INSERT INTO [MeDriAnchor].[SettingsEnvironment_Shadow]	([ShadowType],[SettingsEnvironment_ID],[Environment_ID],[Metadata_ID],[SettingKey],[SettingValue],[SettingInSchemaMD])	SELECT 'D',[DELETED].[SettingsEnvironment_ID],[DELETED].[Environment_ID],[DELETED].[Metadata_ID],[DELETED].[SettingKey],[DELETED].[SettingValue],[DELETED].[SettingInSchemaMD]	FROM DELETED;END TRYBEGIN CATCH	DECLARE @ErrorMessage NVARCHAR(4000);	DECLARE @ErrorSeverity INT;	DECLARE @ErrorState INT;	SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();	RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);END CATCH;