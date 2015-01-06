CREATE TABLE [MeDriAnchor].[DBTableColumnTest] (
    [DBTableColumnTestID] INT            IDENTITY (1, 1) NOT NULL,
    [TestName]            NVARCHAR (100) NOT NULL,
    [TestType]            NVARCHAR (50)  NOT NULL,
    CONSTRAINT [PK_DBTableColumnTest] PRIMARY KEY CLUSTERED ([DBTableColumnTestID] ASC),
    CONSTRAINT [CHK_DBTableColumnTest_DBTableColumnTestType] CHECK ([TestType]='> (LENGTH STRING)' OR [TestType]='ISVALID (LOOKUP STRING)' OR [TestType]='<> (STRING)' OR [TestType]='IS NUMERIC' OR [TestType]='IS NOT BLANK' OR [TestType]='IS NOT NULL' OR [TestType]='<=' OR [TestType]='<' OR [TestType]='>=' OR [TestType]='>' OR [TestType]='BETWEEN (YEARS FROM VALUE)' OR [TestType]='BETWEEN (NUMERIC)')
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