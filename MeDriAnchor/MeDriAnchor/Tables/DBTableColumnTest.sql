CREATE TABLE [MeDriAnchor].[DBTableColumnTest]
(
	[DBTableColumnTestID] INT IDENTITY (1, 1) NOT NULL,
	[TestName] NVARCHAR(100) NOT NULL,
	[TestType] NVARCHAR(50) 
		CONSTRAINT [CHK_DBTableColumnTest_DBTableColumnTestType] CHECK([TestType] IN('BETWEEN (NUMERIC)', 
		'BETWEEN (YEARS FROM VALUE)', '>', '>=', '<', '<=', 'IS NOT NULL',
		'IS NOT BLANK','IS NUMERIC','<> (STRING)','ISVALID (LOOKUP STRING)',
		'> (LENGTH STRING)')) NOT NULL, 
    CONSTRAINT [PK_DBTableColumnTest] PRIMARY KEY CLUSTERED ([DBTableColumnTestID] ASC)
);



GO
EXEC sp_addextendedproperty @name = N'MS_Description',
    @value = N'The type of test. Must be one of the following values: "BETWEEN (NUMERIC)", "BETWEEN (YEARS FROM VALUE)", ">", ">=", "<", "<=", "IS NOT NULL", "IS NOT BLANK","IS NUMERIC","<> (STRING)","ISVALID (LOOKUP STRING)","> (LENGTH STRING)"',
    @level0type = N'SCHEMA',
    @level0name = N'MeDriAnchor',
    @level1type = N'TABLE',
    @level1name = N'DBTableColumnTest',
    @level2type = N'COLUMN',
    @level2name = N'TestName';
GO