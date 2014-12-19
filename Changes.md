---
title: MeDriAnchor data incorporation
author: Steph Locke
output: html_document
---

# TLDR
Once a source of data is added into the MeDriAnchor tables, data can then be added rapidly. The full set of actions can be performed 
in a Post-deployment script.

- Add an anchor using `[MeDriAnchor].[sspAddAnchor]`
- Add a knot using `[MeDriAnchor].[sspAddKnot]` 
- Add an attribute using `[MeDriAnchor].[sspAddAttribute]` 
- Add a tie using `[MeDriAnchor].[sspAddTie]` 


# Intro

The MeDriAnchor database is a metadata-driven ETL engine. As such, it needs all the necessary data about a source database to 
successfully be able to pull data from it, create the appropriate objects in the Anchor database, and transfer data between the two. 
Once it knows about the server the source database resides on, what type of database server it is, which databases it is pulling 
from, the schema of those databases, and - via markup - how those tables and columns are structured in the Anchor model. All this is 
achieved via meatadata and there is no hard-coding anywhere in the process - so what works for one source database will work for any other.

# Prerequisites

There are only two prerequistes for adding a data source: the MeDriAnchor database must be able to see and communicate with it and 
also the `[dbo].[vIndexDetails]` and `[dbo].[vTableColumns]` views from the MeDriAnchor project must be created in it. If the database 
is not SQL Server then you will need to make new versions of these views that produce the same output. The `[MeDriAnchor].[sspGetSchemaFromSourceDB]` 
procedure relies on these views but obviously you are able to customise this as you wish as long as the same columns are returned.

# Adding data
Once any of these changes occur, the metadata will be flagged as changed and the Anchor objects generated and populated. The procedure 
 `[MeDriAnchor].[sspGetSchemaFromSourceDB]` will  need to be run first to get the mapping data for the source system.

## Add an Anchor
```sql
EXEC [MeDriAnchor].[sspAddAnchor]
			@DBTableSchema = @DBTableSchema, -- The schema of the table the Anchor is coming from
			@DBTableName = @DBTableName, -- The table the Anchor is coming from
			@DBTableColumnName = @DBTableColumnName, -- The column that will be the Anchor
			@DBTableColumnAlias = @DBTableColumnAlias, -- An alias for the Anchor 
														-- (if you multiple columns called say "ID" here you can rename them to be ProductID, CustomerID etc.)
			@AnchorMnemonic = @AnchorMnemonic, -- The Anchor mnemonic (short textual identifier, must be unique amongst Anchors)
			@DBTableColumnNameDateComp = @DBTableColumnNameDateComp; -- If the table has a datetime filed that can be used for 
				-- incremental changes - ModifiedDate, CreatedDate, etc. - then it can be specified here and the ETL will use it
				-- getting only rows changed after the last batch date
```

The main points to note here, bar specifying which column is the Anchor, are the DBTableColumnAlias parameter and the DBTableColumnNameDateComp 
parameter. The DBTableColumnAlias value allows you to rename in Anchor the column, so in a case of you having every primary key named [ID], 
here you can give them more descriptive and, more importantly, unique names. The DBTableColumnNameDateComp is equally important, as it can 
seriously help with incremental loading. If a column is specified here (which is in the same table as the Anchor) then the ETL can use that to 
only pull records altered since the last batch ran. A serious winner in terms of the work the ETL routine has to do.

## Add a Knot

Currently, ONLY lookups that have a numeric key in the source table referencing a numeric key and value in a separate lookup table are supported. 
Textual lookup values that reference text in a lookup table are not supported. You can get round this using a Gateway database and it is no big 
show-stopper but does take additional work (see the Gateways documentation).

```sql
EXEC [MeDriAnchor].[sspAddKnot]
	@DBTableSchema = @DBTableSchema, -- The schema of the table the Knot is coming from (the lookup table)
	@DBTableName = @DBTableName, -- The table the Knot is coming from (the lookup table)
	@KnotMnemonic = @KnotMnemonic, -- A mnemonic (text) reference for the Knot (unique amongst Knots)
	@IsHistorised = @IsHistorised, -- Whether the Knot is historised
	@IDRoleName = @IDRoleName, -- The role name of the Knot (lookup) - i.e. isstatus
	@ValRoleName = @ValRoleName, -- The role name of the referencing column (lookup) - i.e. hasstatus
	@IDKnotJoinColumn = @IDKnotJoinColumn, -- The id (pk) column of the Knot
	@ValKnotJoinColumn = @ValKnotJoinColumn, -- The name of the column that will be used to join to the Knot. 
												 -- So if TypeID in the lookup but just Type in the source table then this should be "Type"
	@ValTableColumnAlias = @ValTableColumnAlias, -- This is an alias for the Knot. Knots can only be used once in Anchor unless they have different names,
												 -- so to use mnore than once add an alias here (CustomerGenderID, PersonGenderId, etc.)
	@IDDBTableColumnName = @IDDBTableColumnName, -- Actual column name of the pk in the Knot (lookup) table
	@ValDBTableColumnName = @ValDBTableColumnName; -- Actual column name of the value in the Knot (lookup) table
```

## Add the Attributes

Next you can add the markup to identify all Attributes of the Anchors previously identified. Again this is a straight forward process. The 
markup just needs to identify the Attribute, the Anchor it relates to (and optionally any Knot it relates to).

```sql
EXEC [MeDriAnchor].[sspAddAttribute]
			@DBTableSchema = @DBTableSchema, -- The schema of the table the Attribute is coming from
			@DBTableName = @DBTableName, -- The table the Attribute is coming from
			@DBTableColumnName = @DBTableColumnName, -- The column that will be the Attribute
			@IsHistorised = @IsHistorised, -- Whether the attribute is historised
			@AnchorMnemonicRef = @AnchorMnemonicRef, -- The mnemonic of the Anchor that this Attribute relates to
			@AttributeMnemonic = @AttributeMnemonic, -- A mnemonic (text) reference for the Attribute (Anchor mnemonic + "_" + Attribute mnemonic (Unique within Attribute))
			@KnotMnemonic = @KnotMnemonic, -- The mnemonic of the Know (lookup) that this attribute relates to (don't pass paramater if none)
			@CreateNCIndexInDWH = @CreateNCIndexInDWH; -- Flag specifying whether you want a non-clustered index created in the DWH on this column
```

## Add the Ties

Now that the Anchors, Attributes, and Knots have been identified, we can add the ties. These are similar to relationships in databases and 
basically tie (relate) two Anchors together (Customer to Order, Customer to Contact etc.). Ties are done in pairs in MeDriAnchor to make 
things easy, so each relationship is added as a distinct tie between two Anchors. All that the MeDriAnchor database needs is to know which 
two Anchors to relate and how to do this. When the join columns in the source may not be the same, you can pass in values to use instead 
(otherwise it will automatically try and join on the PK column of the first table).

```sql
EXEC [MeDriAnchor].[sspAddTie]
	@TieMnemonic = @TieMnemonic, -- A mnemonic for the tie (Anchor mnemonic (table 1) + "-" + Anchor mnemonic (table 2))
	@GenerateID = @GenerateID, -- Flag to tell Anchor that this is an Anchor-generated id (so that it automatically puts a unique constraint on the tie column)
								-- Defaults to 0 (off)
	@IsHistorised = @IsHistorised, -- Flag to say if the tie is historised or not
	@KnotMnemonic = @KnotMnemonic, -- A mnemonic for the Knot if the Tie is knotted (not currently implemented and defaults to false)
	@KnotRoleName = @KnotRoleName, -- A role name for the Knot reference
	-- table 1 data
	@J1AnchorMnemonicRef = @J1AnchorMnemonicRef, -- Table 1 Anchor mnemonic
	@J1DBTableSchema = @J1DBTableSchema, -- Table 1 table schema
	@J1DBTableName = @J1DBTableName, -- Table 1 table name
	@J1DBTableColumnName = @J1DBTableColumnName, -- Table 1 column name
	@J1RoleName = @J1RoleName, -- Table 1 role name
	@J1TieJoinOrder = @J1TieJoinOrder, -- Table 1 join order (defaults to 1)
	@J1TieJoinColumn = @J1TieJoinColumn, -- Table 1 join column (the column in table 1 that will be used to join to table 2)
	@J1IsIdentity = @J1IsIdentity, -- Flag to tell Anchor that this is an "IDENTITY" (pk)
									-- Defaults to 1 (true). Again stops unecessary constraints being put on the column
	-- table 1 data
	@J2AnchorMnemonicRef = @J2AnchorMnemonicRef, -- Table 2 Anchor mnemonic
	@J2DBTableSchema = @J2DBTableSchema, -- Table 2 table schema
	@J2DBTableName = @J2DBTableName, -- Table 2 table name
	@J2DBTableColumnName = @J2DBTableColumnName, -- Table 2 column name
	@J2RoleName = @J2RoleName, -- Table 2 role name
	@J2TieJoinOrder = @J2TieJoinOrder, -- Table 2 join order (defaults to 2)
	@J2TieJoinColumn = @J2TieJoinColumn, -- Table 2 join column (the column in table 2 that will be used to join with the column specified in table 1)
	@J2IsIdentity = @J2IsIdentity; -- Flag to tell Anchor that this is an "IDENTITY" (pk)
									-- Defaults to 1 (true). Again stops unecessary constraints being put on the column
```


## Computed columns

Computed columns can be added into the metadata.
```sql
INSERT INTO [MeDriAnchor].[DBTableColumn]
	(
	[DBTableID],
	[ColumnName],
	[PKName], 
	[PKClustered], 
	[PKColOrdinal], 
	[PKDescOrder], 
	[IdentityColumn], 
	[ColPosition], 
	[DataType], 
	[NumericPrecision], 
	[NumericScale], 
	[CharMaxLength], 
	[IsNullable], 
	[IsComputedCol],
	[IsMaterialisedColumn],
	[MaterialisedColumnFunction]
	)
SELECT
	(SELECT [DBTableID] FROM [MeDriAnchor].[DBTable] WHERE [DBTableSchema] = 'Sales' AND [DBTableName] = 'SalesOrderHeader') AS [DBTableID],
	'SubTotalAverageVariance' AS [ColumnName],
	{@Environment_ID} AS [Environment_ID],
	0 AS [PKColumn], 
	'' AS [PKName], 
	0 AS [PKClustered], 
	0 AS [PKColOrdinal], 
	'' AS [PKDescOrder], 
	0 AS [IdentityColumn], 
	999 AS [ColPosition], 
	'money' AS [DataType], 
	0 AS [NumericPrecision], 
	0 AS [NumericScale], 
	0 AS [CharMaxLength], 
	0 AS [IsNullable], 
	1 AS [IsComputedCol],
	1 AS [IsMaterialisedColumn],
	'[MeDriAnchor].[fnSalesOrderSubTotalPctOfAverage](s.[SubTotal])' AS [MaterialisedColumnFunction]
```

Obviously you first have to create a scalar function in the MeDriAnchor database but this can take any parameters from the same table as 
it is being added to; any parameters with an s. prefix and quoted will be replaced by those column values at ETL time. This can then be 
marked up as any other attribute.


# Existing data

As the Anchor model is purely iterative, the concept of amending existing Anchor objects doesn't exist. What we have to do is to create 
new ones and simply stop communicating with the old ones. This provides a very Agile model where nothing is ever altered in the DWH, just 
invalidated and new objects created. There is no concept of changing an Anchor, we either drop it out of the ETL by removing it's metadata, 
or spawn the creation of a new anchor by simply changing it's mnemonic or column alias. This will result in a brand new Anchor being created 
and populated. The old Anchor will still exist in the DWH but it will be ignored in the ETL routine.

## Attributes: Moving to historized

Due to the iterative and create-only nature of Anchor, if we want to change a previously non-historised Attribute to being a historised 
Attribute then we need to create a new Attribute. This is as simple as changing the attribute mnemonic or the column alias of the source 
column. Either of these changes would result in an Anchor object with a different name to the original and this change would be picked up 
by the ETL engine and the new object populated accordingly.

## Attributes: Moving to knotted

Moving an existing attribute to being knotted is as simple as adding the markup to add a Knot Mnemonic to the source schema row in the 
[MeDriAnchor].[DBTableColumn] table. The addition of the Knot mnemonic will result in a new name for the Attribute in Anchor and a new 
object will be automatically created and populated during the next ETL run.

# Troubleshooting

Errors with the Anchor markup will become apparent in the ETL run, as either the production of the Anchor XML or running the sisulated 
SQL over the DWH will generate errors. Manually running the `[MeDriAnchor].[fnGetAnchorXML]` function, saving the XML and loading into the 
Anchor Modeller then generating the SQL will show any validation failures. This is why the MeDriAnchor database has the concept of 
environments, as obviously you'd first want to run all of your changes into the development DWH prior to running into UAT or live.

# Roadmap

* Support for Knotted Ties
* Metadata-checking procedure
