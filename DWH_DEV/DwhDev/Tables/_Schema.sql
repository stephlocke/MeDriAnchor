CREATE TABLE [DwhDev].[_Schema](
	[version] [int] IDENTITY(1,1) NOT NULL,
	[activation] [datetime2](7) NOT NULL,
	[schema] [xml] NOT NULL,
CONSTRAINT [PK_Schema] PRIMARY KEY CLUSTERED ([version] ASC)
)
GO
