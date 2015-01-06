
CREATE TABLE [MeDriAnchor].[BatchType] (
    [BatchTypeID] SMALLINT      IDENTITY (1, 1) NOT NULL,
    [BatchType]   NVARCHAR (20) NOT NULL,
    CONSTRAINT [PK_BatchType] PRIMARY KEY CLUSTERED ([BatchTypeID] ASC) ON [MeDriAnchor_Current]
);








GO
CREATE TRIGGER [MeDriAnchor].[atrBatchType_Update]ON [MeDriAnchor].[BatchType] WITH EXECUTE AS 'MeDriAnchorUser'FOR UPDATEAS/**revisions: - author: MeDriAnchor	date: 05 Jan 2015revisions: - author: MeDriAnchor	date: 05 Jan 2015summary:	>				Records the update of an [MeDriAnchor].[BatchType] table record - code:	Cannot be called from client code	parameters: n/areturns: on success nothing, otherwise throws an error**/BEGIN TRY	INSERT INTO [MeDriAnchor].[BatchType_Shadow]	([ShadowType],[BatchTypeID],[BatchType])	SELECT 'U',[DELETED].[BatchTypeID],[DELETED].[BatchType]	FROM DELETED;END TRYBEGIN CATCH	DECLARE @ErrorMessage NVARCHAR(4000);	DECLARE @ErrorSeverity INT;	DECLARE @ErrorState INT;	SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();	RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);END CATCH;
GO
CREATE TRIGGER [MeDriAnchor].[atrBatchType_Insert]ON [MeDriAnchor].[BatchType] WITH EXECUTE AS 'MeDriAnchorUser'FOR INSERTAS/**revisions: - author: MeDriAnchor	date: 05 Jan 2015summary:	>				Records the insert of an [MeDriAnchor].[BatchType] table record - code:	Cannot be called from client code	parameters: n/areturns: on success nothing, otherwise throws an error**/BEGIN TRY	INSERT INTO [MeDriAnchor].[BatchType_Shadow]	([ShadowType],[BatchTypeID],[BatchType])	SELECT 'I',[INSERTED].[BatchTypeID],[INSERTED].[BatchType]	FROM INSERTED;END TRYBEGIN CATCH	DECLARE @ErrorMessage NVARCHAR(4000);	DECLARE @ErrorSeverity INT;	DECLARE @ErrorState INT;	SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();	RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);END CATCH;
GO
CREATE TRIGGER [MeDriAnchor].[atrBatchType_Delete]ON [MeDriAnchor].[BatchType] WITH EXECUTE AS 'MeDriAnchorUser'FOR DELETEAS/**revisions: - author: MeDriAnchor	date: 05 Jan 2015summary:	>				Records the delete of an [MeDriAnchor].[BatchType] table record - code:	Cannot be called from client code	parameters: n/areturns: on success nothing, otherwise throws an error**/BEGIN TRY	INSERT INTO [MeDriAnchor].[BatchType_Shadow]	([ShadowType],[BatchTypeID],[BatchType])	SELECT 'D',[DELETED].[BatchTypeID],[DELETED].[BatchType]	FROM DELETED;END TRYBEGIN CATCH	DECLARE @ErrorMessage NVARCHAR(4000);	DECLARE @ErrorSeverity INT;	DECLARE @ErrorState INT;	SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();	RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);END CATCH;