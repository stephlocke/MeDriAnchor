PRINT 'START: Loading Adventure Works 2008 metadata into MeDriAnchor....';

SET NOCOUNT ON;

/* 
------------------------------------------------------------------------------------------------------------------------------------------
STEP 1: Tell MeDriAnchor about the source; what server it is on, what type of database this is, and details about the database
------------------------------------------------------------------------------------------------------------------------------------------
*/

/*
NOTE: THE  specific to that databadse which produce the same out MUST BE ADDED TO THE SOURCE DATABASE PRIOR TO ANY ATTEMPT TO
GET THE SOURCE SCHEMA. IF THE DATABSE IS SQL SEERVER THEN JUST RUN THESE IN, OTHERWISE YOU WILL HAVE TO WRITE NEW VERSIONS
THAT PRODUCE THE SAME OUTPUT FOR THE GIVEN DATABASE TYPE.

*/

DECLARE @DBServerID BIGINT;
DECLARE @DBID BIGINT;
DECLARE @Environment_ID_Dev SMALLINT = (SELECT [Environment_ID] FROM [MeDriAnchor].[Environment] 
	WHERE [EnvironmentName] = 'DEVELOPMENT');

-- 1.1 Add the server if it doesn't exist (the server that the Adventure Works database was restored on)
EXEC [MeDriAnchor].[sspAddDBServer]
	@DBServerType = 'SQLSERVER',
	@DBServerName = 'TECHNOBITCH\SQL2008R2D2',
	@DBServerID = @DBServerID OUTPUT;

-- 1.2: Create the database if it doesn't exist (using the name you used when restoring the database)
EXEC [MeDriAnchor].[sspAddDB]
	@DBServerID = @DBServerID,
	@DBName = 'AdventureWorks2008', 
	@DBUserName = NULL, 
	@DBUserPassword = NULL,
	@DBIsLocal = 0,
	@DBIsSource = 1,
	@DBIsDestination = 0,
	@Environment_ID = NULL,
	@DBID = @DBID OUTPUT;

-- 1.3: Run the linked server routine to do any necessary adjustments or creations
EXEC [MeDriAnchor].[amsp_ETLSQL_CreateLinkedServers];

-- 1.4: Hoover in the source schema
EXEC [MeDriAnchor].[sspGetSchemaFromSourceDB]
	@DBID = @DBID,
	@Environment_ID = @Environment_ID_Dev;
GO

/* 
------------------------------------------------------------------------------------------------------------------------------------------
STEP 2: Add the Anchor markup (Production)
------------------------------------------------------------------------------------------------------------------------------------------
*/

-- 2.1 Flag the Knots
SET NOCOUNT ON;

-- N.B. All Knots must have a numeric key and a value

DECLARE @DBTableSchema SYSNAME;
DECLARE @DBTableName SYSNAME;
DECLARE @KnotMnemonic NVARCHAR(7);
DECLARE @IsHistorised BIT = 0;
DECLARE @IDRoleName NVARCHAR(30);
DECLARE @ValRoleName NVARCHAR(30);
DECLARE @IDKnotJoinColumn SYSNAME;
DECLARE @ValKnotJoinColumn SYSNAME;
DECLARE @ValTableColumnAlias SYSNAME;
DECLARE @IDDBTableColumnName SYSNAME;
DECLARE @ValDBTableColumnName SYSNAME;
DECLARE @Environment_ID_Prod SMALLINT = (SELECT [Environment_ID] FROM [MeDriAnchor].[Environment] 
	WHERE [EnvironmentName] = 'PRODUCTION');

DECLARE @Knots TABLE 
	(
	[DBTableSchema] SYSNAME,
	[DBTableName] SYSNAME,
	[KnotMnemonic] NVARCHAR(7),
	[IsHistorised] BIT,
	[IDRoleName] NVARCHAR(30),
	[ValRoleName] NVARCHAR(30),
	[IDKnotJoinColumn] SYSNAME,
	[ValKnotJoinColumn] SYSNAME,
	[ValTableColumnAlias] SYSNAME,
	[IDDBTableColumnName] SYSNAME,
	[ValDBTableColumnName] SYSNAME
	);

INSERT INTO @Knots
	(
	[DBTableSchema],
	[DBTableName],
	[KnotMnemonic],
	[IsHistorised],
	[IDRoleName],
	[ValRoleName],
	[IDKnotJoinColumn],
	[ValKnotJoinColumn],
	[ValTableColumnAlias],
	[IDDBTableColumnName],
	[ValDBTableColumnName]
	)
SELECT 'Sales','SalesOrderStatus','LK_OST',1,'status','status','Status','Status','','Status_ID','Status' UNION ALL
SELECT 'Person','PersonTitle','LK_PTL',1,'title','title','Title','Title','','Title_ID','Title';

-- loop through adding\updating the knots
DECLARE KNOTS CURSOR
READ_ONLY
FOR SELECT * FROM @Knots;

OPEN KNOTS

FETCH NEXT FROM KNOTS INTO @DBTableSchema, @DBTableName, @KnotMnemonic, @IsHistorised, @IDRoleName, @ValRoleName, @IDKnotJoinColumn,
							@ValKnotJoinColumn, @ValTableColumnAlias, @IDDBTableColumnName, @ValDBTableColumnName;
WHILE (@@fetch_status <> -1)
BEGIN
	IF (@@fetch_status <> -2)
	BEGIN
		EXEC [MeDriAnchor].[sspAddKnot]
			@DBTableSchema = @DBTableSchema,
			@DBTableName = @DBTableName,
			@KnotMnemonic = @KnotMnemonic,
			@IsHistorised = @IsHistorised,
			@IDRoleName = @IDRoleName,
			@ValRoleName = @ValRoleName,
			@IDKnotJoinColumn = @IDKnotJoinColumn,
			@ValKnotJoinColumn = @ValKnotJoinColumn,
			@ValTableColumnAlias = @ValTableColumnAlias,
			@IDDBTableColumnName = @IDDBTableColumnName,
			@ValDBTableColumnName = @ValDBTableColumnName,
			@Environment_ID = @Environment_ID_Prod;
	END
	FETCH NEXT FROM KNOTS INTO @DBTableSchema, @DBTableName, @KnotMnemonic, @IsHistorised, @IDRoleName, @ValRoleName, @IDKnotJoinColumn,
								@ValKnotJoinColumn, @ValTableColumnAlias, @IDDBTableColumnName, @ValDBTableColumnName;
END

CLOSE KNOTS;
DEALLOCATE KNOTS;
GO

-- 2.2 Flag the Anchors
SET NOCOUNT ON;

DECLARE @DBTableSchema SYSNAME;
DECLARE @DBTableName SYSNAME;
DECLARE @DBTableColumnName SYSNAME;
DECLARE @DBTableColumnAlias SYSNAME;
DECLARE @AnchorMnemonic NVARCHAR(3);
DECLARE @DBTableColumnNameDateComp SYSNAME;
DECLARE @Environment_ID SMALLINT;
DECLARE @Environment_ID_Prod SMALLINT = (SELECT [Environment_ID] FROM [MeDriAnchor].[Environment] 
	WHERE [EnvironmentName] = 'PRODUCTION');
DECLARE @Environment_ID_Uat SMALLINT = (SELECT [Environment_ID] FROM [MeDriAnchor].[Environment] 
	WHERE [EnvironmentName] = 'UAT');
DECLARE @Environment_ID_Dev SMALLINT = (SELECT [Environment_ID] FROM [MeDriAnchor].[Environment] 
	WHERE [EnvironmentName] = 'DEVELOPMENT');

DECLARE @Anchors TABLE
	(
	[DBTableSchema] SYSNAME,
	[DBTableName] SYSNAME,
	[DBTableColumnName] SYSNAME,
	[DBTableColumnAlias] SYSNAME,
	[AnchorMnemonic] NVARCHAR(3),
	[DBTableColumnNameDateComp] SYSNAME,
	[Environment_ID] SMALLINT
	);
INSERT INTO @Anchors
SELECT 'Sales', 'SalesOrderHeader', 'SalesOrderID', 'AWSalesOrderID', 'SO', 'ModifiedDate', @Environment_ID_Prod UNION ALL
SELECT 'Sales', 'Customer', 'CustomerID', 'AWCustomerID', 'CU', 'ModifiedDate', @Environment_ID_Prod UNION ALL
SELECT 'Person', 'Person', 'BusinessEntityID', 'AWBusinessEntityID', 'PE', 'ModifiedDate', @Environment_ID_Prod UNION ALL
SELECT 'Person', 'EmailAddress', 'EmailAddressID', 'AWEmailAddressID', 'EM', 'ModifiedDate', @Environment_ID_Prod UNION ALL
SELECT 'Sales', 'SalesPerson', 'BusinessEntityID', 'AWSalesPersonID', 'SP', 'ModifiedDate', @Environment_ID_Uat UNION ALL
SELECT 'Sales', 'SalesTerritory', 'TerritoryID', 'AWTerritoryID', 'TR', 'ModifiedDate', @Environment_ID_Dev;

-- loop through adding\updating the anchors
DECLARE ANCHORS CURSOR
READ_ONLY
FOR SELECT * FROM @Anchors;

OPEN ANCHORS

FETCH NEXT FROM ANCHORS INTO @DBTableSchema, @DBTableName, @DBTableColumnName, @DBTableColumnAlias, @AnchorMnemonic, 
	@DBTableColumnNameDateComp, @Environment_ID;
WHILE (@@fetch_status <> -1)
BEGIN
	IF (@@fetch_status <> -2)
	BEGIN
		EXEC [MeDriAnchor].[sspAddAnchor]
			@DBTableSchema = @DBTableSchema,
			@DBTableName = @DBTableName,
			@DBTableColumnName = @DBTableColumnName,
			@DBTableColumnAlias = @DBTableColumnAlias,
			@AnchorMnemonic = @AnchorMnemonic,
			@DBTableColumnNameDateComp = @DBTableColumnNameDateComp,
			@Environment_ID = @Environment_ID;
	END
	FETCH NEXT FROM ANCHORS INTO @DBTableSchema, @DBTableName, @DBTableColumnName, @DBTableColumnAlias, 
		@AnchorMnemonic, @DBTableColumnNameDateComp, @Environment_ID;
END

CLOSE ANCHORS;
DEALLOCATE ANCHORS;
GO

-- 2.3 Flag the Attributes
DECLARE @DBTableSchema SYSNAME;
DECLARE @DBTableName SYSNAME;
DECLARE @DBTableColumnName SYSNAME;
DECLARE @IsAttribute BIT;
DECLARE @IsHistorised BIT;
DECLARE @AnchorMnemonicRef NVARCHAR(3);
DECLARE @AttributeMnemonic NVARCHAR(7);
DECLARE @KnotMnemonic NVARCHAR(7);
DECLARE @CreateNCIndexInDWH BIT;
DECLARE @Environment_ID SMALLINT;
DECLARE @Environment_ID_Prod SMALLINT = (SELECT [Environment_ID] FROM [MeDriAnchor].[Environment] 
	WHERE [EnvironmentName] = 'PRODUCTION');
DECLARE @Environment_ID_Uat SMALLINT = (SELECT [Environment_ID] FROM [MeDriAnchor].[Environment] 
	WHERE [EnvironmentName] = 'UAT');
DECLARE @Environment_ID_Dev SMALLINT = (SELECT [Environment_ID] FROM [MeDriAnchor].[Environment] 
	WHERE [EnvironmentName] = 'DEVELOPMENT');

DECLARE @Attributes TABLE 
	(
	[DBTableSchema] SYSNAME,
	[DBTableName] SYSNAME,
	[DBTableColumnName] SYSNAME,
	[IsAttribute] BIT,
	[IsHistorised] BIT,
	[AnchorMnemonicRef] NVARCHAR(3),
	[AttributeMnemonic] NVARCHAR(7),
	[KnotMnemonic] NVARCHAR(7),
	[CreateNCIndexInDWH] BIT,
	[Environment_ID] SMALLINT
	);
INSERT INTO @Attributes
SELECT 'Sales', 'SalesOrderHeader', 'OrderDate', 1, 1, 'SO', 'SO_ODT','', 0, @Environment_ID_Prod UNION ALL
SELECT 'Sales', 'SalesOrderHeader', 'SalesOrderNumber', 1, 1, 'SO', 'SO_SON','', 0, @Environment_ID_Prod UNION ALL
SELECT 'Sales', 'SalesOrderHeader', 'AccountNumber', 1, 1, 'SO', 'SO_ACN','', 0, @Environment_ID_Prod UNION ALL
SELECT 'Sales', 'SalesOrderHeader', 'SubTotal', 1, 1, 'SO', 'SO_SBT','', 0, @Environment_ID_Prod UNION ALL
SELECT 'Sales', 'SalesOrderHeader', 'Status', 1, 1, 'SO', 'SP_STS','LK_OST', 0, @Environment_ID_Prod UNION ALL
SELECT 'Sales', 'SalesOrderHeader', 'ModifiedDate', 1, 1, 'SO', 'SO_MOD','', 0, @Environment_ID_Prod UNION ALL
SELECT 'Person', 'Person', 'FirstName', 1, 1, 'PE', 'PE_FNM','', 0, @Environment_ID_Prod UNION ALL
SELECT 'Person', 'Person', 'LastName', 1, 1, 'PE', 'PE_LNM','', 0, @Environment_ID_Prod UNION ALL
SELECT 'Person', 'Person', 'Title', 1, 1, 'PE', 'PE_TLE','LK_PTL', 0, @Environment_ID_Prod UNION ALL
SELECT 'Person', 'Person', 'ModifiedDate', 1, 1, 'PE', 'PE_MOD','', 0, @Environment_ID_Prod UNION ALL
SELECT 'Person', 'EmailAddress', 'BusinessEntityID', 1, 1, 'EM', 'EM_BEI','', 0, @Environment_ID_Prod UNION ALL
SELECT 'Person', 'EmailAddress', 'EmailAddress', 1, 1, 'EM', 'EM_EML','', 0, @Environment_ID_Prod UNION ALL
SELECT 'Person', 'EmailAddress', 'ModifiedDate', 1, 1, 'EM', 'EM_MOD','', 0, @Environment_ID_Prod UNION ALL
SELECT 'Sales', 'Customer', 'TerritoryID', 1, 1, 'CU', 'CU_TER','', 0, @Environment_ID_Prod UNION ALL
SELECT 'Sales', 'Customer', 'AccountNumber', 1, 1, 'CU', 'CU_ACN','', 0, @Environment_ID_Prod UNION ALL
SELECT 'Sales', 'Customer', 'ModifiedDate', 1, 1, 'CU', 'CU_MOD','', 0, @Environment_ID_Prod UNION ALL
SELECT 'Sales', 'SalesPerson', 'TerritoryID', 1, 1, 'SP', 'SP_TRT','', 0, @Environment_ID_Uat UNION ALL
SELECT 'Sales', 'SalesPerson', 'SalesQuota', 1, 1, 'SP', 'SP_SLQ','', 0, @Environment_ID_Uat UNION ALL
SELECT 'Sales', 'SalesPerson', 'Bonus', 1, 1, 'SP', 'SP_BON','', 0, @Environment_ID_Uat UNION ALL
SELECT 'Sales', 'SalesPerson', 'CommissionPct', 1, 1, 'SP', 'SP_CPT','', 0, @Environment_ID_Uat UNION ALL
SELECT 'Sales', 'SalesPerson', 'SalesYTD', 1, 1, 'SP', 'SP_YTD','', 0, @Environment_ID_Uat UNION ALL
SELECT 'Sales', 'SalesPerson', 'SalesLastYear', 1, 1, 'SP', 'SP_SLY','', 0, @Environment_ID_Uat UNION ALL
SELECT 'Sales', 'SalesPerson', 'ModifiedDate', 1, 1, 'SP', 'SP_MOD','', 0, @Environment_ID_Uat UNION ALL
SELECT 'Sales', 'SalesTerritory', 'Name', 1, 1, 'TR', 'TR_NAM','', 0, @Environment_ID_Dev UNION ALL
SELECT 'Sales', 'SalesTerritory', 'CountryRegionCode', 1, 1, 'TR', 'TR_CRC','', 0, @Environment_ID_Dev UNION ALL -- Knot?
SELECT 'Sales', 'SalesTerritory', 'Group', 1, 1, 'TR', 'TR_TRG','', 0, @Environment_ID_Dev UNION ALL
SELECT 'Sales', 'SalesTerritory', 'SalesYTD', 1, 1, 'TR', 'TR_TSY','', 0, @Environment_ID_Dev UNION ALL
SELECT 'Sales', 'SalesTerritory', 'SalesLastYear', 1, 1, 'TR', 'TR_TSL','', 0, @Environment_ID_Dev UNION ALL
SELECT 'Sales', 'SalesTerritory', 'CostYTD', 1, 1, 'TR', 'TR_TCY','', 0, @Environment_ID_Dev UNION ALL
SELECT 'Sales', 'SalesTerritory', 'CostLastYear', 1, 1, 'TR', 'TR_TCL','', 0, @Environment_ID_Dev UNION ALL
SELECT 'Sales', 'SalesTerritory', 'ModifiedDate', 1, 1, 'TR', 'TR_MOD','', 0, @Environment_ID_Dev;

-- loop through adding\updating the attributes
DECLARE ATTRIBUTES CURSOR
READ_ONLY
FOR SELECT * FROM @Attributes;

OPEN ATTRIBUTES

FETCH NEXT FROM ATTRIBUTES INTO @DBTableSchema, @DBTableName, @DBTableColumnName, @IsAttribute, @IsHistorised, @AnchorMnemonicRef, 
								@AttributeMnemonic, @KnotMnemonic, @CreateNCIndexInDWH, @Environment_ID;
WHILE (@@fetch_status <> -1)
BEGIN
	IF (@@fetch_status <> -2)
	BEGIN
		EXEC [MeDriAnchor].[sspAddAttribute]
			@DBTableSchema = @DBTableSchema,
			@DBTableName = @DBTableName,
			@DBTableColumnName = @DBTableColumnName,
			@IsAttribute = @IsAttribute,
			@IsHistorised = @IsHistorised, -- Flag to say whether this attribute is hsitorised or not
			@AnchorMnemonicRef = @AnchorMnemonicRef,
			@AttributeMnemonic = @AttributeMnemonic,
			@KnotMnemonic = @KnotMnemonic,
			@CreateNCIndexInDWH = @CreateNCIndexInDWH,
			@Environment_ID = @Environment_ID;

	END
	FETCH NEXT FROM ATTRIBUTES INTO @DBTableSchema, @DBTableName, @DBTableColumnName, @IsAttribute, @IsHistorised, @AnchorMnemonicRef, 
									@AttributeMnemonic, @KnotMnemonic, @CreateNCIndexInDWH, @Environment_ID;
END

CLOSE ATTRIBUTES;
DEALLOCATE ATTRIBUTES;
GO

-- 2.4 Flag the Ties
DECLARE @TieMnemonic NVARCHAR(20);
DECLARE @GenerateID BIT;
DECLARE @IsHistorised BIT;
DECLARE @KnotMnemonic NVARCHAR(20);
DECLARE @KnotRoleName NVARCHAR(50);
DECLARE @J1AnchorMnemonicRef NVARCHAR(3);
DECLARE @J1RoleName NVARCHAR(50);
DECLARE @J1DBTableSchema SYSNAME;
DECLARE @J1DBTableName SYSNAME;
DECLARE @J1DBTableColumnName SYSNAME;
DECLARE @J1TieJoinOrder SMALLINT;
DECLARE @J1TieJoinColumn SYSNAME;
DECLARE @J1IsIdentity BIT;
DECLARE @J2AnchorMnemonicRef NVARCHAR(3);
DECLARE @J2RoleName NVARCHAR(50);
DECLARE @J2TieJoinOrder SMALLINT;
DECLARE @J2TieJoinColumn SYSNAME;
DECLARE @J2IsIdentity BIT;
DECLARE @J2DBTableSchema SYSNAME;
DECLARE @J2DBTableName SYSNAME;
DECLARE @J2DBTableColumnName SYSNAME;
DECLARE @Environment_ID SMALLINT;
DECLARE @Environment_ID_Prod SMALLINT = (SELECT [Environment_ID] FROM [MeDriAnchor].[Environment] 
	WHERE [EnvironmentName] = 'PRODUCTION');
DECLARE @Environment_ID_Uat SMALLINT = (SELECT [Environment_ID] FROM [MeDriAnchor].[Environment] 
	WHERE [EnvironmentName] = 'UAT');
DECLARE @Environment_ID_Dev SMALLINT = (SELECT [Environment_ID] FROM [MeDriAnchor].[Environment] 
	WHERE [EnvironmentName] = 'DEVELOPMENT');

DECLARE @Ties TABLE 
	(
	[TieMnemonic] NVARCHAR(20),
	[GenerateID] BIT,
	[IsHistorised] BIT,
	[KnotMnemonic] NVARCHAR(20),
	[KnotRoleName] NVARCHAR(50),
	[J1AnchorMnemonicRef] NVARCHAR(3),
	[J1DBTableSchema] SYSNAME,
	[J1DBTableName] SYSNAME,
	[J1DBTableColumnName] SYSNAME,
	[J1RoleName] NVARCHAR(50),
	[J1TieJoinOrder] SMALLINT,
	[J1TieJoinColumn] SYSNAME,
	[J1IsIdentity] BIT,
	[J2AnchorMnemonicRef] NVARCHAR(3),
	[J2DBTableSchema] SYSNAME,
	[J2DBTableName] SYSNAME,
	[J2DBTableColumnName] SYSNAME,
	[J2RoleName] NVARCHAR(50),
	[J2TieJoinOrder] SMALLINT,
	[J2TieJoinColumn] SYSNAME,
	[J2IsIdentity] BIT,
	[Environment_ID] SMALLINT
	);
INSERT INTO @Ties
SELECT 'PE-CU', 0, 1, '', '', 'PE', 'Person', 'Person', 'BusinessEntityID', 'employee', 1, '', 1, 'CU', 'Sales', 'Customer', 'CustomerID', 'employs', 2, 'PersonID', 1, @Environment_ID_Prod UNION ALL
SELECT 'CU-SO', 0, 1, '', '', 'CU', 'Sales', 'Customer', 'CustomerID', 'purchases', 1, '', 1, 'SO', 'Sales', 'SalesOrderHeader', 'SalesOrderID', 'purchased', 2, 'CustomerID', 1, @Environment_ID_Prod UNION ALL
SELECT 'PE-EM', 0, 1, '', '', 'PE', 'Person', 'Person', 'BusinessEntityID', 'hasemail', 1, '', 1, 'EM', 'Person', 'EmailAddress', 'EmailAddressID', 'isemail', 2, 'BusinessEntityID', 1, @Environment_ID_Prod UNION ALL
SELECT 'SP-PE', 0, 1, '', '', 'SP', 'Sales', 'SalesPerson', 'BusinessEntityID', 'isperson', 1, '', 1, 'PE', 'Person', 'Person', 'BusinessEntityID', 'people', 2, '', 1, @Environment_ID_Uat UNION ALL
SELECT 'SP-TR', 0, 1, '', '', 'SP', 'Sales', 'SalesPerson', 'BusinessEntityID', 'issalesperson', 1, 'TerritoryID', 1, 'TR', 'Sales', 'SalesTerritory', 'TerritoryID', 'salespeople', 2, '', 1, @Environment_ID_Dev UNION ALL
SELECT 'CU-TR', 0, 1, '', '', 'CU', 'Sales', 'Customer', 'CustomerID', 'iscustomer', 1, 'TerritoryID', 1, 'TR', 'Sales', 'SalesTerritory', 'TerritoryID', 'customers', 2, '', 1, @Environment_ID_Dev;

-- loop through adding\updating the ties
DECLARE TIES CURSOR
READ_ONLY
FOR SELECT * FROM @Ties;

OPEN TIES

FETCH NEXT FROM TIES INTO @TieMnemonic, @GenerateID, @IsHistorised, @KnotMnemonic, @KnotRoleName, @J1AnchorMnemonicRef,
							@J1DBTableSchema, @J1DBTableName, @J1DBTableColumnName, @J1RoleName, @J1TieJoinOrder,
							@J1TieJoinColumn, @J1IsIdentity, @J2AnchorMnemonicRef, @J2DBTableSchema, @J2DBTableName,
							@J2DBTableColumnName, @J2RoleName, @J2TieJoinOrder, @J2TieJoinColumn, @J2IsIdentity,
							@Environment_ID;

WHILE (@@fetch_status <> -1)
BEGIN
	IF (@@fetch_status <> -2)
	BEGIN
		EXEC [MeDriAnchor].[sspAddTie]
			@TieMnemonic = @TieMnemonic,
			@GenerateID = @GenerateID,
			@IsHistorised = @IsHistorised,
			@KnotMnemonic = @KnotMnemonic,
			@KnotRoleName = @KnotRoleName,
			@J1AnchorMnemonicRef = @J1AnchorMnemonicRef,
			@J1DBTableSchema = @J1DBTableSchema,
			@J1DBTableName = @J1DBTableName,
			@J1DBTableColumnName = @J1DBTableColumnName,
			@J1RoleName = @J1RoleName,
			@J1TieJoinOrder = @J1TieJoinOrder,
			@J1TieJoinColumn = @J1TieJoinColumn,
			@J1IsIdentity = @J1IsIdentity,
			@J2AnchorMnemonicRef = @J2AnchorMnemonicRef,
			@J2DBTableSchema = @J2DBTableSchema,
			@J2DBTableName = @J2DBTableName,
			@J2DBTableColumnName = @J2DBTableColumnName,
			@J2RoleName = @J2RoleName,
			@J2TieJoinOrder = @J2TieJoinOrder,
			@J2TieJoinColumn = @J2TieJoinColumn,
			@J2IsIdentity = @J2IsIdentity,
			@Environment_ID = @Environment_ID;

	END
	FETCH NEXT FROM TIES INTO @TieMnemonic, @GenerateID, @IsHistorised, @KnotMnemonic, @KnotRoleName, @J1AnchorMnemonicRef,
								@J1DBTableSchema, @J1DBTableName, @J1DBTableColumnName, @J1RoleName, @J1TieJoinOrder,
								@J1TieJoinColumn, @J1IsIdentity, @J2AnchorMnemonicRef, @J2DBTableSchema, @J2DBTableName,
								@J2DBTableColumnName, @J2RoleName, @J2TieJoinOrder, @J2TieJoinColumn, @J2IsIdentity,
								@Environment_ID;
END

CLOSE TIES;
DEALLOCATE TIES;

PRINT 'END: Loading Adventure Works 2008 metadata into MeDriAnchor....';
GO

-- Attach tests
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
SELECT 'Sales', 'SalesPerson', 'Bonus', 'BETWEEN (NUMERIC)', CONVERT(MONEY, 1000), CONVERT(MONEY, 10000), NULL, NULL, NULL;

INSERT INTO @Tests
SELECT 'Sales', 'SalesPerson', 'SalesYTD', 'IS NUMERIC', NULL, NULL, NULL, NULL, NULL;

INSERT INTO @Tests
SELECT 'Person', 'Person', 'FirstName', 'IS NOT BLANK', NULL, NULL, NULL, NULL, NULL;

INSERT INTO @Tests
SELECT 'Person', 'Person', 'LastName', 'IS NOT BLANK', NULL, NULL, NULL, NULL, NULL;

INSERT INTO @Tests
SELECT 'Sales', 'SalesTerritory', 'Name', '> (LENGTH STRING)', CONVERT(TINYINT, 2), NULL, NULL, NULL, NULL;

INSERT INTO @Tests
SELECT 'Sales', 'SalesTerritory', 'CountryRegionCode', '<> (STRING)', CAST('USA' AS NVARCHAR(50)), NULL, NULL, NULL, NULL;

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