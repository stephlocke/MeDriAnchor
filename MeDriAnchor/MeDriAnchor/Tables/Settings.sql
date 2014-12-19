
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
CREATE TRIGGER [MeDriAnchor].[atrSettings_Update]ON [MeDriAnchor].[Settings] WITH EXECUTE AS 'MeDriAnchorUser'FOR UPDATEAS/**revisions: - author: MeDriAnchor	date: 24 Nov 2014revisions: - author: MeDriAnchor	date: 24 Nov 2014summary:	>				Records the update of an [MeDriAnchor].[Settings] table record - code:	Cannot be called from client code	parameters: n/areturns: on success nothing, otherwise throws an error**/BEGIN TRY	INSERT INTO [MeDriAnchor].[Settings_Shadow]	([ShadowType],[SettingID],[SettingKey],[SettingValue],[SettingInSchemaMD],[Metadata_ID])	SELECT 'U',[DELETED].[SettingID],[DELETED].[SettingKey],[DELETED].[SettingValue],[DELETED].[SettingInSchemaMD],[DELETED].[Metadata_ID]	FROM DELETED;END TRYBEGIN CATCH	DECLARE @ErrorMessage NVARCHAR(4000);	DECLARE @ErrorSeverity INT;	DECLARE @ErrorState INT;	SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();	RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);END CATCH;
GO
CREATE TRIGGER [MeDriAnchor].[atrSettings_Insert]ON [MeDriAnchor].[Settings] WITH EXECUTE AS 'MeDriAnchorUser'FOR INSERTAS/**revisions: - author: MeDriAnchor	date: 24 Nov 2014summary:	>				Records the insert of an [MeDriAnchor].[Settings] table record - code:	Cannot be called from client code	parameters: n/areturns: on success nothing, otherwise throws an error**/BEGIN TRY	INSERT INTO [MeDriAnchor].[Settings_Shadow]	([ShadowType],[SettingID],[SettingKey],[SettingValue],[SettingInSchemaMD],[Metadata_ID])	SELECT 'I',[INSERTED].[SettingID],[INSERTED].[SettingKey],[INSERTED].[SettingValue],[INSERTED].[SettingInSchemaMD],[INSERTED].[Metadata_ID]	FROM INSERTED;END TRYBEGIN CATCH	DECLARE @ErrorMessage NVARCHAR(4000);	DECLARE @ErrorSeverity INT;	DECLARE @ErrorState INT;	SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();	RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);END CATCH;
GO
CREATE TRIGGER [MeDriAnchor].[atrSettings_Delete]ON [MeDriAnchor].[Settings] WITH EXECUTE AS 'MeDriAnchorUser'FOR DELETEAS/**revisions: - author: MeDriAnchor	date: 24 Nov 2014summary:	>				Records the delete of an [MeDriAnchor].[Settings] table record - code:	Cannot be called from client code	parameters: n/areturns: on success nothing, otherwise throws an error**/BEGIN TRY	INSERT INTO [MeDriAnchor].[Settings_Shadow]	([ShadowType],[SettingID],[SettingKey],[SettingValue],[SettingInSchemaMD],[Metadata_ID])	SELECT 'D',[DELETED].[SettingID],[DELETED].[SettingKey],[DELETED].[SettingValue],[DELETED].[SettingInSchemaMD],[DELETED].[Metadata_ID]	FROM DELETED;END TRYBEGIN CATCH	DECLARE @ErrorMessage NVARCHAR(4000);	DECLARE @ErrorSeverity INT;	DECLARE @ErrorState INT;	SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();	RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);END CATCH;