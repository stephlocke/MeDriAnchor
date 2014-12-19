
-- TESTS (MOVE TEST TABLES TO MEDRIANCHOR SCHEMA)
/*
------------------------------------------------------------------------------------------------------
00 TEST DEFINITION
------------------------------------------------------------------------------------------------------
*/
DECLARE @TestName NVARCHAR(100);
DECLARE @TestType NVARCHAR(50);

DECLARE @Test TABLE
	(
	[TestName] NVARCHAR(100),
	[TestType] NVARCHAR(50)
	);

INSERT INTO @Test
	(
	[TestName],
	[TestType]
	)
SELECT 'Value between two numbers', 'BETWEEN (NUMERIC)' UNION ALL
SELECT 'Value between two years based on column value', 'BETWEEN (YEARS FROM VALUE)' UNION ALL
SELECT 'Value is not blank', 'IS NOT BLANK' UNION ALL
SELECT 'Value is not null', 'IS NOT NULL' UNION ALL
SELECT 'Value is numeric', 'IS NUMERIC' UNION ALL
SELECT 'Value does not equal a given string value', '<> (STRING)' UNION ALL
SELECT 'Value is a valid lookup in another column', 'ISVALID (LOOKUP STRING)' UNION ALL
SELECT 'Value is a string greater than n in length', '> (LENGTH STRING)';

DECLARE TEST CURSOR
READ_ONLY
FOR SELECT * FROM @Test;

OPEN TEST;

FETCH NEXT FROM TEST INTO @TestName, @TestType;
WHILE (@@fetch_status <> -1)
BEGIN
	IF (@@fetch_status <> -2)
	BEGIN
		EXEC [dbo].[sspAddDBTest]
			@TestName = @TestName,
			@TestType = @TestType;
	END
	FETCH NEXT FROM TEST INTO @TestName, @TestType;
END

CLOSE TEST;
DEALLOCATE TEST;
GO

/*
------------------------------------------------------------------------------------------------------
01 TEST ATTACH
------------------------------------------------------------------------------------------------------
*/

SET NOCOUNT ON;

DECLARE @DBTableSchema SYSNAME;
DECLARE @DBTableName SYSNAME;
DECLARE @DBTableColumnName SYSNAME;
DECLARE @TestType NVARCHAR(50);
DECLARE @TestValue1 SQL_VARIANT;
DECLARE @TestValue2 SQL_VARIANT;
DECLARE @LkpDBTableSchema SYSNAME;
DECLARE @LkpDBTableName SYSNAME;
DECLARE @LkpDBTableColumnName SYSNAME;

DECLARE @Tests TABLE 
	(
	[DBTableSchema] SYSNAME NOT NULL,
	[DBTableName] SYSNAME NOT NULL,
	[DBTableColumnName] SYSNAME NOT NULL,
	[TestType] NVARCHAR(50) NOT NULL,
	[TestValue1] SQL_VARIANT NULL,
	[TestValue2] SQL_VARIANT NULL,
	[LkpDBTableSchema] SYSNAME NULL,
	[LkpDBTableName] SYSNAME NULL,
	[LkpDBTableColumnName] SYSNAME NULL
	);

INSERT INTO @Tests
SELECT 'MeDriAnchor', 'blah', 'InitialLoanTermMonths', 'BETWEEN (NUMERIC)', CONVERT(INT, 36), CONVERT(INT, 300), NULL, NULL, NULL;

INSERT INTO @Tests
SELECT 'MeDriAnchor', 'blah2', 'AddressLine1', 'IS NOT BLANK', NULL, NULL, NULL, NULL, NULL;

INSERT INTO @Tests
SELECT 'MeDriAnchor', 'blah3', 'AddressName', '> (LENGTH STRING)', CONVERT(INT, 2), NULL, NULL, NULL, NULL;

INSERT INTO @Tests
SELECT 'MeDriAnchor', 'blah4', 'AddressNumber', 'IS NUMERIC', NULL, NULL, NULL, NULL, NULL;

INSERT INTO @Tests
SELECT 'MeDriAnchor', 'blah5', 'PostCode_trimmed', 'ISVALID (LOOKUP STRING)', NULL, NULL, 'MeDriAnchor', 'LookupPostcode', 'pcd_trimmed';

-- loop through adding the tests
DECLARE TESTS CURSOR
READ_ONLY
FOR SELECT * FROM @Tests;

OPEN TESTS;

FETCH NEXT FROM TESTS INTO @DBTableSchema, @DBTableName, @DBTableColumnName, @TestType, @TestValue1, @TestValue2,
	@LkpDBTableSchema, @LkpDBTableName, @LkpDBTableColumnName;
WHILE (@@fetch_status <> -1)
BEGIN
	IF (@@fetch_status <> -2)
	BEGIN
		EXEC [MeDriAnchor].[sspAddDBTableColumnTest]
			@DBTableSchema = @DBTableSchema,
			@DBTableName = @DBTableName,
			@DBTableColumnName = @DBTableColumnName,
			@TestType = @TestType,
			@TestValue1 = @TestValue1,
			@TestValue2 = @TestValue2,
			@LkpDBTableSchema = @LkpDBTableSchema, 
			@LkpDBTableName = @LkpDBTableName, 
			@LkpDBTableColumnName = @LkpDBTableColumnName;
	END
	FETCH NEXT FROM TESTS INTO @DBTableSchema, @DBTableName, @DBTableColumnName, @TestType, @TestValue1, @TestValue2,
		@LkpDBTableSchema, @LkpDBTableName, @LkpDBTableColumnName;
END

CLOSE TESTS;
DEALLOCATE TESTS;
GO