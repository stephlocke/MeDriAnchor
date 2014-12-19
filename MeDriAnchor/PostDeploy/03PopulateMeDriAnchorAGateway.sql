
PRINT 'START: Loading MeDriAnchor from A Gateway....';

SET NOCOUNT ON;

/* 
------------------------------------------------------------------------------------------------------------------------------------------
STEP 1: Tell MeDriAnchor about the source; what server it is on, what type of database this is, and details about the database
------------------------------------------------------------------------------------------------------------------------------------------
*/

DECLARE @DBServerID BIGINT;
DECLARE @DBID BIGINT;
DECLARE @Environment_ID SMALLINT = (SELECT [Environment_ID] FROM [MeDriAnchor].[Environment] 
	WHERE [EnvironmentName] = 'LIVE');

-- 1.1 Add the server if it doesn't exist
EXEC [MeDriAnchor].[sspAddDBServer]
	@DBServerType = 'SQLSERVER',
	@DBServerName = 'dummysrvr\dummyinstance',
	@DBServerID = @DBServerID OUTPUT;

-- 1.2: Create the database if it doesn't exist
EXEC [MeDriAnchor].[sspAddDB]
	@DBServerID = @DBServerID,
	@DBName = 'Dummy db', 
	@DBUserName = NULL, 
	@DBUserPassword = NULL,
	@DBIsLocal = 1,
	@DBIsSource = 1,
	@DBIsDestination = 0,
	@Environment_ID = @Environment_ID,
	@StageData = 1,
	@DBID = @DBID OUTPUT;

-- 1.3: Run the linked server routine to do any necessary adjustments or creations
EXEC [MeDriAnchor].[amsp_ETLSQL_CreateLinkedServers];

-- 1.4: Hoover in the source schema
EXEC [MeDriAnchor].[sspGetSchemaFromSourceDB]
	@DBID = @DBID,
	@Environment_ID = @Environment_ID;
GO

/* 
------------------------------------------------------------------------------------------------------------------------------------------
STEP 2: Add the Anchor markup
------------------------------------------------------------------------------------------------------------------------------------------
*/

SET NOCOUNT ON;

-- 2.1 Flag the Anchors

DECLARE @DBTableSchema SYSNAME;
DECLARE @DBTableName SYSNAME;
DECLARE @DBTableColumnName SYSNAME;
DECLARE @DBTableColumnAlias SYSNAME;
DECLARE @AnchorMnemonic NVARCHAR(3);
DECLARE @DBTableColumnNameDateComp SYSNAME;

DECLARE @Anchors TABLE 
	(
	[DBTableSchema] SYSNAME,
	[DBTableName] SYSNAME,
	[DBTableColumnName] SYSNAME,
	[DBTableColumnAlias] SYSNAME,
	[AnchorMnemonic] NVARCHAR(3),
	[DBTableColumnNameDateComp] SYSNAME
	);

INSERT INTO @Anchors
	(
	[DBTableSchema],
	[DBTableName],
	[DBTableColumnName],
	[DBTableColumnAlias],
	[AnchorMnemonic],
	[DBTableColumnNameDateComp]
	)
SELECT 'MeDriAnchor', 'blah', 'blahCode', '', 'NWR', 'ModifiedDate' UNION ALL
SELECT 'MeDriAnchor', 'blah2', 'ID', 'blahID', 'BAL', '';

-- loop through adding\updating the anchors
DECLARE ANCHORS CURSOR
READ_ONLY
FOR SELECT * FROM @Anchors;

OPEN ANCHORS

FETCH NEXT FROM ANCHORS INTO @DBTableSchema, @DBTableName, @DBTableColumnName, @DBTableColumnAlias, @AnchorMnemonic, @DBTableColumnNameDateComp;
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
			@DBTableColumnNameDateComp = @DBTableColumnNameDateComp;
	END
	FETCH NEXT FROM ANCHORS INTO @DBTableSchema, @DBTableName, @DBTableColumnName, @DBTableColumnAlias, @AnchorMnemonic, @DBTableColumnNameDateComp;
END

CLOSE ANCHORS;
DEALLOCATE ANCHORS;
GO

-- 2.2 Flag the Attributes

SET NOCOUNT ON;

DECLARE @DBTableSchema SYSNAME;
DECLARE @DBTableName SYSNAME;
DECLARE @DBTableColumnName SYSNAME;
DECLARE @IsAttribute BIT;
DECLARE @IsHistorised BIT;
DECLARE @AnchorMnemonicRef NVARCHAR(3);
DECLARE @AttributeMnemonic NVARCHAR(7);
DECLARE @KnotMnemonic NVARCHAR(7);
DECLARE @CreateNCIndexInDWH BIT;

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
	[CreateNCIndexInDWH] BIT
	);
INSERT INTO @Attributes
SELECT 'MeDriAnchor','blah','HPIRegion',1,1,'NWR','NWR_HPI','',0 UNION ALL
SELECT 'MeDriAnchor','blah2','IsLatestBalance',1,1,'BAL','BAL_ILB','',0 ;


-- loop through adding\updating the attributes
DECLARE ATTRIBUTES CURSOR
READ_ONLY
FOR SELECT * FROM @Attributes;

OPEN ATTRIBUTES

FETCH NEXT FROM ATTRIBUTES INTO @DBTableSchema, @DBTableName, @DBTableColumnName, @IsAttribute, @IsHistorised, @AnchorMnemonicRef, 
								@AttributeMnemonic, @KnotMnemonic, @CreateNCIndexInDWH;
WHILE (@@fetch_status <> -1)
BEGIN
	IF (@@fetch_status <> -2)
	BEGIN
		EXEC [MeDriAnchor].[sspAddAttribute]
			@DBTableSchema = @DBTableSchema,
			@DBTableName = @DBTableName,
			@DBTableColumnName = @DBTableColumnName,
			@IsAttribute = @IsAttribute,
			@IsHistorised = @IsHistorised,
			@AnchorMnemonicRef = @AnchorMnemonicRef,
			@AttributeMnemonic = @AttributeMnemonic,
			@KnotMnemonic = @KnotMnemonic,
			@CreateNCIndexInDWH = @CreateNCIndexInDWH;

	END
	FETCH NEXT FROM ATTRIBUTES INTO @DBTableSchema, @DBTableName, @DBTableColumnName, @IsAttribute, @IsHistorised, @AnchorMnemonicRef, 
									@AttributeMnemonic, @KnotMnemonic, @CreateNCIndexInDWH;
END

CLOSE ATTRIBUTES;
DEALLOCATE ATTRIBUTES;
GO

-- 2.3 Flag the Knots

-- N.B. All Knots must have a numeric key and a value

SET NOCOUNT ON;

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
SELECT 'MeDriAnchor','LookupApplicantType','LK_APPT',0,'type','type','ApplicantTypeID','ApplicantType','','ApplicantTypeID','ApplicantType' UNION ALL
SELECT 'MeDriAnchor','vLookupSecurityTypeS','LK_SCTS',0,'title','type','SecurityTypeID','SecurityType','SecurityTypeServicing','SecurityTypeID','SecurityType';

-- loop through adding\updating the anchors
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
			@ValDBTableColumnName = @ValDBTableColumnName;
	END
	FETCH NEXT FROM KNOTS INTO @DBTableSchema, @DBTableName, @KnotMnemonic, @IsHistorised, @IDRoleName, @ValRoleName, @IDKnotJoinColumn,
								@ValKnotJoinColumn, @ValTableColumnAlias, @IDDBTableColumnName, @ValDBTableColumnName;
END

CLOSE KNOTS;
DEALLOCATE KNOTS;
GO

-- 2.4 Flag the Ties

SET NOCOUNT ON;

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
	[J2IsIdentity] BIT
	);
INSERT INTO @Ties
SELECT 'OAP-OAO', 0, 1, '', '', 'OAP', 'MeDriAnchor', 'vApplicationOrigination', 'ApplicationID', 'receives',1, '', 1, 'OAO', 'MeDriAnchor', 'vApplicantOrigination','ApplicantID', 'applies', 2, '', 1 UNION ALL
SELECT 'SEG-BAL', 1, 1, '', '', 'SEG', 'MeDriAnchor', 'vAccountSegmentServicing', 'LoanSegmentID', 'hasbalance',1, '', 1, 'BAL', 'MeDriAnchor', 'vAccountBalances','ID', 'balance', 2, 'LoanSegmentID', 1;
-- loop through adding\updating the ties
DECLARE TIES CURSOR
READ_ONLY
FOR SELECT * FROM @Ties;

OPEN TIES

FETCH NEXT FROM TIES INTO @TieMnemonic, @GenerateID, @IsHistorised, @KnotMnemonic, @KnotRoleName, @J1AnchorMnemonicRef,
							@J1DBTableSchema, @J1DBTableName, @J1DBTableColumnName, @J1RoleName, @J1TieJoinOrder,
							@J1TieJoinColumn, @J1IsIdentity, @J2AnchorMnemonicRef, @J2DBTableSchema, @J2DBTableName,
							@J2DBTableColumnName, @J2RoleName, @J2TieJoinOrder, @J2TieJoinColumn, @J2IsIdentity;

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
			@J2IsIdentity = @J2IsIdentity;

	END
	FETCH NEXT FROM TIES INTO @TieMnemonic, @GenerateID, @IsHistorised, @KnotMnemonic, @KnotRoleName, @J1AnchorMnemonicRef,
								@J1DBTableSchema, @J1DBTableName, @J1DBTableColumnName, @J1RoleName, @J1TieJoinOrder,
								@J1TieJoinColumn, @J1IsIdentity, @J2AnchorMnemonicRef, @J2DBTableSchema, @J2DBTableName,
								@J2DBTableColumnName, @J2RoleName, @J2TieJoinOrder, @J2TieJoinColumn, @J2IsIdentity;
END

CLOSE TIES;
DEALLOCATE TIES;

PRINT 'END: Loading MeDriAnchor from A Gateway....';
GO