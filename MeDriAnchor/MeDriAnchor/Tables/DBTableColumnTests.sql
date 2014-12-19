CREATE TABLE [MeDriAnchor].[DBTableColumnTests]
(
	[DBTableColumnID] BIGINT,
	[DBTableColumnTestID] INT,
	[Active] BIT CONSTRAINT [DF_DBTableColumnTests_Active] DEFAULT(1) NOT NULL,
	CONSTRAINT [PK_DBTableColumnTests] PRIMARY KEY CLUSTERED ([DBTableColumnID] ASC, [DBTableColumnTestID] ASC)
);
