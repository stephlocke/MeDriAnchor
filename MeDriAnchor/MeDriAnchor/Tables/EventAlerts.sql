
CREATE TABLE [MeDriAnchor].[EventAlerts] (
    [EventAlertID]         BIGINT         IDENTITY (1, 1) NOT NULL,
    [Batch_ID]             BIGINT         NOT NULL,
    [SeverityID]           TINYINT        NOT NULL,
    [AlertMessage]         NVARCHAR (MAX) NOT NULL,
	[AlertDate]         DATETIME CONSTRAINT [DF_EventAlerts_AlertDate] DEFAULT(GETDATE()) NOT NULL,
	[RecordsInserted]		BIGINT NULL,
    [DBTableColumnID]      BIGINT         NULL,
    [PKDBTableColumnValue] SQL_VARIANT    NULL,
    CONSTRAINT [PK_EventAlerts] PRIMARY KEY CLUSTERED ([EventAlertID] ASC) ON [MeDriAnchor_Current],
    CONSTRAINT [FK_EventAlerts_Batch] FOREIGN KEY ([Batch_ID]) REFERENCES [MeDriAnchor].[Batch] ([Batch_ID]),
    CONSTRAINT [FK_EventAlerts_Severity] FOREIGN KEY ([SeverityID]) REFERENCES [MeDriAnchor].[Severity] ([SeverityID])
) TEXTIMAGE_ON [MeDriAnchor_Current];






GO

CREATE NONCLUSTERED INDEX [IX_EventAlerts_Batch_ID] ON [MeDriAnchor].[EventAlerts] ([Batch_ID])
GO

CREATE INDEX [IX_EventAlerts_ValidationFailures] ON [MeDriAnchor].[EventAlerts] ([DBTableColumnID], [PKDBTableColumnValue])
WHERE [DBTableColumnID] IS NOT NULL;
GO
