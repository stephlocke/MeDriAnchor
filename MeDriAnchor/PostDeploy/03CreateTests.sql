-- ADD TESTS (DEFINITIONS - ACTUAL LOGIC FOR WHAT THEY DO CONTROLLED BY THE MeDriAnchor.sspCreateDWHTests PROCEDURE)
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
		EXEC [MeDriAnchor].[sspAddDBTest]
			@TestName = @TestName,
			@TestType = @TestType;
	END
	FETCH NEXT FROM TEST INTO @TestName, @TestType;
END

CLOSE TEST;
DEALLOCATE TEST;
GO